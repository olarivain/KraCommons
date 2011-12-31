//
//  NibUtils.m
//  MediaManagement
//
//  Created by Kra on 3/6/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "KCNibUtils.h"

static NSString *deviceSuffix;

@interface KCNibUtils(private)
+ (NSString*) deviceSuffix;
@end
@implementation KCNibUtils

+ (BOOL) isiPad
{
  return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (NSString*) deviceSuffix
{
  if(deviceSuffix == nil)
  {
    deviceSuffix =   UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? @"_iPad"  : @"_iPhone";
  }
  
  return deviceSuffix;

}

+ (NSString*) nibName: (NSString*) name
{
  return [NSString stringWithFormat:@"%@%@", name, [KCNibUtils deviceSuffix]];
}

@end
