//
//  NSNumber+String.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/12/13.
//  Copyright (c) 2013 kra All rights reserved.
//

#import "NSNumber+String.h"

@implementation NSNumber (String)

+ (NSNumber *) numberFromString:(NSString *)string {
    // convert string to double (will avoid issues with conversions). Note that this will return 0 if the string isn't an integer
    double componentInteger = [string doubleValue];
    
    // build number
    NSNumber *number = [NSNumber numberWithDouble: componentInteger];
    NSString *convertedString = [number stringValue];
    // if the string obtained from the number is equal to the original string, we had
    // an appropriate number to start with, so return this dude
    if([convertedString isEqualToString: string]) {
        return number;
    }
    
    // string wasn't a number, return nothing.
    return nil;
}

@end
