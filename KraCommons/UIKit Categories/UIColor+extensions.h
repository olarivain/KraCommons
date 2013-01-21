//
//  UIColor+extensions.h

//
//  Created by Kra on 10/29/08.
//  Copyright 2008 kra.. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

@interface UIColor (UIColor_extensions)

+ (UIColor *) kc_colorWithHex:(NSUInteger)hex;

@end
#endif