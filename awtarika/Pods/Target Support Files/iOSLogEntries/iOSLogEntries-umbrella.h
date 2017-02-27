#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "LEBackgroundThread.h"
#import "lecore.h"
#import "lelib.h"
#import "LELog.h"
#import "LeNetworkStatus.h"
#import "LogFile.h"
#import "LogFiles.h"

FOUNDATION_EXPORT double iOSLogEntriesVersionNumber;
FOUNDATION_EXPORT const unsigned char iOSLogEntriesVersionString[];

