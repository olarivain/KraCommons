//
//  NSArray+BoundSafe.h
//  KraCommons
//
//  Created by Kra on 12/28/12.
//  Copyright (c) 2012 kra All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (BoundSafe)
- (id)boundSafeObjectAtIndex:(NSInteger)index;
@end

@interface NSMutableArray (NullSafe)
- (void)addObjectNilSafe:(id)object;
@end

@interface NSMutableSet (NullSafe)
- (void)addObjectNilSafe:(id)object;
@end