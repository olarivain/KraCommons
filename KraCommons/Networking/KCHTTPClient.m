//
//  OTFOpenTableClient.m
//  
//
//  Created by Kra on 12/31/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import <AFNetworking/AFNetworkActivityIndicatorManager.h>

#import "KCHTTPClient.h"

#import "KCWebRequestOperation.h"

#import "NSString+URLEncoding.h"

static KCHTTPClient *defaultClient;

// we need to declare this function: this is how AFNetworking sorts query params
NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);


@interface KCHTTPClient () {
	__strong NSString *_oauthKey;
	__strong NSString *_oauthSecret;
}

@end

@implementation KCHTTPClient

+ (KCHTTPClient *) defaultClient
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create the default client
        KCGlobalConfiguration *configuration = [KCGlobalConfiguration sharedInstance];
        
        // set the base url to opentable
        NSURL *baseURL = [NSURL URLWithString: configuration.baseUrl];
        defaultClient = [[self alloc] initWithBaseURL:baseURL];
    });
    
    return defaultClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        // configure the client now.
        
        // We'll be using our own web request operation class
        [self registerHTTPOperationClass: KCWebRequestOperation.class];
		
        // we want json
        [self setDefaultHeader: @"Accept"
                         value: @"application/json"];
        // compressed JSON, that is :)
        [self setDefaultHeader: @"Accept-Encoding"
                         value: @"gzip, deflate"];

		// configure ourselves for 6 max concurrent requests
		[self.operationQueue setMaxConcurrentOperationCount: 6];
#if __IPHONE_OS_VERSION_MIN_REQUIRED
		[AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
#endif
    }
    
    return self;
}

@end
