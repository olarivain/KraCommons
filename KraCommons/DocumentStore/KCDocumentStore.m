//
//  KCDocumentStore.m
//
//  Created by Larivain, Olivier on 7/9/11.
//
#import "KCDocumentStore.h"
#import "KCDocumentStoreFileBackend.h"
#import "KCDocumentStoreOperation.h"
#import "NSArray+BoundSafe.h"

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import "UIImage+Retina.h"
#endif

#define DEFAULT_STORE_PATH @"default_store"

static KCDocumentStore *defaultDocumentStore = nil;
static KCDocumentStore *temporaryDefaultDocumentStore = nil;

typedef void(^KCDocumentStoreBlock)();

@interface KCDocumentStore()

@property (nonatomic, readwrite, strong) NSOperationQueue *writeQueue;
@property (nonatomic, readwrite, strong) id<KCDocumentStoreBackend> backend;
@property (nonatomic, readwrite, strong) NSMutableArray *pending;
@property (nonatomic, readwrite, strong) NSMutableArray *processing;

- (id) init: (BOOL) temp;

- (void) scheduleOperation: (KCDocumentStoreOperation*) operation;
- (void) processNextOperation;

- (KCDocumentStoreOperation*) dequeueNextOperationWithConcurrency;
- (KCDocumentStoreOperation*) dequeueNextOperationWithoutConcurrency;
- (void) didProcessOperation: (KCDocumentStoreOperation*) operation;

- (BOOL) isDocumentExpired: (NSString *) documentId withExpiration: (NSTimeInterval) interval;

- (void) waitUntilFlushed;

- (void) run: (KCDocumentStoreOperation*) operation;

- (NSObject *) parseJSON: (NSData*) data;
@end

@implementation KCDocumentStore

+ (id) defaultDocumentStore {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultDocumentStore = [[KCDocumentStore alloc] init: NO];
    });
    return defaultDocumentStore;
}

+ (id) temporaryDefaultDocumentStore {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        temporaryDefaultDocumentStore = [[KCDocumentStore alloc] init: YES];
    });
    return temporaryDefaultDocumentStore;

}

- (id) init: (BOOL) temp {
    
    self = [super init];
    if(self) {        
        // TODO this should be configurable through plist, potentially programatically.
        // So far, we're fine since we have only one backend :)
        self.backend = [[KCDocumentStoreFileBackend alloc] initWithBasePath:DEFAULT_STORE_PATH temporary: temp];
        
        NSInteger maxConcurrentOperation = 30;
        writeQueue = [[NSOperationQueue alloc] init];
        [writeQueue setMaxConcurrentOperationCount: maxConcurrentOperation];
        
        self.pending = [NSMutableArray arrayWithCapacity: 60];
        self.processing = [NSMutableArray arrayWithCapacity: maxConcurrentOperation];
        
        [backend createStore];
    }
    return self;
}


@synthesize writeQueue;
@synthesize backend;
@synthesize pending;
@synthesize processing;

#pragma mark - Queue Processing
#pragma mark Scheduling
- (void) scheduleOperation:(KCDocumentStoreOperation *)operation {
    @synchronized(self) {
        // remove any pending operation for this id.
        // indeed, since we are going to update it, this operation will have the final word
        // and we can skip altogether the pending one.
        for(int i = 0; i < [pending count]; i++){
            KCDocumentStoreOperation *candidate = [pending objectAtIndex: i];
            if([candidate equals: operation]) {
                [pending removeObjectAtIndex: i];
                i--;
            }
        }
        
        // now schedule this guy
        [pending addObject: operation];
        
        // and process next
        [self processNextOperation];
    }
}

#pragma mark Processing next operation
- (void) processNextOperation {
    @synchronized(self) {
        // nothing to process, get out
        if([pending count] == 0) {
            return;
        }
        
        // dequueing will be different depending on the concurrency support of the backend.
        // branch here.
        KCDocumentStoreOperation *operation = nil;
        if([backend supportsConcurrency]) {
            operation = [self dequeueNextOperationWithConcurrency];
        } else {
            operation = [self dequeueNextOperationWithoutConcurrency];
        }
        
        // no operation could be dequeued, give up now
        if(operation == nil) {
            return;
        }
        
        // run operation and process next
        KCDocumentStoreBlock block = ^{
            [self run: operation];
            [self didProcessOperation: operation];
            [self processNextOperation];
        };
        
        // and schedule!
        [writeQueue addOperationWithBlock: block];
    }
}

- (void) run: (KCDocumentStoreOperation*) operation {
    
    if(operation.type == WRITE) {
        [backend persistDocument: operation.data withId: operation.documentId];
        return;
    } 
    if(operation.type == DELETE) {
        [backend deleteDocumentWithId: operation.documentId];
        return;
    } 
    
    // no callback, get out now
    if(operation.callback == nil) {
        return;
    }
    
    // read operation, get from backend and then perform callback
    NSData * data = [backend documentWithId: operation.documentId];
    
    // honor read type by building relevant object and then callback
    switch (operation.readType) {
        case DATA:
            operation.callback(data);
            break;
        case JSON:
            operation.callback([self parseJSON: data]);
            break;
        case IMAGE:
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
            operation.callback([UIImage retinaImageWithData: data]);
#endif
            break;
        default:
            break;
    }
}

