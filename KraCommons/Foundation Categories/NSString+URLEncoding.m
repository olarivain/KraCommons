//
//  NSString+URLEncoding.m
//  KonaTestURI
//
//  Created by Snehal on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)

- (NSString *) stringByURLEncoding
{
    // self is considered to be a raw, decoded string
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                 kCFStringEncodingUTF8));
}


- (NSString *) stringByURLDecoding
{
    // self is considered to be a valid, URL encoded string
    return  (NSString*) CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapes(NULL,
                                                                                     (CFStringRef)self,
                                                                                     CFSTR("")));
}
@end
