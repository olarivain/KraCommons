//
//  KCDocumentStoreOperation.m
//
//  Created by Larivain, Olivier on 7/10/11.
//

#import "KCDocumentStoreOperation.h"
#import "KCDocumentStore.h"

@interface KCDocumentStoreOperation()

- (id) initWithId: (NSString *) docId andData: (NSData*) docData;

- (id) initWithId: (NSString *) docId;

- (id) initWithId: (NSString *) docId 
         callback: (KCDocumentStoreCallback) operationCallback  
          andType: (KCDocumentStoreOperationReadType) readType;

@end
@implementation KCDocumentStoreOperation

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId 
                                                   andData: (NSData*) data 
{
    return [[KCDocumentStoreOperation alloc] initWithId: documentId andData: data];
}

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId
{
    return [[KCDocumentStoreOperation alloc] initWithId: documentId];
}

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId 
                                                  readType: (KCDocumentStoreOperationReadType) readType 
                                               andCallback: (KCDocumentStoreCallback) callback 
{
    return [[KCDocumentStoreOperation alloc] initWithId: documentId 
                                               callback: callback 
                                                andType: readType];
}

// write init
- (id) initWithId: (NSString *) docId andData: (NSData*) docData  {
    self = [super init];
    if(self){
        documentId = docId;
        data = docData;
        type = WRITE;
    }
    return self;
}

// delete init
- (id) initWithId: (NSString *) docId  {
    self = [super init];
    if(self){
        documentId = docId;
        type = DELETE;
    }
    return self;
}

// read init
- (id) initWithId: (NSString *) docId 
         callback: (KCDocumentStoreCallback) operationCallback  
          andType: (KCDocumentStoreOperationReadType) read  {
    self = [super init];
    if(self){
        documentId = docId;
        type = READ;
        callback = [operationCallback copy];
        // default read type to NSData
        readType = read;
    }
    return self;
}


@synthesize documentId;
@synthesize data;
@synthesize type;
@synthesize callback;
@synthesize readType;

- (BOOL) equals: (KCDocumentStoreOperation*) other {
    return [documentId compare: other.documentId] == NSOrderedSame;
}

@end
