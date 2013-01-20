//
//  DownloadQueueItem.m
//  ECUtil
//
//  Created by Kra on 6/28/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import "KCRequestQueueItem.h"
#import "KCRequestQueue.h"

@interface KCRequestQueueItem()
@property (nonatomic, readwrite, weak) KCRequestQueue *queue;
@property (nonatomic, readwrite, copy) KCRequestCallback callback;
@property (nonatomic, readwrite, strong) NSURL *url;
@property (nonatomic, readwrite, strong) NSData *requestData;
@property (nonatomic, readwrite, strong) NSString *method;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, strong) NSURLResponse *response;
@property (nonatomic, readwrite, strong) NSData *responseData;
@property (nonatomic, readwrite, strong) NSError *error;

- (id) initWithQueue: (KCRequestQueue*) downloadQueue 
                 URL: (NSURL*) downloadURL 
              method: (NSString *) aMethod 
                data: (NSData *) data 
         andCallback:(KCRequestCallback) requestCallback;

- (NSHTTPURLResponse*) httpResponse;
@end

@implementation KCRequestQueueItem
+ (id) requestQueueItemWithQueue: (KCRequestQueue*) queue 
                             URL: (NSURL*) url 
                     andCallback:(KCRequestCallback) requestCallback 
{
  return [KCRequestQueueItem requestQueueItemWithQueue: queue 
                                                   URL: url 
                                                method: @"GET" 
                                                  data: nil 
                                           andCallback: requestCallback];
}

+ (id) requestQueueItemWithQueue: (KCRequestQueue*) queue 
                             URL: (NSURL*) url 
                          method: (NSString *) aMethod 
                            data: (NSData *) data 
                     andCallback:(KCRequestCallback) requestCallback 
{
  return [[KCRequestQueueItem alloc] initWithQueue: queue 
                                               URL: url 
                                            method: aMethod 
                                              data: data 
                                       andCallback: requestCallback];
}

- (id) initWithQueue: (KCRequestQueue*) downloadQueue 
                 URL: (NSURL*) downloadURL 
              method: (NSString *) aMethod 
                data: (NSData *) data 
         andCallback:(KCRequestCallback) requestCallback 
{
  self = [super init];
  if(self) 
  {
    self.url = downloadURL;
    self.requestData = data;
    self.method = aMethod;
    self.queue = downloadQueue;
    self.callback = requestCallback;
    self.responseData = [NSMutableData data];
  }
  
  return self;
}


@synthesize url;
@synthesize callback;
@synthesize responseData;
@synthesize success;
@synthesize connection;
@synthesize response;
@synthesize error;
@synthesize cancelled;
@synthesize requestData;
@synthesize method;
@synthesize cancellationKey;
@synthesize queue;

#pragma mark - Start/Stop methods
- (void) start 
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
  [request setHTTPBody: requestData];
  [request setHTTPMethod: method];
  
  self.connection = [NSURLConnection connectionWithRequest: request delegate: self];
#if DEBUG_NETWORK == 1
  NSLog(@"Starting request %@", url.absoluteString);
#endif
  [connection start];
  NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
  // run the current run loop every 0.2 seconds, self is responsible for flipping the shouldKeeprunning switch
  // when download ends OR is cancelled.
  shouldKeepRunning = YES;
  while(shouldKeepRunning && 
        [runLoop runMode: NSDefaultRunLoopMode 
              beforeDate: [NSDate dateWithTimeIntervalSinceNow:0.2]]);

}

- (void) cancel 
{
#if DEBUG_NETWORK == 1
  NSLog(@"Canceling %@", url.absoluteString);
#endif
  shouldKeepRunning = NO;
  cancelled = YES;
  [connection cancel];
}

#pragma mark - JSON converter
- (NSObject*) jsonObject 
{
  NSObject *object = [NSJSONSerialization JSONObjectWithData: responseData 
                                                     options: NSJSONReadingAllowFragments 
                                                       error: nil];
  return object;
}

- (NSDictionary*) jsonDictionary 
{
  NSObject *object = [self jsonObject];
  if([object isKindOfClass: [NSDictionary class]])
  {
      return (NSDictionary *) object;
  }
  
  return nil;
}

- (NSArray*) jsonArray 
{
  NSObject *object = [self jsonObject];
  if([object isKindOfClass: [NSArray class]])
  {
      return (NSArray *) object;
  }
  
  return nil;
}

#pragma mark - HTTP convenience
- (BOOL) isSuccessful 
{
  // successful = no errors and http code in 200 range
  NSInteger status = [self status];
  return  error == nil && (199 < status) && (status < 300);
}

- (void) logFailure 
{
  if([self isSuccessful]) 
  {
    return;
  }
  NSLog(@"\n***\nCould not perform request:\n-Request URL: %@\n-HTTP Status Code: %i\n-Reason: %@\n-Description: %@\n***\n", url, [self status], [error localizedFailureReason], [error localizedDescription]);
}

- (NSInteger) status 
{
  NSHTTPURLResponse *httpResponse = [self httpResponse];
  if(httpResponse == nil)
  {
      return -1;
  }
     
  return [httpResponse statusCode];
}

- (NSDictionary*) headers 
{
  NSHTTPURLResponse *httpResponse = [self httpResponse];
  if(httpResponse == nil) 
  {
      return nil;
  }
  
  return [httpResponse allHeaderFields];
}

- (NSHTTPURLResponse*) httpResponse 
{
  if(response == nil) 
  {
      return nil;
  }
  
  if(![response isKindOfClass: [NSHTTPURLResponse class]])
  {
      return nil;
  }
  return (NSHTTPURLResponse*) response;
}

#pragma mark - NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse 
{
  self.response = aResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newData  
{
  [responseData appendData: newData];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection 
{
  success = YES;
#if DEBUG_NETWORK == 1
  [self logFailure];
#endif
  shouldKeepRunning = NO;
  [queue requestFinished: self];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)failure 
{
  success = NO;
#if DEBUG_NETWORK == 1
  [self logFailure];
#endif
  self.error = failure;
  shouldKeepRunning = NO;
  [queue requestFinished: self];
}

@end
