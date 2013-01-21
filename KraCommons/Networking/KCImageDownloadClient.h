//
//  Created by kra on 1/10/13.
//  Copyright (c) 2012  kra.. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <AFNetworking/AFNetworking.h>

@interface KCImageDownloadClient : NSObject

+ (KCImageDownloadClient *)sharedClient;

/**
 The string encoding used in constructing url requests. This is `NSUTF8StringEncoding` by default.
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 The `AFHTTPClientParameterEncoding` value corresponding to how parameters are encoded into a request body. This is `AFFormURLParameterEncoding` by default.
 
 @warning JSON encoding will automatically use JSONKit, SBJSON, YAJL, or NextiveJSON, if provided. Otherwise, the built-in `NSJSONSerialization` class is used, if available (iOS 5.0 and Mac OS 10.7). If the build target does not either support `NSJSONSerialization` or include a third-party JSON library, a runtime exception will be thrown when attempting to encode parameters as JSON.
 */
@property (nonatomic, assign) AFHTTPClientParameterEncoding parameterEncoding;

/**
 The operation queue which manages operations enqueued by the HTTP client.
 */
@property (readonly, nonatomic, retain) NSOperationQueue *operationQueue;

/**
 Returns the value for the HTTP headers set in request objects created by the HTTP client.
 
 @param header The HTTP header to return the default value for
 
 @return The default value for the HTTP header, or `nil` if unspecified
 */
- (NSString *)defaultValueForHeader:(NSString *)header;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.
 
 @param header The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil
 */
- (void)setDefaultHeader:(NSString *)header value:(NSString *)value;

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

/**
 Enqueues an `AFHTTPRequestOperation` to the HTTP client's operation queue.
 
 @param operation The HTTP request operation to be enqueued.
 */
- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation;

/**
 Cancels all operations in the HTTP client's operation queue whose URLs match the specified HTTP request path.
 
 @param path The path to match for the cancelled requests.
 */
- (void)cancelAllHTTPOperationsWithPath:(NSString *)path;

/**
 Creates an `AFHTTPRequestOperation` with a `GET` request, and enqueues it to the HTTP client's operation queue.
 
 @param urlString The request URL.
 @param parameters The parameters to be encoded and appended as the query string for the request URL.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes two arguments: the created request operation and the object created from the response data of request.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the resonse data. This block has no return value and takes two arguments:, the created request operation and the `NSError` object describing the network or parsing error that occurred.
 
 @see HTTPRequestOperationWithRequest:success:failure
 */
- (void)getUrl: (NSString *)urlString
    parameters: (NSDictionary *)parameters
  cacheRequest: (BOOL) cache
       success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
       failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
#endif