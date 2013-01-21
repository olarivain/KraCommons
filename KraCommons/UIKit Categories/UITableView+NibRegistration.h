//
//  UITableView+extensions.h
//  OpenTable
//
//  Created by Snehal Patil on 1/3/13.
//  Copyright (c) 2013 OpenTable. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

@interface UITableView (extensions)
- (void)registerNibNamed:(NSString *)nibName forCellReuseIdentifier:(NSString *)reuseId;
- (void) registerNibsForCellReuseIdentifier: (NSDictionary *) cellIdToNibName;
@end
#endif