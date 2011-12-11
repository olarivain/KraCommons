//
//  UIImage+Retina.m
//  ECUtil
//
//  Created by Larivain, Olivier on 8/4/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import "UIImage+Retina.h"


@implementation UIImage (UIImage_Retina)

+ (UIImage *)retinaImageWithData:(NSData *)data {
    if(data == nil) {
        return nil;
    }
    
    // let UIImage API decode data to bitmap
    UIImage *image = [UIImage imageWithData:data];
    
    // if image already has the right scale factor, just return it
    CGFloat scale = [UIScreen mainScreen].scale;
    if (image.scale == scale) {    
        return image;
    } 
    
    // otherwise, resize it
    return [UIImage imageWithCGImage:[image CGImage] scale: scale orientation:UIImageOrientationUp];        
}


+ (UIImage *)retinaImageWithData:(NSData *)data andSize:(CGSize)size {
    if(data == nil) {
        return nil;
    }
    
    UIImage *retinaImage = [self retinaImageWithData:data];
    return [self scaleImage:retinaImage toSize:size];
}

+ (UIImage *)scaleImage:(UIImage *)original toSize:(CGSize)newSize {
    
    CGImageRef imageRef = original.CGImage;
    CGFloat desiredRatio = newSize.width / newSize.height; 
    CGFloat aspectRatio = original.size.width / original.size.height;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize scaledSize = CGSizeMake(newSize.width * scale, newSize.height * scale);
    CGSize drawSize = CGSizeZero;
    if (fabs(aspectRatio - desiredRatio) < 0.1) {
        drawSize = scaledSize;
    } else if(aspectRatio > desiredRatio) { // wider
        drawSize = CGSizeMake(scaledSize.width, scaledSize.width / aspectRatio);
    } else { // taller
        drawSize = CGSizeMake(scaledSize.height / (1.0/aspectRatio), scaledSize.height);
    } 
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                scaledSize.width,
                                                scaledSize.height,
                                                8,
                                                scaledSize.width * 4, // bytes per row, 4 bytes per pixel RGBA
                                                colorSpace,
                                                kCGImageAlphaPremultipliedLast);
    
    // Set the quality level to use when rescaling
    BOOL highPerformance = [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)];
    CGContextSetInterpolationQuality(bitmap, highPerformance ? kCGInterpolationHigh : kCGInterpolationLow);
    
    // Draw into the context; this scales the image
    CGContextSetFillColorWithColor(bitmap, [[UIColor clearColor] CGColor]);
    CGContextFillRect(bitmap, CGRectMake(0, 0, scaledSize.width, scaledSize.height));
    CGContextDrawImage(bitmap, CGRectMake((scaledSize.width - drawSize.width) / 2, (scaledSize.height - drawSize.height) / 2, drawSize.width, drawSize.height), imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:[UIScreen mainScreen].scale orientation:original.imageOrientation];
    
    // Clean up
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(newImageRef);
    
    return newImage;
}
@end
