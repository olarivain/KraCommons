//
//  OTKInputController.m
//  OTKit
//
//  Created by Olivier Larivain on 1/22/13.
//  Copyright (c) 2013 OpenTable, Inc. All rights reserved.
//

#import "KCInputViewController.h"

#import "UIView+FirstResponder.h"

#define DEFAULT_MARGIN 5.0f

@interface KCInputViewController() {
	// initialized to CGRectZero since clang 4.something
	// so no need to explicitely initialize
	CGRect _lastKeyboardRect;
	double _lastKeyboardAnimationDuration;
	BOOL _didInsetScrollView;
	BOOL _keyboardVisible;
}

@end

@implementation KCInputViewController

#pragma mark - lifecycle
- (void)awakeFromNib
{
    self.enabled = YES;
	self.margin = DEFAULT_MARGIN;
	
	if(self.nextPreviousSegmentedControl != nil) {
		NSAssert(self.nextPreviousSegmentedControl.numberOfSegments == 2, @"Next/Previous Segmented control must have exactly 2 segments");
	}
}

- (id) initWithScrollView: (UIScrollView *) scrollView
			  inputFields: (NSArray *) inputFields
	   accessoryInputView: (UIView *) inputAccessoryView
			 nextPrevious: (UISegmentedControl *) nextPrevious {
	self = [super init];
	if(self) {
		self.margin = DEFAULT_MARGIN;
		self.scrollView = scrollView;
		self.textInputFields = inputFields;
		self.defaultInputAccessoryView = inputAccessoryView;
		self.nextPreviousSegmentedControl = nextPrevious;
		self.enabled = YES;
	}
	return self;
}

- (void)dealloc
{
    self.enabled = NO;
}

- (void) setEnabled:(BOOL)enabled {
	// no change, abort
	if(_enabled == enabled) {
		return;
	}
	
	// update the ivar
    _enabled = enabled;
	
	// enable or disable the controller
    if (enabled) {
        
        // set the default input accessory view for all connected fields
        for (UIView *field in self.textInputFields) {
            [self useDefaultInputAccessoryView: YES
									  forField: field];
        }
        // register for keyboard events
        [self registerForKeyboardNotifications];
		return;
    }
	
	// otherwise, do the oppose: unregister, unwire the input toolbar
	[self unregisterForKeyboardNotifications];
	for (UIView *field in self.textInputFields) {
		[self useDefaultInputAccessoryView:NO
								  forField:field];
	}
}

