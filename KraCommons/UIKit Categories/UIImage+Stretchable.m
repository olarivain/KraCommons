//
//  UIImage+extensions.m

//
//  Created by kra on 1/20/09.
//  Copyright 2009 kra. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "UIImage+Stretchable.h"

@implementation UIImage (Stretchable)
- (UIImage *)stretchableImageWithDefaultCaps {
	return [self stretchableImageWithLeftCapWidth:(self.size.width / 2) topCapHeight:(self.size.height / 2)];
}
@end

#endif