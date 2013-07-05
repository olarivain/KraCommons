//
//  Created by Kra on 12/31/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import "KCWebRequestOperation.h"

static dispatch_queue_t networkRequestCallbackQueue;

@interface KCWebRequestOperation ()
@property (nonatomic, readwrite) NSError *openTableError;
@end

@implementation KCWebRequestOperation

+ (NSSet *)acceptableContentTypes
{
	// text/html should NOT be there, be we have to add it, since our backend returns json
	// with an html content type. OL 1/12/2013
    return [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", @"text/html", nil];
}

- (id) initWithRequest:(NSURLRequest *)urlRequest {
	self = [super initWithRequest: urlRequest];
	if(self) {
		// create the nework callback queue - we don't our stores processing stuff on the main thread
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			networkRequestCallbackQueue = dispatch_queue_create("com.kra.networking.request.processing", DISPATCH_QUEUE_CONCURRENT);
		});
	}
	return self;
}

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    // get a weak reference to self to avoid a retain cycle
    __weak KCWebRequestOperation *weakSelf = self;
    
    self.completionBlock = ^ {
        
        // get a strong reference to self to keep it from disappearing
        // during the dispatch_async blocks below
        KCWebRequestOperation *blockSelf = weakSelf;
        
		// and dispatch on the shared network callback queue (super implementation would be succes/failure, but we're
		// fine shoving everything into one queue, as long as it's off main thread
		dispatch_async(networkRequestCallbackQueue, ^{
			// request is cancelled, get the hell out without doing shit.
			if ([blockSelf isCancelled]) {
				return;
			}
			
			// we have a hard error (i.e. physical network layer, bad content type or other)
			if (blockSelf.error) {
				// invoke the failure block right here, right now
				InvokeBlock(failure, blockSelf, blockSelf.error);
				return;
			}
		

			id JSON = blockSelf.responseJSON;
			
			// server replied 200OK BUT we have a business error in the JSON - invoke the error block
			if (blockSelf.openTableError) {
				InvokeBlock(failure, blockSelf, blockSelf.error);
				return ;
			}
			
			// everything went fine, invoke the success block right here
			InvokeBlock(success, blockSelf, JSON);
		});
    };
}


@end
