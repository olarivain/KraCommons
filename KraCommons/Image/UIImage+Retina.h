//
//  UIImage+Retina.h
//  ECUtil
//
//  Created by Larivain, Olivier on 8/4/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIImage_Retina)

// because [UIImage imageWithData] will always return images with scale 1.0
+ (UIImage *)retinaImageWithData:(NSData *)data;

// because [UIImage imageWithData] will always return images with scale 1.0
+ (UIImage *)retinaImageWithData:(NSData *)data andSize:(CGSize)size;

+ (UIImage *)scaleImage:(UIImage *)original toSize:(CGSize)newSize;

//+ (UIImage *)normalize:(UIImage *)image;

@end
