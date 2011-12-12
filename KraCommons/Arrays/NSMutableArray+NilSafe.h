//
//  NSMutableArray+NilSafe.h
//  ECUtil
//
//  Created by Larivain, Olivier on 10/3/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (NSMutableArray_NilSafe)
- (void) addObjectNilSafe: (id) object;
@end
