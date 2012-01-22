//
//  UIImage+Retina.m
//
//  Created by Larivain, Olivier on 8/4/11.
//

#import "UIImage+Retina.h"

static BOOL highPerformance;

@implementation UIImage (UIImage_Retina)

+ (UIImage *)retinaImageWithData:(NSData *)data 
{
    if(data == nil) 
    {
        return nil;
    }
    
    // let UIImage API decode data to bitmap
    UIImage *image = [UIImage imageWithData:data];
    
    // if image already has the right scale factor, just return it
    CGFloat scale = [UIScreen mainScreen].scale;
    if (image.scale == scale) 
    {    
        return image;
    } 
    
    // otherwise, resize it
    return [UIImage imageWithCGImage: image.CGImage 
                               scale: scale 
                         orientation:UIImageOrientationUp];        
}


+ (UIImage *)retinaImageWithData:(NSData *)data andSize:(CGSize)size 
{
    if(data == nil) 
    {
        return nil;
    }
    
    UIImage *retinaImage = [self retinaImageWithData:data];
    return [self scaleImage:retinaImage toSize:size];
}

+ (UIImage *)scaleImage:(UIImage *)original toSize:(CGSize)newSize 
{
    
    CGImageRef imageRef = original.CGImage;
    CGFloat desiredRatio = newSize.width / newSize.height; 
    CGFloat aspectRatio = original.size.width / original.size.height;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize scaledSize = CGSizeMake(newSize.width * scale, newSize.height * scale);
    CGSize drawSize = CGSizeZero;
    if (fabs(aspectRatio - desiredRatio) < 0.1) 
    {
        drawSize = scaledSize;
    } 
    else if(aspectRatio > desiredRatio) // wider
    { 
        drawSize = CGSizeMake(scaledSize.width, scaledSize.width / aspectRatio);
    } 
    else // taller
    { 
        drawSize = CGSizeMake(scaledSize.height * aspectRatio, scaledSize.height);
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
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIDevice *device = [UIDevice currentDevice];
        highPerformance = [device respondsToSelector:@selector(isMultitaskingSupported)];
    });
    
    CGInterpolationQuality quality = highPerformance ? kCGInterpolationHigh : kCGInterpolationLow;
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextSetFillColorWithColor(bitmap, [UIColor clearColor].CGColor);
    CGRect fillRect;
    fillRect.origin = CGPointZero;
    fillRect.size = CGSizeMake(scaledSize.width, scaledSize.height);
    // fill it with transparent color
    CGContextFillRect(bitmap, fillRect);
    
    // center the image in the draw rect
    CGRect imageRect;
    CGFloat xOrigin = (scaledSize.width - drawSize.width) / 2.0f;
    CGFloat yOrigin = (scaledSize.height - drawSize.height) / 2.0f;
    imageRect.origin = CGPointMake(xOrigin, yOrigin);
    imageRect.size = CGSizeMake(drawSize.width, drawSize.height);
    // and paint in there
    CGContextDrawImage(bitmap, imageRect, imageRef);
    
    // Get the resized image from the context and create a UIImage from it
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage: newImageRef 
                                            scale: scale 
                                      orientation: original.imageOrientation];
    
    // Clean up memory
    CGContextRelease(bitmap);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(newImageRef);
    
    return newImage;
}
@end
