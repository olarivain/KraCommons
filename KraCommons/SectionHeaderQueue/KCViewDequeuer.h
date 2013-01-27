//
//  KCSectionHeaderQueue.h
//  KraCommons
//
//  Created by Olivier Larivain on 1/26/13.
//  Copyright (c) 2013 kra. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import <UIKit/UIKit.h>

@interface KCViewDequeuer : NSObject

- (void) registerNibName: (NSString *) nibName forReuseIdentifier: (NSString *) reuseId;
- (UIView *) dequeueReusableViewWithIdentifier: (NSString *) reuseId;

@end

#endif