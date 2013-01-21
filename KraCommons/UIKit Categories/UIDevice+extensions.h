//
//  UIDevice+extensions.h

//
//  Created by kra on 8/30/12.
//  Copyright (c) 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@interface UIDevice(Hardware)

+ (NSString *)platform;
+ (BOOL)hasRetinaDisplay;
+ (BOOL)hasMultitasking;
+ (BOOL)isTalliPhone;

@end
#endif