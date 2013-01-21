//
//  KCAnimation.h
//
//  Created by Larivain, Olivier on 7/9/11.
//

#import <Foundation/Foundation.h>


typedef void(^KCAnimationBlock)(void);
typedef void(^KCCompletionBlock)(BOOL);

#define SHORT_ANIMATION_DURATION 0.2
#define MEDIUM_ANIMATION_DURATION 0.35
#define LONG_ANIMATION_DURATION 0.5