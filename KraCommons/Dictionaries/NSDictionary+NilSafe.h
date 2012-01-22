//
//  NSDictionary+NilSafe.h
//  KCUtil
//
//  Created by Larivain, Olivier on 7/28/11.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (NSDictionary_NilSafe)
- (void) setObjectNilSafe: (id) object forKey:(NSString*) key;

- (void) setDouble: (float) value forKey: (NSString *) key;
- (void) setFloat: (float) value forKey: (NSString *) key;
- (void) setInteger: (NSInteger) value forKey: (NSString *) key;
@end

@interface NSDictionary(NSDictionary_NilSafe)
- (NSInteger) integerForKey: (NSString *) key;
- (float) floatForKey: (NSString *) key;
- (double) doubleForKey: (NSString *) key;
- (BOOL) booleanForKey: (NSString *) key;
- (id) nullSafeForKey: (NSString *) key;
@end