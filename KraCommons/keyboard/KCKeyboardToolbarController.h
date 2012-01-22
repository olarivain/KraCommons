//
//  KCKeyboardToolbarDelegat.h
//
//  Created by Larivain, Olivier on 9/14/11.
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
    // some keyboards might have an extra bar, e.g. for emoji support,
    // so we need to know what the previous position was
    CGRect previousSize;
    
    BOOL disabled;
}

@property (nonatomic, readwrite, assign) BOOL disabled;

@end
