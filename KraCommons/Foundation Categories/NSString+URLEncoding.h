//
//  NSString+URLEncoding.h
//  KonaTestURI
//
//  Created by Snehal on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NSString (URLEncoding)
- (NSString *) stringByURLEncoding;
- (NSString *) stringByURLDecoding;
@end