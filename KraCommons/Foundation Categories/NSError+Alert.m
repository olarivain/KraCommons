//
//  NSError+Alert.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/17/13.
//  Copyright (c) 2013 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "NSError+Alert.h"

#import "NSError+Creation.h"

@implementation NSError (Alert)

- (BOOL) present {
	return [self presentWithTitleSubstitution: nil
						  messageSubstitution: nil];
}

- (BOOL) presentWithTitleSubstitution: (NSArray *) titleSubstitution
				  messageSubstitution: (NSArray *) messageSubstitution {
	NSString *titleKey = [NSString stringWithFormat: @"error-title-%i", self.code];
	NSString *title = [self kc_stringForKey: titleKey WithDefault: @"Error"];
	title = [title kc_stringBySubstituting: titleSubstitution];
	
	NSString *messageKey = [NSString stringWithFormat:@"error-message-%i", self.code];
	NSString *message = [self kc_stringForKey: messageKey WithDefault: self.kc_errorMessage];
	message = [message kc_stringBySubstituting: messageSubstitution];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
														message: message
													   delegate: nil
											  cancelButtonTitle: NSLocalizedString(@"alert.default.cancel", nil)
											  otherButtonTitles: nil];
	[alertView show];
	return YES;

}

- (NSString *) kc_stringForKey: (NSString *) key WithDefault: (NSString *) value {
	NSString *localizedValue = NSLocalizedString(key, nil);
	// the value is the key, return the default value
	if([localizedValue isEqual: key]) {
		return value;
	}
	
	return localizedValue;
}

@end

#endif
