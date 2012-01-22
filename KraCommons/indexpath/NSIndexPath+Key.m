//
//  NSIndexPath+NSIndexPath_Key.m
//  KraCommons
//
//  Created by Larivain, Olivier on 12/31/11.
//

#import <UIKit/UIKit.h>
#import "NSIndexPath+Key.h"

@implementation NSIndexPath (NSIndexPath_Key)

- (NSString *) key
{
  return [NSString stringWithFormat: @"%i_%i", self.row, self.section];
}

@end