#pragma mark Dequeuing
/*
 IMPORTANT these 2 dequeue methods don't have a synchronized block because they are being called from within a
 synchronized block.
 Any refactoring should ensure that this logic MUST be called from a synchronized block
 */
- (KCDocumentStoreOperation*) dequeueNextOperationWithConcurrency {
    // pop next pending
    KCDocumentStoreOperation *operation = [pending boundSafeObjectAtIndex: 0];
    
    // nothing to do, get out!
    if(operation == nil){
        return nil;
    }
    // otherwise move it to processing
    [processing addObject: operation];
    [pending removeObject: operation];
    
    return  operation;
}

- (KCDocumentStoreOperation*) dequeueNextOperationWithoutConcurrency {
    BOOL dequeued = YES;
    KCDocumentStoreOperation *operation = nil;
    
    // go through all pending, looking for a concurrency conflict
    for(KCDocumentStoreOperation *next in pending){
        dequeued = YES;
        
        // if an a pending operation exists for that id, then skip the current pending operation
        for(KCDocumentStoreOperation *inProgress in processing) {
            if([inProgress equals: next]) {
                dequeued = NO;
                break;
            }
        }
        
        // the current operation didn't have any conflict, go ahead and process it.
        // just get out of the loop.
        // Note to self: a do/while should be better suited for this kind of logic.
        if(dequeued) {
            operation = next;
            break;
        }
    }
    
    // every operation was concurrent, give up now
    if(operation == nil) {
        return  nil;
    }
    
    // move from pending to processing
    [processing addObject: operation];
    [pending removeObject: operation];
    
    return  operation;
}

#pragma mark Completion callback
- (void) didProcessOperation:(KCDocumentStoreOperation *)operation {
    @synchronized(self) {
        [processing removeObject: operation];
    }
}

#pragma mark - Persistance
#pragma raw Data
- (void) persistData: (NSData*) data withId: (NSString *) documentId {
    // schedule a write
    KCDocumentStoreOperation *operation = [KCDocumentStoreOperation documentStoreOperationWithId: documentId 
                                                                                         andData: data];
    [self scheduleOperation: operation];
}

#pragma mark JSON convenience
- (void) persistObject: (NSObject*) dict withId: (NSString *) documentId {
    // figure out runtime class, pass on to right method or do nothing if types are not correct
    if (dict == nil) {
        return;
    }
    
    if([dict isKindOfClass: [NSDictionary class]]) {
        [self persistDictionary: (NSDictionary*) dict withId: documentId];
        return;
    }
    
    if([dict isKindOfClass: [NSArray class]]) {
        [self persistArray: (NSArray*) dict withId: documentId];
        return;
    }
}

- (void) persistDictionary: (NSDictionary*) dict withId: (NSString *) documentId {
    NSData *data = [NSJSONSerialization dataWithJSONObject: dict 
                                                   options: 0 
                                                     error: nil];
    [self persistData: data withId:documentId];
}

- (void) persistArray: (NSArray*) array withId: (NSString *) documentId {
    NSData *data = [NSJSONSerialization dataWithJSONObject: array 
                                                   options: 0 
                                                     error: nil];
    [self persistData: data withId:documentId];    
}

#pragma mark Image convenience
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (void) persistImage: (UIImage*) image withId: (NSString *) documentId {
    NSData *data = UIImagePNGRepresentation(image);
    [self persistData: data withId: documentId];
}
#endif


#pragma mark - Deletion
- (void) deleteDocumentWithId: (NSString *) documentId {
    if(documentId == nil) {
        return;
    }
    
    // schedule a delete operation
    KCDocumentStoreOperation *operation = [KCDocumentStoreOperation documentStoreOperationWithId: documentId];
    [self scheduleOperation: operation];
}


#pragma mark - Read access
#pragma mark Synchronous
- (NSDate*) lastUpdateDate: (NSString *) documentId {
    return [backend lastUpdateDate: documentId];
}

- (NSData *) documentWithId:(NSString *)documentId {
    return [self documentWithId: documentId andCacheExpiration: -1]; 
}

