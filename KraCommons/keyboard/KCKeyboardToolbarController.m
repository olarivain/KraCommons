//
//  KCKeyboardToolbarDelegat.m
//
//  Created by Larivain, Olivier on 9/14/11.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KCKeyboardToolbarController.h"
#import "KCAnimation.h"

@interface KCKeyboardToolbarController()
- (void)moveKeyboardToolbar:(CGRect)keyboardRect 
               withDuration:(NSTimeInterval)duration 
            keyboardVisible:(BOOL) keyboardVisible;

- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardDidShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;
- (void)keyboardDidHide:(NSNotification*)notification;
@end

@implementation KCKeyboardToolbarController

- (id)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self 
                   selector:@selector(keyboardWillShow:) 
                       name:UIKeyboardWillShowNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardDidShow:) 
                       name:UIKeyboardDidShowNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardWillHide:) 
                       name:UIKeyboardWillHideNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardDidHide:) 
                       name:UIKeyboardDidHideNotification 
                     object:nil];
        
        previousSize.size = CGSizeZero;
        previousSize.origin = CGPointZero;
    }
    
    return self;
}

- (void) dealloc 
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self];
}

@synthesize disabled;

- (void) setDisabled:(BOOL) flag 
{
    if(flag == disabled) 
    {
        return;
    }
    
    disabled = flag;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if(flag) 
    {
        [center removeObserver: self];
    } 
    else 
    {
        [center addObserver:self 
                   selector:@selector(keyboardWillShow:) 
                       name:UIKeyboardWillShowNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardDidShow:) 
                       name:UIKeyboardDidShowNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardWillHide:) 
                       name:UIKeyboardWillHideNotification 
                     object:nil];
        
        [center addObserver:self 
                   selector:@selector(keyboardDidHide:) 
                       name:UIKeyboardDidHideNotification 
                     object:nil];
    }
}

#pragma mark - Keyboard management

- (void)keyboardWillShow: (NSNotification*) notification 
{
    // ask delegate to hide keyboard before showing it again if the previous size is
    // set. This is due to keyboard changing size when switching languages, for example the asian
    // keyboards have an extra row of buttons in it. Not doing this will result in the delegate
    // getting a different size on will hide than they had on will show, hence the hide, then show again 
    // approach taken here.
    if(!CGSizeEqualToSize(previousSize.size, CGSizeZero)) 
    {
        // notify delegate
        if([delegate respondsToSelector: @selector(willHideKeyboard:withToolbar:)])
        {
            [delegate willHideKeyboard: previousSize withToolbar: keyboardToolbar];
        }   
    }
    
    // grab keyboard rect in window coordinates
    NSDictionary* info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self moveKeyboardToolbar:keyboardRect withDuration:duration keyboardVisible:TRUE];
    
    // notify delegate
    [delegate willShowKeyboard:keyboardRect withToolbar: keyboardToolbar];
    
    previousSize = keyboardRect;
}

- (void) keyboardDidShow: (NSNotification*) notification 
{
    SEL selector = @selector(didShowKeyboard:);
    if([delegate respondsToSelector: selector]) 
    {
        // grab keyboard rect in window coordinates
        NSDictionary* info = [notification userInfo];
        CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        [delegate didShowKeyboard:keyboardRect withToolbar: keyboardToolbar];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification 
{
    previousSize.size = CGSizeZero;
    
    // grab keyboard rect in window coordinates
    NSDictionary* info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self moveKeyboardToolbar:keyboardRect withDuration:duration keyboardVisible: FALSE];
    
    // notify delegate
    if([delegate respondsToSelector: @selector(willHideKeyboard:withToolbar:)])
    {
        [delegate willHideKeyboard:keyboardRect withToolbar: keyboardToolbar];
    }
}

- (void) keyboardDidHide: (NSNotification*) notification 
{
    SEL selector = @selector(didHideKeyboard:withToolbar:);
    if([delegate respondsToSelector: selector]) 
    {
        // grab keyboard rect in window coordinates
        NSDictionary* info = [notification userInfo];
        CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        [delegate didHideKeyboard:keyboardRect withToolbar: keyboardToolbar];
    }
}

- (void)moveKeyboardToolbar:(CGRect)keyboardRect 
               withDuration:(NSTimeInterval)duration 
            keyboardVisible:(BOOL)keyboardVisible {    
    //make keyboard visible on before slideing it up
    if(keyboardVisible) 
    {
        keyboardToolbar.hidden = NO;
    }
    
    KCAnimationBlock animation = ^{
        if (keyboardVisible) 
        {            
            //use translation to slide toolbar up
            CGFloat tx = 0;
            CGFloat ty = -keyboardRect.size.height;
            //set absolute point to shich to slide toolbar to (relative to origin position)
            CGAffineTransform transform = CGAffineTransformMakeTranslation(tx, ty);
            keyboardToolbar.transform = transform;
        } 
        else 
        {
            //slide right under visible area
            CGSize toolbarSize = keyboardToolbar.frame.size;
            CGAffineTransform transform = CGAffineTransformMakeTranslation(0, toolbarSize.height);
            keyboardToolbar.transform = transform;
        }
    };
    
    [UIView animateWithDuration: duration 
                          delay: 0 
                        options: UIViewAnimationOptionAllowUserInteraction
                     animations: animation 
                     completion: EMPTY_COMPLETION];
    
}

@end
#endif