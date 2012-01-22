//
//  NSDictionary+NilSafe.m
//  KCUtil
//
//  Created by Larivain, Olivier on 7/28/11.
//

#import "NSDictionary+NilSafe.h"

@implementation NSMutableDictionary (NSDictionary_NilSafe)

- (void) setObjectNilSafe: (id) object forKey:(NSString*) key 
{
  if(object == nil) 
  {
    return;
  }
  
  [self setObject: object forKey: key];
}

- (void) setFloat: (float) value forKey: (NSString *) key
{
  NSNumber *number = [NSNumber numberWithFloat: value];
  [self setObject: number forKey: key];
}

- (void) setInteger: (NSInteger) value forKey: (NSString *) key
{    
  NSNumber *number = [NSNumber numberWithInteger: value];
  [self setObject: number forKey: key];
}

- (void) setDouble: (float) value forKey: (NSString *) key 
{
  NSNumber *number = [NSNumber numberWithDouble: value];
  [self setObject: number forKey: key];
}

@end

@implementation NSDictionary(NSDictionary_NilSafe)

- (NSInteger) integerForKey: (NSString *) key 
{
  id number = [self objectForKey: key];
  if([number isKindOfClass: [NSNumber class]]) 
  {
    return  [(NSNumber *) number integerValue];
  }
  return 0;
}

- (float) floatForKey: (NSString *) key

{
  id number = [self objectForKey: key];
  if([number isKindOfClass: [NSNumber class]]) 
  {
    return  [(NSNumber *) number floatValue];
  }
  return 0;
}

- (double) doubleForKey: (NSString *) key

{
  id number = [self objectForKey: key];
  if([number isKindOfClass: [NSNumber class]]) 
  {
    return  [(NSNumber *) number doubleValue];
  }
  return 0;
}

- (BOOL) booleanForKey: (NSString *) key 
{
  id number = [self objectForKey: key];
  if([number isKindOfClass: [NSNumber class]]) 
  {
    return  [(NSNumber *) number boolValue];
  }
  return NO;
}

- (id) nullSafeForKey: (NSString *) key 
{
  id object = [self objectForKey: key];
  if([[NSNull null] isEqual: object]) 
  {
    return nil;
  }
  return object;
}

@end
