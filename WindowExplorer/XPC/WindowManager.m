//  Copyright © 2018 JABT. All rights reserved.

#import "WindowManager.h"

@implementation WindowManager

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)displayString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
