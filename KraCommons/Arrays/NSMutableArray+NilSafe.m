//
//  NSMutableArray+NilSafe.m
//  ECUtil
//
//  Created by Larivain, Olivier on 10/3/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import "NSMutableArray+NilSafe.h"

@implementation NSMutableArray (NSMutableArray_NilSafe)

- (void) addObjectNilSafe: (id) object {
    if(object == nil) {
        return;
    }
    
    [self addObject: object];
}

@end
