//
//  EHKInputViewController.m
//  EHKit
//
//  Created by kra on 9/27/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import "KCInputViewController.h"
#import "UIView+FirstResponder.h"

@interface KCInputViewController ()

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (assign, nonatomic) CGSize mostRecentKeyboardSize;

- (void)registerForKeyboardNotifications;
- (void)unregisterForKeyboardNotifications;
- (void)keyboardWillShow:(NSNotification *)aNotification;
- (void)keyboardWillHide:(NSNotification *)aNotification;
- (void)showActiveField:(UIView *)activeField;
- (void)useDefaultInputAccessoryView:(BOOL)useDefault forField:(UIView *)field;
- (void)updateFieldNavigationControlForActiveField:(UIView *)field;
- (void)backgroundTapped;

@end

@implementation KCInputViewController

#pragma mark - Initializers

- (id)initWithScrollView:(UIScrollView *)scrollView
{
    self = [super init];
    if (self) {
        _scrollView = scrollView;
        self.enabled = YES;
    }
    return self;
}


#pragma mark - NSObject methods

- (void)awakeFromNib
{
    self.enabled = YES;
}

- (void)dealloc
{
    self.enabled = NO;
}

#pragma mark - IBAction methods

- (IBAction)fieldNavigationTapped:(UISegmentedControl *)sender
{
    NSUInteger fieldCount = self.textInputFields.count;
    NSUInteger fieldIndex = [self.textInputFields indexOfObject:self.activeField];
    if (fieldCount == 0 || fieldIndex == NSNotFound) {
        return;
    }

    NSInteger segmentIndex = [sender selectedSegmentIndex];
    if (segmentIndex == 0) {
        
        // find the previous field index
        if (fieldIndex > 0) {
            fieldIndex--;
        }
    } else if (segmentIndex == 1) {
        
        // find the next field index
        if (fieldIndex < fieldCount - 1) {
            fieldIndex++;
        }
    }
    
    // make the new field active
    UIView *field = [self.textInputFields objectAtIndex:fieldIndex];
    [field becomeFirstResponder];
    [self setActiveField:field];
}

- (IBAction)inputDoneTapped:(id)sender {
    [self.scrollView endEditing:YES];
}


#pragma mark - Public properties

- (void)setActiveField:(UIView *)activeField
{
    if (_activeField == activeField) {
        return;
    }
    _activeField = activeField;
    [self updateFieldNavigationControlForActiveField:activeField];
    [self showActiveField:activeField];
}

- (void)setEnabled:(BOOL)enabled
{
    // check if the property has changed
    if (_enabled == enabled) {
        return;
    }
    
    // update the ivar
    _enabled = enabled;
    
    // enable or disable the controller
    if (enabled) {
        
        // set the default input accessory view for all connected text fields
        for (UIView *field in self.textInputFields) {
            [self useDefaultInputAccessoryView:YES forField:field];
        }
        
        // capture taps anywhere on the view's background
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(backgroundTapped)];
        [self.tapGestureRecognizer setCancelsTouchesInView:NO];
        [self.scrollView addGestureRecognizer:_tapGestureRecognizer];
        
        // register for keyboard events
        [self registerForKeyboardNotifications];
    } else {
        [self unregisterForKeyboardNotifications];
        [self.scrollView removeGestureRecognizer:self.tapGestureRecognizer];
        
        // unset the default input accessory view
        for (UIView *field in self.textInputFields) {
            [self useDefaultInputAccessoryView:NO forField:field];
        }
    }
}


#pragma mark - Private methods

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardWillShowNotification is sent.
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    // Get the size of the keyboard
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.mostRecentKeyboardSize = kbSize;
    
    self.activeField = [self.scrollView kc_findFirstResponder];
}


// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillHide:(NSNotification *)aNotification
{
    KCVoidBlock animation = ^{
        UIScrollView *scrollView = self.scrollView;
        scrollView.contentInset = UIEdgeInsetsZero;
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        scrollView.contentOffset = CGPointZero;
    };
    [UIView animateWithDuration: SHORT_ANIMATION_DURATION animations: animation];
    
    _activeField = nil;
}

