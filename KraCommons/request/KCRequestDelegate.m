//
//  ECDownloadService.m
//  ECUtil
//
//  Created by Kra on 6/29/11.
//  Copyright 2011 Kra. All rights reserved.
//

#import "KCRequestDelegate.h"

#import "KCRequestQueueItem.h"

@interface KCRequestDelegate()
- (id) initWithHost: (NSString *) host andPort: (NSInteger) port;
@end

@implementation KCRequestDelegate
+ (id) requestDelegateWithHost: (NSString *) host
{
  return [[KCRequestDelegate alloc] initWithHost: host andPort: 80];  
}

+ (id) requestDelegateWithHost: (NSString *) host andPort: (NSInteger) port
{
  return [[KCRequestDelegate alloc] initWithHost: host andPort: port];
}

- (id) initWithHost: (NSString *) aHost andPort: (NSInteger) aPort
{
  self = [super init];
  if(self) 
  {
    host = aHost;
    port = aPort;
  }
  return self;
}

#pragma mark - Convenience method
- (NSString *) paramString: (NSDictionary*) params 
{
  if(params == nil || [params count] == 0) 
  {
    return nil;
  }
  
  NSMutableString *paramString = [NSMutableString stringWithString:@"?"];
  NSArray *allKeys = [params allKeys];
  // build the param string by going through all params, create key=value fragment, don't forget to HTTP escape params
  for(NSString *key in allKeys) 
  {
    id value = [params objectForKey: key];
    
    // serialize arrays their own way
    if([value isKindOfClass: [NSArray class]]) 
    {
      NSArray *valueArray = (NSArray *) value;
      for(__strong id subvalue in valueArray) 
      {
        // we have a number, make sure we grab the string representation
        if([subvalue isKindOfClass: [NSNumber class]]) 
        {
          subvalue = [(NSNumber *) subvalue stringValue];
        } 
        
        // escape the string if possible
        if([subvalue respondsToSelector:@selector(stringByAddingPercentEscapesUsingEncoding:)])
        {
          subvalue = [subvalue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        // append value and & if we're not processing the last subvalue
        [paramString appendFormat:@"%@=%@", key, subvalue];
        [paramString appendString: @"&"];
      }
      
      // skip to next params
      continue;
    }
    
    // we have a number, make sure we grab the string representation
    if([value isKindOfClass: [NSNumber class]]) 
    {
      value = [(NSNumber *) value stringValue];
    } 
    
    // escape the string if possible
    if([value respondsToSelector:@selector(stringByAddingPercentEscapesUsingEncoding:)])
    {
      value = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    [paramString appendFormat:@"%@=%@", key, value];
    
    // append & unless we're processing the last param
    if(key != [allKeys lastObject]) 
    {
      [paramString appendString:@"&"];
    }
  }
  return paramString;
}


#pragma mark - Request methods
- (KCRequestQueueItem*) requestWithPath: (NSString *) path andCallback: (KCRequestCallback) callback
{
  return [self requestWithPath: path params: nil andCallback: callback];
}

- (KCRequestQueueItem*) requestWithPath: (NSString *) path 
                                 params: (NSDictionary *) params 
                            andCallback: (KCRequestCallback) callback 
{
  return [self requestWithPath: path params: params method: @"GET" andCallback: callback];
}

#warning add caching support
- (KCRequestQueueItem*) requestWithPath: (NSString *) path 
                                 params: (NSDictionary *) params 
                                 method: (NSString *) method 
                            andCallback: (KCRequestCallback) callback
{
  NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  NSString *urlString = [NSString stringWithFormat:@"http://%@:%i%@", host, port, escapedPath];

  NSData *data = nil;
  // process parameters appropriately, depending on requested method
  if([@"GET" caseInsensitiveCompare: method] == NSOrderedSame) 
  {
    NSString *paramString = [self paramString: params];
    if(paramString) 
    {
        urlString = [NSString stringWithFormat:@"%@%@", urlString, paramString];
    } 
  }
  else 
  {
    data = [NSJSONSerialization dataWithJSONObject: params options:NSJSONReadingAllowFragments error: nil];
  }

  // and schedule the guy
#if DEBUG_NETWORK==1
  NSLog(@"Scheduling for request:\n%@", urlString);
#endif
  NSURL *url = [NSURL URLWithString: urlString];
  return [KCRequestQueue scheduleURL: url withData: data withMethod: method andCallback: callback];
}

@end
