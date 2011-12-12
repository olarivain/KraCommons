//
//  NSArray+BoundSafe.h
//  ECUtil
//
//  Created by Larivain, Olivier on 7/15/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray (NSArray_BoundSafe)

- (id) boundSafeObjectAtIndex: (NSInteger) index;

@end
