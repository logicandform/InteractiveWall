//  Copyright © 2018 JABT. All rights reserved.

import Foundation

/// Implementation of a listener that uses a message port
///
/// This class is derived from NSObject so that the Objective-C-based callback function can use it.
class TouchListener: NSObject {

    var receivedTouch: ((Touch) -> Void)?


    /// Create the local message port then register an input source for it
    func listenToPort(named name: String) {
        if let messagePort = createMessagePort(name: name) {
            addSource(messagePort: messagePort, toRunLoop: RunLoop.current)
        }
    }

    /// Create a local message port with the specified name
    ///
    /// Incoming messages will be routed to this object's handleMessageWithID(,data:) method.
    private func createMessagePort(name: String) -> CFMessagePort? {
        let callback = GetListenerCallback()
        var context = CFMessagePortContext(
            version: 0,
            info: GetListenerCallbackInfo(self),
            retain: nil,
            release: nil,
            copyDescription: nil)
        var shouldFreeInfo: DarwinBoolean = false

        return CFMessagePortCreateLocal(
            nil,
            name as CFString,
            callback,
            &context,
            &shouldFreeInfo)
    }

    /// Create an input source for the specified message port and add it to the specified run loop
    private func addSource(messagePort: CFMessagePort, toRunLoop runLoop: RunLoop) {
        let source = CFMessagePortCreateRunLoopSource(nil, messagePort, 0)
        CFRunLoopAddSource(runLoop.getCFRunLoop(), source, CFRunLoopMode.commonModes)
    }

    /// Called by the message port callback function
    @objc
    func handleTouch(data: Data) {
        if let touch = Touch(data: data) {
            receivedTouch?(touch)
        } else {
            print("FAILED")
        }
    }
}
