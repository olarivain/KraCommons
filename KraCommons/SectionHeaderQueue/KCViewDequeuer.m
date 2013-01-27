//
//  KCSectionHeaderQueue.m
//  KraCommons
//
//  Created by Olivier Larivain on 1/26/13.
//  Copyright (c) 2013 kra. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED

#import "KCViewDequeuer.h"

@interface KCViewDequeuer ()

@property (weak, nonatomic) IBOutlet UIView *view;

@property (strong, nonatomic) NSMutableDictionary *nibNames;
@property (strong, nonatomic) NSMutableDictionary *allSections;

@end

@implementation KCViewDequeuer

#pragma mark - Lifecycle
- (id) init {
	self = [super init];
	if(self) {
		self.nibNames = [NSMutableDictionary dictionaryWithCapacity: 5];
		self.allSections = [NSMutableDictionary dictionaryWithCapacity: 10];
	}
	return self;
}

- (void) dealloc {
	for(NSMutableArray *views in [self.allSections allValues]) {
		for(UIView *view in views) {
			[view removeObserver: self
					  forKeyPath: @"superview"];
		}
	}
}

#pragma mark - Nib Registration
- (void) registerNibName: (NSString *) nibName forReuseIdentifier: (NSString *) reuseId {
	NSAssert(reuseId.length > 0, @"Reuse ID can't be empty");
	NSAssert(nibName.length > 0, @"NibName can't be empty");
	
	UINib *nib = [UINib nibWithNibName: nibName
								bundle: nil];
	[self.nibNames setObjectNilSafe: nib
							 forKey: reuseId];
}

#pragma mark - View dequeuing
- (UIView *) dequeueReusableViewWithIdentifier: (NSString *) reuseId {
	UIView *dequeued = [self availableHeaderWithReuseIdentifier: reuseId];
	if(dequeued != nil) {
		return dequeued;
	}
	
	// get the nib and ensure we have one
	UINib *nib = [self.nibNames objectForKey: reuseId];
	if(nib == nil) {
		@throw [NSException exceptionWithName: @"NSInfernalConsistency"
									   reason: [NSString stringWithFormat: @"No nib registered for reuseID %@", reuseId]
									 userInfo: nil];
	}
	
	// instantiate the view
	[nib instantiateWithOwner: self
					  options: nil];
	dequeued = self.view;
	self.view = nil;
	
	// add the view to the view list, creating the backing array if needed
	NSMutableArray *viewList = [self.allSections objectForKey: reuseId];
	if(viewList == nil) {
		viewList = [NSMutableArray arrayWithCapacity: 10];
		[self.allSections setObject: viewList forKey: reuseId];
	}
	[viewList addObject: dequeued];
	
	// we'll want to listen to changes to superview, so we can call "-prepareForReuse" if needed
	[dequeued addObserver: self
			   forKeyPath: @"superview"
				  options: 0
				  context: nil];
	
	return dequeued;
}

- (UIView *) availableHeaderWithReuseIdentifier: (NSString *) reuseId {
	NSMutableArray *availableViews = [self.allSections objectForKey: reuseId];
	NSInteger index = [availableViews indexOfObjectPassingTest:^BOOL(UIView *obj, NSUInteger idx, BOOL *stop) {
		return obj.superview == nil;
	}];
	return [availableViews boundSafeObjectAtIndex: index];
}

#pragma mark - KVC observing
- (void) observeValueForKeyPath:(NSString *)keyPath
					   ofObject:(id)object
						 change:(NSDictionary *)change
						context:(void *)context {
	if([object respondsToSelector: @selector(prepareForReuse)]) {
		[object performSelector: @selector(prepareForReuse)];
	}
}

@end

#endif