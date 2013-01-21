//
//  KCGlobalConfiguration.m
//  
//
//  Created by Kra on 12/28/12.
//  Copyright (c) 2012 OpenTable, Inc. All rights reserved.
//

#import "KCGlobalConfiguration.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "UIColor+extensions.h"
#endif
static KCGlobalConfiguration *sharedInstance;

@interface KCGlobalConfiguration () {
	NSLocale *_propertyLocale;
}
@property (nonatomic, readwrite, strong) NSDictionary *configuration;
@property (readonly) NSString *propertySuffix;
@end

@implementation KCGlobalConfiguration

+ (KCGlobalConfiguration *) sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KCGlobalConfiguration alloc] init];
    });
    
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    if(self)
    {
        // locate the path to the GlobalConfiguration.plist file
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *configurationPlistPath = [bundle pathForResource:@"GlobalConfiguration" ofType:@"plist"];
        
        // load if possible
        if(configurationPlistPath == nil)
        {
            DDLogWarn(@"**** Fatal: Could not load Configuration.plist");
            self.configuration = [NSMutableDictionary dictionary];
        }
        else
        {
            self.configuration = [NSMutableDictionary dictionaryWithContentsOfFile: configurationPlistPath];
        }
    }
    
    return self;
}

#pragma mark - Synthetic getters
- (NSBundle *) mainBundle {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_mainBundle = [NSBundle mainBundle];
	});
	
	return _mainBundle;
}

#pragma mark - URL
- (NSString *) baseUrl
{
    return [self.configuration objectForKey: @"baseUrl"];
}
#pragma mark - Colors
#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (UIColor *) colorForKey: (NSString *) key defaultColor: (UIColor *) defaultColor {
	NSInteger number = [self.configuration hexaIntegerForKey: key];
    if(number == 0)
    {
        return defaultColor;
    }
    
    return [UIColor kc_colorWithHex: (unsigned int) number];
}
#endif

@end
