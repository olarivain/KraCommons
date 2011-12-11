//
//  ECAnimation.h
//  EdmundsUI
//
//  Created by Larivain, Olivier on 7/9/11.
//  Copyright 2011 Edmunds.com. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void(^KCAnimationBlock)(void);
typedef void(^KCCompletionBlock)(BOOL);

#define EMPTY_COMPLETION ^(BOOL finished){}

#define SHORT_ANIMATION_DURATION 0.2
#define MEDIUM_ANIMATION_DURATION 0.35
#define LONG_ANIMATION_DURATION 0.5