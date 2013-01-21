//
//  NSString+extensions.h

//
//  Created by kra on 11/4/08.
//  Copyright 2008 kra.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Replacement)

+ (NSString *) kc_localizedString: (NSString *) key bySubstituting: (NSArray *) substitutions;

- (NSString *) kc_stringBySubstituting: (NSArray *) substitutions;
- (NSString *) kc_stringByReplacingHTMLTags;
- (NSString *) kc_stringByTrimmingSpaces;
@end
