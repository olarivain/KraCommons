//
//  UIColor+extensions.m

//
//  Created by Kra on 10/29/08.
//  Copyright 2008 kra.. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "UIColor+extensions.h"

@implementation UIColor (UIColor_extensions)
+ (UIColor *)kc_colorWithHex:(NSUInteger)hex {
	NSUInteger red = (hex & 0xFF0000) >> 16;
	NSUInteger green = (hex & 0x00FF00) >> 8;
	NSUInteger blue = (hex & 0x0000FF);
    
	return [UIColor colorWithRed:(red / 255.0f)
                           green:(green / 255.0f)
                            blue:(blue / 255.0f)
                           alpha:1.0f];
}

@end
#endif