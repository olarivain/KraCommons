//  Created by kra on 1/10/13.
//  Copyright (c) 2012  kra.. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KCImageDownloadClient.h"

@interface KCImageDownloadClient()

@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, assign) dispatch_queue_t successCallbackQueue;


@end

@implementation KCImageDownloadClient

+(KCImageDownloadClient *)sharedClient
{
    static KCImageDownloadClient *sharedClient;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[KCImageDownloadClient alloc] init];
    });
    
    return sharedClient;
}

-(id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = NSUTF8StringEncoding;
    self.parameterEncoding = AFFormURLParameterEncoding;
	
    
	self.defaultHeaders = [NSMutableDictionary dictionary];
    
	// Accept-Encoding HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.3
	[self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
	
	// Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
	NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
	[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];

    self.operationQueue = [[NSOperationQueue alloc] init];
	[self.operationQueue setMaxConcurrentOperationCount:5];
    
    self.successCallbackQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    return self;
}

#pragma mark - Default headers

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
	[self.defaultHeaders setValue:value forKey:header];
}


#pragma mark - Requests and Operations

- (NSMutableURLRequest *)requestWithUrl:(NSString *)urlString
                             parameters:(NSDictionary *)parameters
                           cacheRequest: (BOOL) useCache
{
    NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:self.defaultHeaders];
    [request setHTTPShouldUsePipelining:YES];
    
    NSURLRequestCachePolicy cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    if(useCache) {
        cachePolicy = NSURLRequestUseProtocolCachePolicy | NSURLRequestReturnCacheDataElseLoad;
    }

    request.cachePolicy = cachePolicy;
	
    if (parameters) {
        NSString *format = [urlString rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@";
        url = [NSURL URLWithString:[urlString stringByAppendingFormat:format, AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
        [request setURL:url];
    }
    
	return request;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    [operation setSuccessCallbackQueue:self.successCallbackQueue];
    
    return operation;
}

#pragma mark -

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperationsWithPath:(NSString *)path {
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
            continue;
        }
        
        if ([path isEqualToString:[[[(AFHTTPRequestOperation *)operation request] URL] path]]) {
            [operation cancel];
        }
    }
}

- (void) getUrl: (NSString *)urlString
     parameters: (NSDictionary *)parameters
   cacheRequest: (BOOL) cache
        success: (void (^)(AFHTTPRequestOperation *operation, id responseObject))success
        failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error))failure 
{
	NSURLRequest *request = [self requestWithUrl: urlString
                                      parameters: parameters
                                    cacheRequest: cache];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
																	  success:success
																	  failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}


@end
#endif