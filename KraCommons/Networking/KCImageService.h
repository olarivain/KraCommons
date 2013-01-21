//
//  Created by Olivier Larivain on 1/10/13.
//  Copyright (c) 2012  kra.. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@class KCImageDownloadClient;

typedef void(^OTFImageCallback)(UIImage *);


@interface KCImageService : NSObject {
    KCImageDownloadClient *imageClient;
    NSCache *cache;
    NSOperationQueue *localResizeQueue;
}

+ (KCImageService *) sharedInstance;

// Cache size in MB
+ (void) setCacheMaxSize: (NSUInteger) maxSize;

// any picture out there on the interweb
+ (void) imageWithURL: (NSString *) url 
          andCallback: (OTFImageCallback) callback;

+ (void) imageWithURL: (NSString *) url 
              forSize: (CGSize) size  
          andCallback: (OTFImageCallback) callback;

+ (void) clearInMemoryCache;

@end
#endif