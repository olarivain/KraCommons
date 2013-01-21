//
//  NSError+Creation.h
//  KraCommons
//
//  Created by Olivier Larivain on 1/17/13.
//  Copyright (c) 2013 kra All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Creation)

+ (void) setGlobalDomain: (NSString *) domain;

+ (NSError *) errorWithCode: (NSInteger) code andMessage: (NSString *) message;
- (NSString *) kc_errorMessage;

@end