- (NSData *) documentWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration{
    if(documentId == nil) {
        return nil;
    }
    
    if([self isDocumentExpired: documentId 
                withExpiration: expiration]){
        return nil;
    }
    
    // backend supports concurrency, just forward request
    if([backend supportsConcurrency]) {
        return [backend documentWithId: documentId];
    }
    
    // synchronize to avoid issues on concurrent array modifications
    @synchronized(self) {
        // look for a pending operation with the same id.
        for(KCDocumentStoreOperation *operation in processing) {
            // we found one. Return that operation's data if the operation was write.
            // return nil if it was a delete (the content is getting erased, so nothing to return.
            // This breaks isolation, yes, I know. Seems a lot more correct considering the use cases
            // of our apps though.
            if([operation.documentId compare: documentId] == NSOrderedSame) {
                if(operation.type == WRITE) {
                    return operation.data;
                }
                if(operation.type == DELETE) {
                    return nil;
                }
            }
        }
    }
    // no concurrency found, forward to backend
    return [backend documentWithId: documentId];
}

- (BOOL) isDocumentExpired: (NSString *) documentId withExpiration: (NSTimeInterval) interval {
    if(interval < 0){
        return NO;
    }
    
    // grab last modification date
    NSDate *date = [self lastUpdateDate: documentId];
    
    // no date, means no modification, means no document, consider it expired
    if(date == nil) {
        return YES;
    }
    
    // compute expiration date
    NSDate *expirationDate = [date dateByAddingTimeInterval: interval];
    NSDate *now = [NSDate date];
    
    // if the later date is now, document is expired
    return [expirationDate laterDate: now] == now;
}

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (UIImage *) imageWithId: (NSString *) documentId {
    return  [self imageWithId: documentId andCacheExpiration: -1];
}

- (UIImage *) imageWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration {
    NSData *data = [self documentWithId: documentId andCacheExpiration: expiration];
    UIImage *image = [UIImage retinaImageWithData: data];
    return  image;
}
#endif

- (NSObject*) jsonDocumentWithId: (NSString *) documentId {
    return [self jsonDocumentWithId: documentId andCacheExpiration: -1];
}

- (NSObject*) jsonDocumentWithId:(NSString *)documentId andCacheExpiration:(NSTimeInterval)expiration {
    NSData *data = [self documentWithId: documentId andCacheExpiration: expiration];
    NSObject *object = [self parseJSON: data];
    return  object;
}

- (NSDictionary*) jsonDictionaryWithId: (NSString *) documentId {
    return [self jsonDictionaryWithId: documentId andCacheExpiration: -1];
}

- (NSDictionary*) jsonDictionaryWithId:(NSString *)documentId andCacheExpiration:(NSTimeInterval)expiration {
    NSObject *object = [self jsonDocumentWithId: documentId andCacheExpiration: expiration];
    if([object isKindOfClass: [NSDictionary class]]){
        return (NSDictionary *) object;
    }
    return  nil;

}

- (NSArray*) jsonArrayWithId: (NSString *) documentId {
    return [self jsonArrayWithId: documentId andCacheExpiration: -1];
}

- (NSArray*) jsonArrayWithId: (NSString *) documentId andCacheExpiration:(NSTimeInterval)expiration {
    NSObject *object = [self jsonDocumentWithId: documentId andCacheExpiration: expiration];
    if([object isKindOfClass: [NSArray class]]){
        return (NSArray *) object;
    }
    return  nil;
}

#pragma mark Asynchronous
// read
- (void) asyncDocumentWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback {
    [self asyncDocumentWithId: documentId cacheExpiration: -1 andCallback: callback];
}

- (void) asyncDocumentWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback {
    KCDocumentStoreOperation *operation = [KCDocumentStoreOperation documentStoreOperationWithId: documentId 
                                                                                        readType: DATA 
                                                                                     andCallback: callback];
    [self scheduleOperation: operation];
}

- (void) asyncImageWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback{
    [self asyncImageWithId: documentId cacheExpiration: -1 andCallback: callback];
}
- (void) asyncImageWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback{
    KCDocumentStoreOperation *operation = [KCDocumentStoreOperation documentStoreOperationWithId: documentId 
                                                                                        readType: IMAGE 
                                                                                     andCallback: callback];
    [self scheduleOperation: operation];
}

- (void) asyncJsonDocumentWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback{
    [self asyncJsonDocumentWithId: documentId cacheExpiration: -1 andCallback: callback];
}

- (void) asyncJsonDocumentWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback {
    KCDocumentStoreOperation *operation = [KCDocumentStoreOperation documentStoreOperationWithId: documentId 
                                                                                        readType: JSON 
                                                                                     andCallback: callback];
    [self scheduleOperation: operation];
}

#pragma mark - JSONParsing
- (NSObject *) parseJSON: (NSData*) data{
    if(data == nil || [data length] == 0) {
        return nil;
    }
    
    NSObject *object = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error: nil];
    return object;
}

#pragma mark - Flushing
// TODO: we could keep track of ALL created stores in a static array.
// this would let us flush all stores in a safe way.
+ (void) waitForFlush {
    if(defaultDocumentStore) {
        [defaultDocumentStore waitUntilFlushed];
    }
}

- (void) waitUntilFlushed {
    [writeQueue waitUntilAllOperationsAreFinished];
}

@end
