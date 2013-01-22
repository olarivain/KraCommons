//
// Prefix header for all source files of the 'Kracommons' target in the 'Kracommons' project
//


#ifdef __OBJC__

	#import <SystemConfiguration/SystemConfiguration.h>
	#if __IPHONE_OS_VERSION_MIN_REQUIRED
		#import <UIKit/UIKit.h>
		#import <MobileCoreServices/MobileCoreServices.h>
		#import "NSError+Alert.h"
		#import "UIDeviceSupport.h"
		#import "UITableView+NibRegistration.h"
		#import "KCAnimation.h"
		#import "KCNibUtils.h"
		#import "UIView+FirstResponder.h"
	#endif

	#import <CocoaLumberJack/DDLog.h>

	#import "KCBlocks.h"
	#import "NSDictionary+NullSafe.h"
	#import "NSArray+BoundSafe.h"
	#import "NSObject+PerformBlock.h"
	#import "NSError+Creation.h"
	#import "KCGlobalConfiguration.h"

	#import "NSString+Replacement.h"

	extern const int ddLogLevel;
	#ifdef RELEASE
		#define NSLog(...)

		#undef DDLogError
		#undef DDLogWarn
		#undef DDLogInfo
		#undef DDLogVerbose
		#undef DDLogCError
		#undef DDLogCWarn
		#undef DDLogCInfo
		#undef DDLogCVerbose

		#define DDLogError(frmt, ...)
		#define DDLogWarn(frmt, ...)
		#define DDLogInfo(frmt, ...)
		#define DDLogVerbose(frmt, ...)

		#define DDLogCError(frmt, ...)
		#define DDLogCWarn(frmt, ...)
		#define DDLogCInfo(frmt, ...)
		#define DDLogCVerbose(frmt, ...)
	#endif

#endif