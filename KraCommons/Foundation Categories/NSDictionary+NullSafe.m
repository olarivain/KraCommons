//
//  NSDictionaryAdditions.h

//
//  Created by kra on 1/19/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import "NSDictionary+NullSafe.h"

#import "NSString+Hexa.h"
#import "NSNumber+String.h"

#define UNIVERSAL_DATE_TIME_FORMAT @"yyyy-MM-dd'T'HH:mm:ss" // 2012-01-01T15:00:00


@implementation NSDictionary (Additions)

- (id) nullSafeForKey: (id) aKey {
    id obj = [self objectForKey:aKey];
    if(obj == [NSNull null]) {
        return nil;
    }
	
	// our servers will return <null> instead of an actual JSON null, so deal with this here
	if([obj isKindOfClass: NSString.class] && [(NSString *) obj isEqualToString: @"<null>"]) {
		return nil;
	}
	
    return obj;
}

- (NSDictionary *) dictionaryForKey:(id)aKey {
	id obj = [self nullSafeForKey:aKey];
    if (obj==nil  || ![obj isKindOfClass: NSDictionary.class]) {
        return nil;
    }
    
	return (NSDictionary *) obj;
}

- (NSDate*)dateForKey:(id)aKey {
    id obj = [self nullSafeForKey:aKey];
    if (obj==nil || ![obj isKindOfClass: NSString.class]) {
        return nil;
    }
    
    NSString *dateString = (NSString*)obj;
    
    // Pares date in format: 2011-02-03T17:43:43UTC
    // 2012/12/28 OL: This used to be static, but NSDateFormatter is NOT thread safe
    // and Apple advises against using it concurrently, hence changing it to a local var.
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    
    // set the format and return a date from it
    [dateFormatter setDateFormat: UNIVERSAL_DATE_TIME_FORMAT];
    return [dateFormatter dateFromString:dateString];
}

- (NSURL*)urlForKey:(id)aKey {
    id obj = [self nullSafeForKey:aKey];
    if (obj == nil || ![obj isKindOfClass: NSString.class]) {
        return nil;
    }
    return [NSURL URLWithString:obj];
}

- (NSNumber *) numberForKey:(id)aKey {
    id value = [self nullSafeForKey: aKey];
    if(value == nil || ![value isKindOfClass: NSNumber.class]) {
        return nil;
    }
    
    return (NSNumber *) value;
}

- (NSNumber *) numberFromStringForKey:(id)aKey {
	id value = [self nullSafeForKey: aKey];
	if(value == nil) {
		return nil;
	}
	
	if([value isKindOfClass: NSNumber.class]) {
		return (NSNumber *) value;
	}
	
	if(![value isKindOfClass: NSString.class]) {
		return nil;
	}
	
	return [NSNumber numberFromString: (NSString *) value];
}

- (BOOL) boolForKey: (id)aKey {
    id value = [self numberForKey: aKey];
    return value == nil ? NO :[(NSNumber *) value boolValue];
}

- (BOOL) boolFromStringForKey: (id)aKey {
	id value = [self numberFromStringForKey: aKey];
    return value == nil ? NO :[(NSNumber *) value boolValue];
}

- (CGFloat) floatForKey: (id)aKey {
    id value = [self numberForKey: aKey];
	return value == nil ? NO :[(NSNumber *) value floatValue];
}

- (CGFloat) floatFromStringForKey:(id)aKey {
    id value = [self numberFromStringForKey: aKey];
	return value == nil ? NO :[(NSNumber *) value floatValue];
}

- (NSInteger) integerForKey: (id)aKey {
    id value = [self numberForKey: aKey];
    return value == nil ? NO :[(NSNumber *) value integerValue];
}

- (NSInteger) integerFromStringForKey: (id)aKey {
    id value = [self numberFromStringForKey: aKey];
    return value == nil ? NO :[(NSNumber *) value integerValue];
}

- (NSInteger) hexaIntegerForKey: (id)aKey {
	NSString *value = [self nullSafeForKey: aKey];
	return [value integerFromHexaValue];
}

@end


@implementation NSMutableDictionary (Additions)

- (void) setBool: (BOOL) boolean forKey: (id)aKey {
    NSNumber *number = [NSNumber numberWithBool: boolean];
    [self safeSetObject: number forKey: aKey];
}

- (void) setInteger: (NSInteger) integer forKey: (id)aKey {
    NSNumber *number = [NSNumber numberWithInteger: integer];
    [self safeSetObject: number forKey: aKey];
}

- (void) setFloat: (CGFloat) value forKey: (id)aKey {
    NSNumber *number = [NSNumber numberWithFloat:value];
    [self safeSetObject: number forKey: aKey];
}

- (void) setLong: (long) value forKey: (id)aKey {
	NSNumber *number = [NSNumber numberWithLong: value];
    [self safeSetObject: number forKey: aKey];
}

- (void) setDouble: (double) value forKey: (id)aKey {
	NSNumber *number = [NSNumber numberWithDouble:value];
    [self safeSetObject: number forKey: aKey];
}

- (void)safeSetObject:(id)obj forKey:(id)aKey {
	[self setObjectNilSafe: obj forKey: aKey];
}

- (void)setObjectNilSafe:(id)obj forKey:(id)aKey {
    // skip nils and NSNull
    if(obj == nil || obj == [NSNull null]) {
        return;
    }
    
    // skip empty string
    if([obj isKindOfClass: NSString.class] && [obj length]==0) {
        return;
    }
    
    [self setObject:obj forKey:aKey];
}
@end