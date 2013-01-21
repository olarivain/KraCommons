//
//  OTFOpenTableClient.h
//  
//
//  Created by Kra on 12/31/12.
//  Copyright (c) 2012 kra. All rights reserved.
//
#import <Foundation/Foundation.h>

#import <AFNetworking/AFHTTPClient.h>

@interface KCHTTPClient : AFHTTPClient

+ (KCHTTPClient *) defaultClient;

@end
