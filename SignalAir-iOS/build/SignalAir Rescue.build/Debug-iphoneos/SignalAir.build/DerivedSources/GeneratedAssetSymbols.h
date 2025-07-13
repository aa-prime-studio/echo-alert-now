#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"gmail.signalairrescue.app";

/// The "LaunchScreenBackground" asset catalog color resource.
static NSString * const ACColorNameLaunchScreenBackground AC_SWIFT_PRIVATE = @"LaunchScreenBackground";

/// The "loading" asset catalog image resource.
static NSString * const ACImageNameLoading AC_SWIFT_PRIVATE = @"loading";

#undef AC_SWIFT_PRIVATE
