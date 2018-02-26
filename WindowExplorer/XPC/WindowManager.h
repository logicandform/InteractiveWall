//  Copyright © 2018 JABT. All rights reserved.

#import <Foundation/Foundation.h>
#import "WindowManagerDelegate.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface WindowManager : NSObject <WindowManagerDelegate>
@end