#pragma mark - Making the current field visible
- (void) makeFirstResponderVisible {
	UIView *firstResponder = [self.scrollView kc_findFirstResponder];
	// nothing responder, no problem
	// same thing if we don't have a keyboard size yet.
	if(firstResponder == nil || CGRectEqualToRect(CGRectZero, _lastKeyboardRect ) ) {
		return;
	}
	
	// ok, so now, convert the last keyboard rect from its coordinate system to the scroll view's parent
	// this will make getting the intersection between the keyboard and the scroll view easier.
	// Note that the rect here actually contains the input accessory view. So we really just
	// have to convert this guy to the scroll view's parent.
	CGRect convertedKeyboardRect = [self.scrollView.window convertRect: _lastKeyboardRect
														toView: self.scrollView.superview];
	
	// we might have to inset the scroll view/scroller indicator since something is showing up.
	// The inset is actually exactly the intersection between the scroll view and the keyboard **in the scroll view's
	// parent coordinate.** We don't care at all if the keyboard doesn't overlap our scroll view.
	// It sounds stupid, but scroll views that don't extend to the bottom of the screen (think toolbar) or forms sheet
	// on iPad will make the intersection smaller than keyboard height and will throw off everything down the line.
	// No intersection, no inset.
	// No inset... No inset!
	
	// This could be made more accurate by checking if the content size is smaller than the frame, but I've been getting
	// mixed result with this approach - mostly because when that's the case, the content inset has to take the diff
	// between content size and frame size into account. It's good enough for now we'll say.
	CGRect scrollViewKeyboardIntersection = CGRectIntersection(self.scrollView.frame, convertedKeyboardRect);
	
	// figure out where the active field is in scroll view coordinates
	CGRect convertedFieldFrame = [firstResponder.superview convertRect: firstResponder.frame
															toView: self.scrollView];
	// and don't forget to shift by the content offset to bring this back to actual screen overlap
	convertedFieldFrame = CGRectOffset(convertedFieldFrame, -self.scrollView.contentOffset.x, -self.scrollView.contentOffset.y);
	// if the active field and the keyboard intersect, we have to change the content offset
	BOOL updateContentOffset = CGRectIntersectsRect(convertedKeyboardRect, convertedFieldFrame);
	
	// make sure the next/previous buttons are properly enabled/disabled, if applicable
	[self updateNextPreviousButtons];
	
	// we don't need to touch anything, call it a day.
	if(_didInsetScrollView && !updateContentOffset) {
		DDLogInfo(@"Not touching.");
		return;
	}
	DDLogInfo(@"Touching.");
	
	CGPoint contentOffset = self.scrollView.contentOffset;
	if(updateContentOffset) {
		// take the lowest point of the field + the margin, substract the visible part of the scroll view (i.e. scroll
		// view height minus the intersection height).
		// that's our new content offset! Yep, draw it on a piece of paper, if you don't believe me.
		CGFloat visiblScrollViewHeight = self.scrollView.frame.size.height - scrollViewKeyboardIntersection.size.height;
		contentOffset.y = CGRectGetMaxY(convertedFieldFrame) + self.margin - visiblScrollViewHeight;
	}
	
	// copy then flip the updated content inset flag
	BOOL updateContentInset = !_didInsetScrollView;
	_didInsetScrollView = YES;
	
	KCVoidBlock animation = ^{
		if (updateContentInset) {
			// if we should be insetting, add to the existing inset. We wouldn't want ot mess existing offset
			// would we?
			UIEdgeInsets inset = self.scrollView.contentInset;
			inset.bottom += scrollViewKeyboardIntersection.size.height;
			self.scrollView.contentInset = inset;
			
			// the inset is the same for the scroll indicators
			inset = self.scrollView.scrollIndicatorInsets;
			inset.bottom += scrollViewKeyboardIntersection.size.height;
			self.scrollView.scrollIndicatorInsets = inset;
		}
		
		// apply content offset if needed
		if (updateContentOffset) {
			[self.scrollView setContentOffset: contentOffset];
		}
	};
	[UIView animateWithDuration: _lastKeyboardAnimationDuration
					 animations: animation];
}

#pragma mark - cycling through fields
- (IBAction) next: (id) sender {
	// no responder, just GTFO
	UIView *firstResponder = [self.scrollView kc_findFirstResponder];
	if(firstResponder == nil) {
		return;
	}
	
	// find the index
	NSInteger index = [self.textInputFields indexOfObject: firstResponder];
	// grab the next field, make it first responder and scroll if needed.
	UIView *nextField = [self.textInputFields boundSafeObjectAtIndex: index + 1];
	[nextField becomeFirstResponder];
	
	[self makeFirstResponderVisible];
}

- (IBAction) back: (id) sender {
	// no responder, just GTFO
	UIView *firstResponder = [self.scrollView kc_findFirstResponder];
	if(firstResponder == nil) {
		return;
	}
	
	// find the index
	NSInteger index = [self.textInputFields indexOfObject: firstResponder];
	// grab the next field, make it first responder and scroll if needed.
	UIView *nextField = [self.textInputFields boundSafeObjectAtIndex: index - 1];
	[nextField becomeFirstResponder];
	
	[self makeFirstResponderVisible];
}

- (void) updateNextPreviousButtons {
	UIView *firstResponder = [self.scrollView kc_findFirstResponder];
	NSInteger index = [self.textInputFields indexOfObject: firstResponder];
	
	// first segment is enabled if the index is beyond 0
	[self.nextPreviousSegmentedControl setEnabled: index > 0
								forSegmentAtIndex: 0];
	// next is enabled if we have one more element after the current one.
	[self.nextPreviousSegmentedControl setEnabled: index < (self.textInputFields.count - 1)
								forSegmentAtIndex: 1];
}

