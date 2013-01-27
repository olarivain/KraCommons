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
@property (strong, nonatomic) NSMutableDictionary *availableViews;

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
		// tell the view it's about to be reused
		if([dequeued respondsToSelector: @selector(prepareForReuse)]) {
			[dequeued performSelector: @selector(prepareForReuse)];
		}
		return dequeued;
	}
	
	dequeued = [self loadViewWithIdentifier: reuseId];
	
	// add the view to the view list, creating the backing array if needed
	NSMutableArray *viewList = [self.allSections objectForKey: reuseId];
	if(viewList == nil) {
		viewList = [NSMutableArray arrayWithCapacity: 10];
		[self.allSections setObject: viewList forKey: reuseId];
	}
	[viewList addObject: dequeued];
	
	return dequeued;
}

- (UIView *) loadViewWithIdentifier: (NSString *) reuseIdentifier {
	// get the nib and ensure we have one
	UINib *nib = [self.nibNames objectForKey: reuseIdentifier];
	if(nib == nil) {
		@throw [NSException exceptionWithName: @"NSInfernalConsistency"
									   reason: [NSString stringWithFormat: @"No nib registered for reuseID %@", reuseIdentifier]
									 userInfo: nil];
	}
	
	// instantiate the view
	[nib instantiateWithOwner: self
					  options: nil];
	UIView *created = self.view;
	self.view = nil;
	
	return created;
}

- (UIView *) availableHeaderWithReuseIdentifier: (NSString *) reuseId {
	NSMutableArray *availableViews = [self.allSections objectForKey: reuseId];
	NSInteger index = [availableViews indexOfObjectPassingTest:^BOOL(UIView *obj, NSUInteger idx, BOOL *stop) {
		return obj.superview == nil;
	}];
	return [availableViews boundSafeObjectAtIndex: index];
}

@end

#endif