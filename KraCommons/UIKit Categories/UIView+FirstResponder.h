//
//  UIView+FirstResponder.h
//  KraCommons
//
//  Created by Olivier Larivain on 1/21/13.
//  Copyright (c) 2013 kra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FirstResponder)

- (UIView *) kc_findFirstResponder;
- (BOOL) kc_findAndResignFirstResponder;

@end