#pragma mark - Registering for keyboard events
- (void)registerForKeyboardNotifications {
	// meh. Booor-iiiing!
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
			   selector: @selector(keyboardWillShow:)
				   name: UIKeyboardWillShowNotification
				 object: nil];
	
    [center addObserver: self
			   selector: @selector(keyboardWillHide:)
				   name: UIKeyboardWillHideNotification
				 object: nil];
}

- (void)unregisterForKeyboardNotifications {
	// Yawn.
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self
					  name: UIKeyboardWillShowNotification
					object: nil];
    
    [center removeObserver: self
					  name: UIKeyboardWillHideNotification
					object: nil];
}

#pragma mark - Responding to keyboard notifications
- (void) keyboardWillShow: (NSNotification *) notification {
	CGRect newRect = [[notification.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect convertedNewKeyboardRect = [self.scrollView.window convertRect: newRect
																   toView: self.scrollView.superview];

	CGRect convertedKeyboardRect = [self.scrollView.window convertRect: _lastKeyboardRect
																toView: self.scrollView.superview];
	if(convertedNewKeyboardRect.size.height != convertedKeyboardRect.size.height) {
		[self removeContentInset: 0.0f clearLastKeyboardRect: NO];
		_didInsetScrollView = NO;
	}

	// copy the target keyboard rect and the animation duration over
	_lastKeyboardRect = newRect;
	_lastKeyboardAnimationDuration = [notification.userInfo doubleForKey: UIKeyboardAnimationDurationUserInfoKey];
	
	[self makeFirstResponderVisible];
	_keyboardVisible = YES;
}

- (void) keyboardWillHide: (NSNotification *) notification {
	double duration = [notification.userInfo doubleForKey: UIKeyboardAnimationDurationUserInfoKey];
	[self removeContentInset: duration clearLastKeyboardRect: YES];
}

- (void) removeContentInset: (double) duration clearLastKeyboardRect: (BOOL) clearLastKeyboardRect {
	CGRect convertedKeyboardRect = [self.scrollView.window convertRect: _lastKeyboardRect
																toView: self.scrollView.superview];
	CGRect scrollViewKeyboardIntersection = CGRectIntersection(self.scrollView.frame, convertedKeyboardRect);
	
	// unset the content inset and such
	KCVoidBlock animation = ^{
		// un-apply the inset modification we made in -showCurrentField
		UIEdgeInsets inset = self.scrollView.contentInset;
		inset.bottom -= scrollViewKeyboardIntersection.size.height;
        self.scrollView.contentInset = inset;
		
		inset = self.scrollView.scrollIndicatorInsets;
		inset.bottom -= scrollViewKeyboardIntersection.size.height;
        self.scrollView.scrollIndicatorInsets = inset;
    };
	
	KCCompletionBlock completion = ^(BOOL finished) {
		if(!clearLastKeyboardRect) {
			return ;
		}
		// clear the keyboard and copy the animation duration, we don't want stale data hanging around
		_lastKeyboardRect = CGRectZero;
		_lastKeyboardAnimationDuration = 0.0f;
	};
	
    [UIView animateWithDuration: duration
					 animations: animation
					 completion: completion];
}


#pragma mark - Injecting the default accessory view
- (void)useDefaultInputAccessoryView:(BOOL)useDefault forField:(UIView *)field
{
	// override only for text field and text views - let's not get ahead of ourselves,
	// this thing is trick enough already as is. If it works out well, we'll push it further.
	// actually, I'm not even sure this thing makes sense outside of text field/views, since they're
	// pretty much the only keyboard input views in iOS.
	if(![field isKindOfClass: UITextField.class] &&
	   ![field isKindOfClass: UITextView.class]) {
		return;
	}
	
	// get a referemce tp the current accessory view
	UIView *existingInputAccessoryView = field.inputAccessoryView;
	
	// casting to UITextField is kind of nasty, but it works - the message is defined
	// on both UITextField and UITextView, so it just works and avoid ugly code constructs
	UITextField *textField = (UITextField *) field;
	
	// set or unset the field's input accessory view
	// do no touch the existing input accessory view, unless it's either not set or ours
	if (useDefault && existingInputAccessoryView == nil) {
		textField.inputAccessoryView = self.defaultInputAccessoryView;
	}
	if (!useDefault && existingInputAccessoryView == self.defaultInputAccessoryView) {
		textField.inputAccessoryView = nil;
	}
}


@end
