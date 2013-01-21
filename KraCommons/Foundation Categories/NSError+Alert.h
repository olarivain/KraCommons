//
//  NSError+Alert.h
//  KraCommons
//
//  Created by Olivier Larivain on 1/17/13.
//  Copyright (c) 2013 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@interface NSError (Alert)

- (BOOL) present;
- (BOOL) presentWithTitleSubstitution: (NSArray *) titleSubstitution
				  messageSubstitution: (NSArray *) messageSubstitution;
@end
#endif