//
//  UIButton+ResizableImage.h
//  OTKit
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright (c) 2013 kra. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import <UIKit/UIKit.h>

@interface UIButton (ResizableImage)

- (void) updateBackgroundWithDefaultCaps;
- (void) updateBackgroundWithResizableCaps: (UIEdgeInsets) caps;

@end

#endif