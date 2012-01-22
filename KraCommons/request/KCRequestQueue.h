//
//  RequestQueue.h
//  ECUtil
//
//  Created by Kra on 6/28/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCRequestQueueItem;

// callback typedef
typedef void(^KCRequestCallback)(KCRequestQueueItem*);

/*
 RequestQueue is a scheduler for HTTP requests.
 Once scheduled, a URL will go through three phases:
 - Pending. The request is waiting for the next available slot. RequestQueue limits the number of concurrent requests to 5.
 - Active. The request is now active and getting (or waiting for) data from the network.
 - Callback. The network call is complete, the queue has now called the callback method for that object. Not that a request can 
 be submitted without a callback if the caller is not interested in the server response (typically, tracking pixels or conversion tracking).
 
 A RequestQueue can:
 - schedule a request for execution as soon as possible (First In, First Out).
 - schedule a given DownloadItem for low priority, background request (not implemented yet).
 - schedule a high priority request that will bypass FIFO rules (not implemented yet). Those requests will always be scheduled for immediate execution, even if no request slots are available.
 - cancel a request, may it be pending or active. Due to the technical architecture of NSOperationQueue, requests in the 
    callback phase can NOT be cancelled. Callers should NEVER directly cancel a DownloadItem, but rather send the RequestQueue that
 created it the +cancel: message. Ideally, when we have time, we should move internal methods to a different header file.
 
 On scheduling, the RequestQueue will build a RequestQueueItem encapsulating the URL to be called, the callback method. It also
 provides convenience methods to access to HTTP status codes, in case the caller wants to handle a 304 Not changed for example, or needs
 access to HTTP headers.
 This object is returned by the scheduling methods in case the caller would need them, for cancelling a request for examples.
 It is safe for the caller to retain these, however callers do NOT have ownership of the objects (i.e. it is not their responsibility
 to make sure it has been dealloc'd).
 */
@interface KCRequestQueue : NSObject {
    __strong NSMutableArray *pending;
    __strong NSMutableArray *active;
    __strong NSMutableArray *processing;
    int maxConcurrentRequests;
    int currentConcurrentRequests;
    
    __strong NSOperationQueue *requestOperationQueue;
    __strong NSOperationQueue *callbackOperationQueue;
}

// schedules given URL for request, associating it with given request
+ (KCRequestQueueItem*) scheduleURL: (NSURL*) url 
                       withCallback: (KCRequestCallback) callback;

+ (KCRequestQueueItem*) scheduleURL: (NSURL*) url 
                           withData: (NSData *) data 
                         withMethod: (NSString *) method 
                        andCallback: (KCRequestCallback) callback;

// cancels given request queue item. requests can only be cancelled in pending or active phase, not in callback phase.
+ (void) cancelItem: (KCRequestQueueItem*) url;

// internal method, DO NOT CALL.
- (void) requestFinished: (KCRequestQueueItem*) item;
@end
