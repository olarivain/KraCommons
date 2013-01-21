//
//  NSError+Creation.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/17/13.
//  Copyright (c) 2013 kra All rights reserved.
//

#import "NSError+Creation.h"

#define ERROR_MESSAGE_KEY @"kc_ErrorMessagKey"
#define DEFAULT_ERROR_DOMAIN @"OTF"
static NSString *globalDomain;

@implementation NSError (Creation)

+ (void) setGlobalDomain: (NSString *) domain {
	globalDomain = domain;
}

+ (NSError *) errorWithCode:(NSInteger)code andMessage:(NSString *)message {
	
	// it's not ok to have an empty error domain, so default to OTF if
	// we don't have one
	if (globalDomain == nil) {
		globalDomain = DEFAULT_ERROR_DOMAIN;
	}
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: message, ERROR_MESSAGE_KEY, nil];
	NSError *error = [NSError errorWithDomain: globalDomain
										 code: code
									 userInfo: userInfo];
	
	return error;
}

- (NSString *) kc_errorMessage {
	return [self.userInfo nullSafeForKey: ERROR_MESSAGE_KEY];
}

@end
