//
//  UIImage+extensions.h

//
//  Created by kra on 1/20/09.
//  Copyright 2009 kra. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface UIImage (UIImage_extensions)
- (UIImage *)stretchableImageWithDefaultCaps;
@end
#endif