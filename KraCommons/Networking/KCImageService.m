//
//  EHFImageService.m
//  EHFoundation
//
//  Created by Olivier Larivain on 1/10/13.
//  Copyright (c) 2012  kra.. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KCImageService.h"

#import "KCImageDownloadClient.h"
#import "UIImage+Retina.h"

static KCImageService *sharedInstance;


@implementation KCImageService

+ (KCImageService *) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KCImageService alloc] init];
    });
    return sharedInstance;
}

- (id) init {
    self = [super init];
    if(self) {
        cache = [[NSCache alloc] init];
        
        // initialize the image download client
        imageClient = [KCImageDownloadClient sharedClient];
        
        // default the cache size to 20MB on recent devices (3GS+) and
        // limit to 5MB on old devices.
        UIDevice *device = [UIDevice currentDevice];
        SEL multitaskingSelector = @selector(multitaskingSupported);
        NSUInteger cacheSize = [device respondsToSelector: multitaskingSelector] ? 20 : 5;
        [cache setTotalCostLimit: 1024 * 1024 * cacheSize];
        
        //create operation queue
        localResizeQueue = [[NSOperationQueue alloc] init];
        [localResizeQueue setMaxConcurrentOperationCount: 5];
    }
    return self;
}

#pragma mark - In memory cache
+ (void) setCacheMaxSize: (NSUInteger) maxSize {
    KCImageService *service = [KCImageService sharedInstance];
    [service setCacheMaxSize: maxSize];
}

- (void) setCacheMaxSize:(NSUInteger)maxSize {
    [cache setTotalCostLimit: maxSize * 1024 * 1024] ;
}

+ (void) clearInMemoryCache {
    KCImageService *service = [KCImageService sharedInstance];
    [service clearInMemoryCache];
}

- (void) clearInMemoryCache {
    [cache removeAllObjects];
}

#pragma mark - Scheduling image downloads
+ (void) imageWithURL: (NSString *) url  andCallback: (OTFImageCallback) callback {
    return [KCImageService imageWithURL: url
								 forSize: CGSizeZero
							 andCallback: callback];
}

+ (void) imageWithURL: (NSString *) url forSize: (CGSize) size  andCallback: (OTFImageCallback) callback {
    KCImageService *imageService = [KCImageService sharedInstance];
    [imageService imageWithURL: url 
                       forSize: size 
                   andCallback: callback];
}

- (void) imageWithURL: (NSString *)url
              forSize: (CGSize)size
          andCallback:(OTFImageCallback)callback {
    // no path passed in, don't do anything
    if([url length] == 0) {
        DispatchMainThread(callback, nil);
        return;
    }
	
    NSString *cacheKey = [NSString stringWithFormat:@"%@__%fx%f", url, size.width, size.height];
    
    // image is already cached, don't go out for it
    UIImage *cachedImage = [cache objectForKey: cacheKey];
    if(cachedImage != nil) {
        DispatchMainThread(callback, cachedImage);
        return;
    }
    
    [imageClient getUrl: url
             parameters: nil
           cacheRequest: YES
                success: ^(AFHTTPRequestOperation *operation, id responseObject) {
                    [self resizeImage: responseObject
                               toSize: size
                             cacheKey: cacheKey
                         withCallback: callback];
                    
                }
                failure: ^(AFHTTPRequestOperation *operation, NSError *error) {
                    DispatchMainThread(callback, nil);
                }];
    
}

#pragma mark - local image processing

+ (void) imageWithImage:(UIImage *) image
                forSize:(CGSize) size
               cacheKey:(id) key //not supported yet
           withCallBack: (OTFImageCallback) callback {
    
    [[KCImageService sharedInstance] imageWithImage:image
											 forSize:size
											cacheKey:key
										withCallBack:callback];
}

- (void) imageWithImage:(UIImage *) image
                forSize:(CGSize) size
               cacheKey:(id) key //not supported yet
           withCallBack: (OTFImageCallback) callback {
    
    if(CGSizeEqualToSize(size, CGSizeZero)) {
        DispatchMainThread(callback, image);
        return;
    }
    
    //create block to resize image
    KCVoidBlock imageCallback = ^{
        UIImage *scaledImage = [UIImage scaleImage: image 
                                            toSize: size];
        DispatchMainThread(callback, scaledImage);
    };
    //dispatch image resize block on queue
    [localResizeQueue addOperationWithBlock:imageCallback];
    
    
}



#pragma mark - Image processing
- (void) resizeImage: (NSData *) data
              toSize: (CGSize) size 
            cacheKey: (NSString *) cacheKey
        withCallback: (OTFImageCallback) callback {
    
    UIImage *image = [UIImage retinaImageWithData: data];
    // no particular size was requested, so just callback with the original image
    if(CGSizeEqualToSize(size, CGSizeZero)) {
        [cache setObject: image
				  forKey: cacheKey
					cost: image.size.width * image.size.height * 4];
        DispatchMainThread(callback, image);
        return;
    }
    
    // resize and dispatch back on main thread
    
    UIImage *scaledImage = [UIImage scaleImage: image
                                        toSize: size];
        [cache setObject: scaledImage
                  forKey: cacheKey 
                    cost: scaledImage.size.width * scaledImage.size.height * 4];
    DispatchMainThread(callback, scaledImage);
}

@end
#endif