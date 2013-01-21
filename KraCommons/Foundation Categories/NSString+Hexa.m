//
//  NSString+Hexa.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/10/13.
//  Copyright (c) 2013 kra All rights reserved.
//

#import "NSString+Hexa.h"

@implementation NSString (Hexa)

- (NSInteger) integerFromHexaValue {
	NSScanner *scanner = [NSScanner scannerWithString: self];
	unsigned int result = 0;
	[scanner scanHexInt: &result];
	return (NSInteger) result;
}

@end
