//
//  KCBlocks.h
//
//  Created by Larivain, Olivier on 7/14/11.
//

#import <Foundation/Foundation.h>

typedef void(^KCVoidBlock)(void);
typedef void(^KCIntegerBlock)(NSInteger result);

#ifndef KC_BLOCKS
#define KC_BLOCKS
#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })
#endif
