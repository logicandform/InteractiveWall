//  Copyright © 2018 JABT. All rights reserved.

#import <Foundation/Foundation.h>

/// CFMessagePortCreateLocal requires a C function pointer for the
/// callback parameter.  These functions, implemented in Objective-C,
/// provide that callback function pointer and related context info
/// in a way that can be consumed by the Swift `TouchListener` class.

@class TouchListener;

/// Return the callback function to be passed to CFMessagePortCreateLocal()
extern CFMessagePortCallBack GetListenerCallback(void);

/// Return the value to be used as the `info` field in CFMessagePortContext
extern void *GetListenerCallbackInfo(TouchListener *listener);