- (void)showActiveField:(UIView *)activeField
{
    // Can't do anything without an active field
    if (!activeField) {
        return;
    }
    
    UIScrollView *scrollView = self.scrollView;
    
    // Get the size of the keyboard or input view
    CGSize kbSize = self.mostRecentKeyboardSize;
    if (activeField.inputView) {
        kbSize = activeField.inputView.frame.size;
        
        // Add the input accessory view's height to the keyboard size
        UIView *inputAccView = [activeField inputAccessoryView];
        CGSize accSize = inputAccView ? inputAccView.frame.size : CGSizeZero;
        kbSize.height += accSize.height;
    }
    
    // Add a gap between the bottom of the active field and the keyboard
    kbSize.height += 2.0f;
    
    // Adjust content insets to make space for the keyboard
    BOOL needsContentInsets = NO;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    if (scrollView.contentInset.bottom != kbSize.height) {
        needsContentInsets = YES;
    }
    
    // If active field is hidden by the keyboard, scroll so it's visible
    BOOL needsContentOffset = NO;
    CGRect aRect = scrollView.bounds;
    aRect.size.height -= kbSize.height;
    CGRect frame = [scrollView convertRect:activeField.frame fromView:activeField.superview];
    CGPoint scrollPoint = CGPointZero;
    if (!CGRectContainsRect(aRect, frame) ) {
        scrollPoint = CGPointMake(0.0, frame.origin.y + frame.size.height - (aRect.size.height));
        if (scrollPoint.y > 0.0) {
            needsContentOffset = YES;
        }
    }
    
    // Perform animations
    if (needsContentInsets || needsContentOffset) {
        KCVoidBlock animation = ^{
            if (needsContentInsets) {
                scrollView.contentInset = contentInsets;
                scrollView.scrollIndicatorInsets = contentInsets;
            }
            
            if (needsContentOffset) {
                [scrollView setContentOffset: scrollPoint];
            }
        };
        [UIView animateWithDuration: SHORT_ANIMATION_DURATION
                         animations: animation];
    }

}

- (void)updateFieldNavigationControlForActiveField:(UIView *)field
{
    NSUInteger fieldCount = self.textInputFields.count;
    NSUInteger index = [self.textInputFields indexOfObject:field];
    
    BOOL previousEnabled = NO;
    BOOL nextEnabled = NO;
    if (fieldCount > 0 && index != NSNotFound) {
        previousEnabled = index > 0;
        nextEnabled = index < (fieldCount - 1);
    }
    
    
    [self.fieldNavigationControl setEnabled:previousEnabled forSegmentAtIndex:0];
    [self.fieldNavigationControl setEnabled:nextEnabled forSegmentAtIndex:1];
}

- (void)useDefaultInputAccessoryView:(BOOL)useDefault forField:(UIView *)field
{
	if(self.defaultInputAccessoryView == nil) {
		return;
	}
	
    // set or unset the default input accessory view for the given field
    if ([field isKindOfClass:[UITextField class]]) {
        UITextField *tf = (UITextField *)field;
        if (useDefault && !tf.inputAccessoryView) {
            tf.inputAccessoryView = self.defaultInputAccessoryView;
        }
        if (!useDefault && tf.inputAccessoryView == self.defaultInputAccessoryView) {
            tf.inputAccessoryView = nil;
        }
    } else if ([field isKindOfClass:[UITextView class]]) {
        UITextView *tv = (UITextView *)field;
        if (useDefault && !tv.inputAccessoryView) {
            tv.inputAccessoryView = self.defaultInputAccessoryView;
        }
        if (!useDefault && tv.inputAccessoryView == self.defaultInputAccessoryView) {
            tv.inputAccessoryView = nil;
        }
    }
}

- (void)backgroundTapped
{
    [self.scrollView endEditing:YES];
}

@end

#endif