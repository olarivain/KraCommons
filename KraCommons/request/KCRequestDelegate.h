//
//  ECDownloadService.h
//  ECUtil
//
//  Created by Kra on 6/29/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCRequestQueue.h"

@class KCRequestQueueItem;
@class MMServer;

/*
 High level wrapper on the RequestQueue, provides convenience with host/port so it doesn't have to be constantly built in. Also, provides HTTP escaping, parameter handling etc.
 */
@interface KCRequestDelegate : NSObject {
  __strong NSString *host;
  NSInteger port;
}

+ (id) requestDelegateWithHost: (NSString *) host;
+ (id) requestDelegateWithHost: (NSString *) host andPort: (NSInteger) port;

// simple GET, no params
- (KCRequestQueueItem*) requestWithPath: (NSString *) path andCallback: (KCRequestCallback) callback;

// simple GET, params are considered HTTP URL params
- (KCRequestQueueItem*) requestWithPath: (NSString *) path params: (NSDictionary *) params andCallback: (KCRequestCallback) callback;
// exposes method, params are considered HTTP URL params if method is GET, will be serialized to JSON as body otherwise
- (KCRequestQueueItem*) requestWithPath: (NSString *) path params: (NSDictionary *) params method: (NSString *) method andCallback: (KCRequestCallback) callback;
@end
