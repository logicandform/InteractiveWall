//  Copyright © 2018 JABT. All rights reserved.

#import "ListenerCallback.h"
#import "NodeExplorer-Swift.h"


/// Calls listener.handleMessageWithID(,data:)
static CFDataRef ListenerCallback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
    TouchListener *listener = (__bridge TouchListener *)info;
    [listener handleTouchWithData:(__bridge NSData *) data];
    return NULL;
}

CFMessagePortCallBack GetListenerCallback() {
    return ListenerCallback;
}

void *GetListenerCallbackInfo(TouchListener *listener) {
    return (__bridge void *)listener;
}
