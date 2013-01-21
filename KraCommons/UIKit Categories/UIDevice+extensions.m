//
//  UIDevice+extensions.m

//
//  Created by kra on 8/30/12.
//  Copyright (c) 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#include <sys/types.h>
#include <sys/sysctl.h>

#import "UIDevice+extensions.h"

@implementation UIDevice(Hardware)

+ (NSString *) platform{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    return platform;
}

+ (BOOL)hasRetinaDisplay {
    // scale is a float, avoid comparing it directly to values
    return [UIScreen mainScreen].scale > 1.0f;
}

+ (BOOL)hasMultitasking {
	UIDevice *currentDevice = [UIDevice currentDevice];
    if ([currentDevice respondsToSelector:@selector(isMultitaskingSupported)]) {
        return [currentDevice isMultitaskingSupported];
    }
    return NO;
}

+ (BOOL)isTalliPhone {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height > 480;
	
}

@end
#endif