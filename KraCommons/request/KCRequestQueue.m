//
//  KCRequestQueue.m
//
//  Created by Kra on 6/28/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import "KCRequestQueue.h"
#import "KCRequestQueueItem.h"
#import "KCBlocks.h"

static KCRequestQueue *sharedInstance;

@interface KCRequestQueue()
@property (nonatomic, readwrite, retain) NSMutableArray *pending;
@property (nonatomic, readwrite, retain) NSMutableArray *active;
@property (nonatomic, readwrite, retain) NSMutableArray *processing;
@property (nonatomic, readwrite, retain) NSOperationQueue *requestOperationQueue;
@property (nonatomic, readwrite, retain) NSOperationQueue *callbackOperationQueue;

+ (KCRequestQueue*) shardInstance;

- (KCRequestQueueItem*) addURL: (NSURL*) url 
                      callback: (KCRequestCallback) callback;

- (KCRequestQueueItem*) addURL: (NSURL*) url 
                      withData: (NSData*) data 
                    withMethod: (NSString *) method 
                   andCallback: (KCRequestCallback) callback;

- (void) cancelDownloadItem: (KCRequestQueueItem*) url;
- (void) cancelFromPending: (KCRequestQueueItem*) item;
- (void) cancelFromActive: (KCRequestQueueItem*) item;
- (void) cancelFromCallback: (KCRequestQueueItem*) item;

- (BOOL) canProcessNextQueueItem;
- (void) processNextQueueItem;

- (void) requestFinishedBlock: (KCRequestQueueItem *) item;

@end

@implementation KCRequestQueue

// lazy singleton constructor
+ (KCRequestQueue*) shardInstance 
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KCRequestQueue alloc] init];
    });
    return sharedInstance;
}

- (id) init 
{
  self = [super init];
  if(self)
  {
    self.pending = [NSMutableArray arrayWithCapacity:20];
    self.active = [NSMutableArray arrayWithCapacity: 20];
    self.processing = [NSMutableArray arrayWithCapacity: 20];
    maxConcurrentRequests = 5;
    currentConcurrentRequests = 0;
    
    self.requestOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [requestOperationQueue setMaxConcurrentOperationCount: maxConcurrentRequests];
    
    self.callbackOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
    [callbackOperationQueue setMaxConcurrentOperationCount: 2*maxConcurrentRequests];
  }
    
  return self;
}

- (void) dealloc {
    self.pending = nil;
    self.active = nil;
    self.processing = nil;
    self.requestOperationQueue = nil;
    self.callbackOperationQueue = nil;
    [super dealloc];
}

@synthesize pending;
@synthesize active;
@synthesize processing;
@synthesize requestOperationQueue;
@synthesize callbackOperationQueue;

#pragma mark - Static methods wrapping singleton calls
// default, no data, simple get
+ (KCRequestQueueItem*) scheduleURL:(NSURL *)url withCallback:(KCRequestCallback)callback 
{
  return [KCRequestQueue scheduleURL: url 
                            withData: nil 
                          withMethod:@"GET" 
                         andCallback: callback];
}

// Full blown control over method, body etc
+ (KCRequestQueueItem*) scheduleURL: (NSURL*) url 
                           withData: (NSData *) data 
                         withMethod: (NSString *) method 
                        andCallback: (KCRequestCallback) callback 
{
  return  [[KCRequestQueue shardInstance] addURL: url 
                                        withData: data 
                                      withMethod: method 
                                     andCallback: callback];
}

+ (void) cancelItem: (KCRequestQueueItem*) item 
{
  [[KCRequestQueue shardInstance] cancelDownloadItem: item];
}

#pragma mark - Add URL method
- (KCRequestQueueItem*) addURL: (NSURL*) url callback: (KCRequestCallback) callback 
{
  return [self addURL: url withData: nil withMethod: @"GET" andCallback: callback];
}

- (KCRequestQueueItem*) addURL: (NSURL*) url 
                      withData: (NSData*) data 
                    withMethod: (NSString *) method 
                   andCallback: (KCRequestCallback) callback 
{
  KCRequestQueueItem *item = nil;
  @synchronized(self)
  {
    // create and item to pending queue
    item = [KCRequestQueueItem requestQueueItemWithQueue: self 
                                                     URL: url 
                                                  method: method 
                                                    data: data 
                                             andCallback: callback];
    [pending addObject: item];
  }
  
  // process if we're done
  [self processNextQueueItem];
  return item;

}

#pragma mark - Cancellation
- (void) cancelDownloadItem:(KCRequestQueueItem *)item 
{
  // cancel from pending, then from active if not found
  [self cancelFromPending: item];
  [self cancelFromActive: item];
  [self cancelFromCallback: item];
}

- (void) cancelFromPending: (KCRequestQueueItem*) item 
{
  BOOL found = NO;
  // iterate through pending list, if found remove it from pending queue
  for(KCRequestQueueItem *candidate in pending) 
  {
    if(candidate == item) 
    {
      found = YES;
      break;
    }
  }
  if(found) 
  {
    [item cancel];
    [pending removeObject: item];
  }
}

- (void) cancelFromActive: (KCRequestQueueItem*) item 
{
  [item cancel];
  [active removeObject: item];
}

- (void) cancelFromCallback: (KCRequestQueueItem*) item 
{
  // iterate through callback item, if found, set cancel flag to YES.
  for(KCRequestQueueItem *candidate in processing) 
  {
    if(candidate == item) 
    {
      candidate.cancelled = YES;
      break;
    }
  }
}

#pragma mark - Queue processing
- (BOOL) canProcessNextQueueItem 
{
  // we can process if we not all concurrent downloads are used
  return currentConcurrentRequests < maxConcurrentRequests;
}

- (void) processNextQueueItem 
{
  KCRequestQueueItem *item = nil;
  @synchronized(self) 
  {
    // if we can't process next item, bail out
    if(![self canProcessNextQueueItem] || [pending count] == 0) 
    {
      return;
    }
    
    // move next download to processing queue and increment concurrent download
    item = [pending objectAtIndex: 0];
    [processing addObject: item];
    [pending removeObject: item];
    
    currentConcurrentRequests++;
  }
  
  // just a safeguard, shouldn't happen
  if(item == nil) 
  {
    return;
  }
  
  // async download API will callback on the thread that initiated the download.
  // We will certainly call this from the UI thread and it's not acceptable to have 
  // download code happening on the UI thread - hence the NSOperation to move this to
  // a background thread.
  KCVoidBlock block = ^ {
    [item start];
  };
  [requestOperationQueue addOperationWithBlock: block];
}

// download is finished, send clean up + callback code to the callback operation queue.
- (void) requestFinished:(KCRequestQueueItem *)item 
{
  void(^finishedBlock)(void) = ^ {
    [self requestFinishedBlock: item];  
  };
  
  [callbackOperationQueue addOperationWithBlock: finishedBlock];
}

- (void) requestFinishedBlock: (KCRequestQueueItem *) item 
{
  // move to processing queue and decrement current active DL count
  [processing addObject: item];
  [active removeObject: item];
  currentConcurrentRequests--;
  
  // start processing next item
  [self processNextQueueItem];
  
  // callback if we're supposed to
  KCRequestCallback callback = item.callback;
  if(callback) 
  {
    callback(item);
  }
  
  // remove from processing queue. this object is going to die now.
  [processing removeObject: item];
}

@end