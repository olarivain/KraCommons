//
//  KCGlobalConfiguration.h
//  
//
//  Created by Kra on 12/28/12.
//  Copyright (c) 2012 kra All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCGlobalConfiguration : NSObject {
	__strong NSMutableDictionary *_configuration;
	__strong NSString *_propertySuffix;
	__strong NSBundle *_mainBundle;
}

+ (KCGlobalConfiguration *) sharedInstance;

// raw configuration object
@property (nonatomic, readonly, strong) NSDictionary *configuration;
// server base URL
@property (nonatomic, readonly) NSString *baseUrl;

@end
