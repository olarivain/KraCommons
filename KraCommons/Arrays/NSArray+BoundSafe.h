//
//  NSArray+BoundSafe.h
//  KCUtil
//
//  Created by Larivain, Olivier on 7/15/11.
//

#import <Foundation/Foundation.h>


@interface NSArray (NSArray_BoundSafe)

- (id) boundSafeObjectAtIndex: (NSInteger) index;

@end

@interface NSMutableArray (NSMutableArray_NilSafe)
- (void) addObjectNilSafe: (id) object;
@end