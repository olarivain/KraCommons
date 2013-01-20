//
//  NSIndexPath+NSIndexPath_Key.h
//  KraCommons
//
//  Created by Larivain, Olivier on 12/31/11.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@interface NSIndexPath (NSIndexPath_Key)

@property (nonatomic, readonly) NSString *key;

@end
#endif