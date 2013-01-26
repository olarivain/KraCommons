//
//  EHKInputViewController.h
//  EHKit
//
//  Created by kra on 9/27/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@interface KCInputViewController : NSObject

- (id) initWithScrollView: (UIScrollView *) scrollView
			  inputFields: (NSArray *) inputFields
	   accessoryInputView: (UIView *) inputAccessoryView
			 nextPrevious: (UISegmentedControl *) nextPrevious;

// the controlled scroll view
@property (nonatomic, strong, readwrite) IBOutlet UIScrollView *scrollView;
// list of text fied/views that can be cycled through with next/previous button
@property (nonatomic, strong, readwrite) IBOutlet IBOutletCollection(UIView) NSArray *textInputFields;

// the input accessory view. Will be injected into the text input fields if they don't have one already.
@property (nonatomic, strong, readwrite) IBOutlet UIView *defaultInputAccessoryView;
// holds the next/previous field buttons
@property (nonatomic, strong, readwrite) IBOutlet UISegmentedControl *nextPreviousSegmentedControl;

// turns the controller on/off.
@property (nonatomic, assign, readwrite) BOOL enabled;

// minimum margin between the bottom of the first responder and the top of the input accessory view.
@property (nonatomic, assign, readwrite) CGFloat margin;

// forces the current first responder to be visible. This controller can detect when the user taps on
// on a text field/view while the keyboard is already up. Call this method liberally in -textField:didBeginEditing:
// to make sure the guy while be visible.
- (void) makeFirstResponderVisible;


@end

#endif