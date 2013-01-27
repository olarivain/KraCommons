//
//  KCBlocks.h
//
//  Created by Larivain, Olivier on 7/14/11.
//

#import <Foundation/Foundation.h>

typedef void(^KCVoidBlock)(void);
typedef void(^KCIntegerBlock)(NSInteger result);
typedef void(^KCBooleanBlock)(BOOL boolean);

// nserror block
typedef void(^KCErrorBlock)(NSError *error);

#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })
#define InvokeBlock(block, ...) if(block) block(__VA_ARGS__)
