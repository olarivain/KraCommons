//
//  NSDictionaryAdditions.h

//
//  Created by kra on 1/19/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Additions)

- (id) nullSafeForKey: (id) aKey;
- (NSDate*)dateForKey:(id)aKey;
- (NSURL*)urlForKey:(id)aKey;
- (NSDictionary *) dictionaryForKey:(id)aKey;

- (NSNumber *) numberForKey:(id)aKey;
- (NSNumber *) numberFromStringForKey:(id)aKey;

- (BOOL) boolForKey: (id)aKey;
- (BOOL) boolFromStringForKey: (id)aKey;

- (CGFloat) floatForKey: (id)aKey;
- (CGFloat) floatFromStringForKey: (id)aKey;

- (NSInteger) integerForKey: (id)aKey;
- (NSInteger) integerFromStringForKey: (id)aKey;

- (NSInteger) hexaIntegerForKey: (id)aKey;
@end


@interface NSMutableDictionary (Additions)
//if obj is nill or @"" it will do nothing
- (void)safeSetObject:(id)obj forKey:(id)aKey;
- (void)setObjectNilSafe:(id)obj forKey:(id)aKey;

- (void) setBool: (BOOL) boolean forKey: (id)aKey;
- (void) setInteger: (NSInteger) integer forKey: (id)aKey;
- (void) setFloat: (CGFloat) value forKey: (id)aKey;
- (void) setLong: (long) value forKey: (id)aKey;
- (void) setDouble: (double) value forKey: (id)aKey;
@end