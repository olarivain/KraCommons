//
//  UITableView+extensions.m
//  OpenTable
//
//  Created by Snehal Patil on 1/3/13.
//  Copyright (c) 2013 OpenTable. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "UITableView+NibRegistration.h"

@implementation UITableView (extensions)
- (void) registerNibNamed:(NSString *)nibName forCellReuseIdentifier:(NSString *)reuseId {
    //validate reuse ID first
    NSAssert([reuseId length] != 0, ([NSString stringWithFormat:@"*** FATAL: Reuse ID can't be empty for nib %@",nibName]));
 
 	UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    NSAssert(nib != nil, ([NSString stringWithFormat:@"*** FATAL: Could not register nib named %@",nibName]));
     
	// and register it, eventually
	[self registerNib:nib forCellReuseIdentifier:reuseId];
}
 
- (void) registerNibsForCellReuseIdentifier: (NSDictionary *) cellIdToNibName {
	for(NSString *reuseId in cellIdToNibName.allKeys) {
		NSString *nibName = [cellIdToNibName valueForKey:reuseId];
        [self registerNibNamed: nibName forCellReuseIdentifier: reuseId];
    }
}
@end
#endif