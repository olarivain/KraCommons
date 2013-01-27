//
//  UIButton+ResizableImage.m
//  OTKit
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright (c) 2013 kra. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import "UIImage+Stretchable.h"

#import "UIButton+ResizableImage.h"

@implementation UIButton (ResizableImage)

- (void) updateBackgroundWithDefaultCaps {
	[self updateBackgroundWithDefaultCapsForState: UIControlStateNormal];
	[self updateBackgroundWithDefaultCapsForState: UIControlStateSelected];
	[self updateBackgroundWithDefaultCapsForState: UIControlStateHighlighted];
}

- (void) updateBackgroundWithDefaultCapsForState: (UIControlState) state {
	UIImage *image = [self backgroundImageForState: state];
	[self setBackgroundImage: [image stretchableImageWithDefaultCaps]
					forState: state];
}

- (void) updateBackgroundWithResizableCaps: (UIEdgeInsets) caps
{
	[self updateBackgroundWithResizableCaps: caps
								   forState: UIControlStateNormal];
	[self updateBackgroundWithResizableCaps: caps
								   forState: UIControlStateSelected];
	[self updateBackgroundWithResizableCaps: caps
								   forState: UIControlStateHighlighted];

}

- (void) updateBackgroundWithResizableCaps: (UIEdgeInsets) caps
								  forState: (UIControlState) state {
	UIImage *image = [self backgroundImageForState: state];
	[self setBackgroundImage: [image resizableImageWithCapInsets: caps]
					forState: state];
}

@end

#endif