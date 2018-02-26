//  Copyright © 2018 JABT. All rights reserved.

#import "MapExplorer_XPC.h"

@implementation MapExplorer_XPC

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
