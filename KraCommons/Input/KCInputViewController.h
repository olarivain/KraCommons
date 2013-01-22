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

- (id)initWithScrollView:(UIScrollView *)scrollView;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *textInputFields;
@property (strong, nonatomic) IBOutlet UISegmentedControl *fieldNavigationControl;
@property (strong, nonatomic) IBOutlet UIView *defaultInputAccessoryView;

@property (strong, nonatomic) UIView *activeField;
@property (assign, nonatomic) BOOL enabled;

- (IBAction)fieldNavigationTapped:(id)sender;
- (IBAction)inputDoneTapped:(id)sender;

@end

#endif