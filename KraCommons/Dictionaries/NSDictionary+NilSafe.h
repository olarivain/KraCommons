//
//  NSDictionary+NilSafe.h
//  ECUtil
//
//  Created by Larivain, Olivier on 7/28/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (NSDictionary_NilSafe)
- (void) setObjectNilSafe: (id) object forKey:(NSString*) key;

- (void) setFloat: (float) value forKey: (NSString *) key;
- (void) setInteger: (NSInteger) value forKey: (NSString *) key;
@end

@interface NSDictionary(NSDictionary_NilSafe)
- (NSInteger) integerForKey: (NSString *) key;
- (BOOL) booleanForKey: (NSString *) key;
- (id) nullSafeForKey: (NSString *) key;
@end