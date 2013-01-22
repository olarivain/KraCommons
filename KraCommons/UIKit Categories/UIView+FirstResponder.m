//
//  UIView+FirstResponder.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/21/13.
//  Copyright (c) 2013 Edmunds. All rights reserved.
//

#import "UIView+FirstResponder.h"

@implementation UIView (FirstResponder)

- (UIView *) kc_findFirstResponder {
	if (self.isFirstResponder) {
        return self;
    }
    for (UIView *subView in self.subviews) {
		UIView *responder = [subView kc_findFirstResponder];
		if(responder != nil) {
			return responder;
		}
    }
	
	return nil;
}

- (BOOL) kc_findAndResignFirstResponder{
	UIView *responder = [self kc_findFirstResponder];
	[responder resignFirstResponder];
	
    return responder != nil;
}

@end
