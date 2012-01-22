//
//  RequestQueueItem.h
//
//  Created by Kra on 6/28/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KCRequestQueue.h"
/*
RequestQueueItem is a high level abstraction for a scheduled requests.
It also is the placeholder for request specific data: url, callback and response.
RequestQueueItem provides high level methods to get access to the response:
- Raw response NSData,
- Parsed JSON,
- HTTP status code,
- HTTP headers

In case the connection failed, the callback will still be called. Caller can check the "success" property to know
wether a download went through.
In case success is NO, the "error" property will hold the NSError sent to the NSURLConnection delegate.
If the download is successfully cancelled, the callback will NOT be called.
*/
@interface KCRequestQueueItem : NSObject {
  __weak KCRequestQueue *queue;
  __strong  KCRequestCallback callback;
  __strong NSURL *url;
  __strong NSData *requestData;

  __strong NSString *method;
  
  __strong NSURLConnection *connection;
  __strong NSURLResponse *response;

  __strong NSMutableData *responseData;
  
  BOOL success;
  __strong NSError *error;
  
  BOOL shouldKeepRunning;
  BOOL cancelled;
}

// URL this object will/has requested
@property (nonatomic, readonly) NSURL *url;

// request body, if any
@property (nonatomic, readonly) NSData *requestData;

// request method, one of GET PUT POST DELETE
@property (nonatomic, readonly) NSString *method;

// callback block that will be called when request is done. Can be nil.
@property (nonatomic, readonly) KCRequestCallback callback;

@property (nonatomic, readonly) BOOL success;
@property (nonatomic, readonly) NSError *error;

// Raw server response.
@property (nonatomic, readonly) NSData *responseData;

@property (nonatomic, readwrite, retain) id cancellationKey;
@property (nonatomic, readwrite, assign) BOOL cancelled;

+ (id) requestQueueItemWithQueue: (KCRequestQueue*) queue 
                             URL: (NSURL*) url 
                     andCallback: (KCRequestCallback) requestCallback;

+ (id) requestQueueItemWithQueue: (KCRequestQueue*) queue 
                             URL: (NSURL*) url 
                          method: (NSString *) aMethod 
                            data: (NSData *) data 
                     andCallback: (KCRequestCallback) requestCallback;
- (void) start;
- (void) cancel;

// NSData parsed as JSON.
- (NSObject*) jsonObject;
- (NSDictionary*) jsonDictionary;
- (NSArray*) jsonArray;

// HTTP status code
- (NSInteger) status;

// HTTP headers
- (NSDictionary *) headers;

- (BOOL) isSuccessful;
- (void) logFailure;

@end
