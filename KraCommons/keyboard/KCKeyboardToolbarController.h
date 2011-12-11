//
//  ECKeyboardToolbarDelegat.h
//  EdmundsUI
//
//  Created by Larivain, Olivier on 9/14/11.
//  Copyright 2011 Edmunds.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KCKeyboardToolbarDelegate <NSObject>

- (void) willShowKeyboard:(CGRect)keyboardFrame withToolbar:(UIToolbar *)keybowrdToolbar;

@optional
- (void) didShowKeyboard:(CGRect)keyboardFrame withToolbar:(UIToolbar *)keybowrdToolbar;
- (void) willHideKeyboard:(CGRect)keyboardFrame withToolbar:(UIToolbar *)keybowrdToolbar;
- (void) didHideKeyboard:(CGRect)keyboardFrame withToolbar:(UIToolbar *)keybowrdToolbar;

@end

@interface KCKeyboardToolbarController : NSObject {
    IBOutlet __strong UIToolbar *keyboardToolbar;
    IBOutlet __weak id<KCKeyboardToolbarDelegate> delegate;
    CGRect previousSize;
    
    BOOL disabled;
}

@property (nonatomic, readwrite, assign) BOOL disabled;

@end
