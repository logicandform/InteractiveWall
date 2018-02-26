//  Copyright © 2018 JABT. All rights reserved.

#import <Foundation/Foundation.h>
#import "MapExplorer_XPCProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface MapExplorer_XPC : NSObject <MapExplorer_XPCProtocol>
@end
