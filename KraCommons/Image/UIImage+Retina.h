//
//  UIImage+Retina.h
//
//  Created by Larivain, Olivier on 8/4/11.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

@interface UIImage (UIImage_Retina)

// because [UIImage imageWithData] will always return images with scale 1.0
+ (UIImage *)retinaImageWithData:(NSData *)data;

// because [UIImage imageWithData] will always return images with scale 1.0
+ (UIImage *)retinaImageWithData:(NSData *)data andSize:(CGSize)size;

+ (UIImage *)scaleImage:(UIImage *)original toSize:(CGSize)newSize;

@end
#endif