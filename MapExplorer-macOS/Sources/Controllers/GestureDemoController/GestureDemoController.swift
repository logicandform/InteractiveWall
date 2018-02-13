//  Copyright © 2017 JABT. All rights reserved.

import MONode

class GestureDemoController: NSViewController, SocketManagerDelegate, GestureResponder {
    static let config = NetworkConfiguration(broadcastHost: "10.0.0.255", nodePort: 12222)

    let socketManager = SocketManager(networkConfiguration: config)
    var gestureManager: GestureManager!
    var rect: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()

        socketManager.delegate = self
        gestureManager = GestureManager(responder: self)

        rect = NSView(frame: CGRect(x: 300, y: 300, width: 400, height: 400))
        rect.wantsLayer = true
        rect.layer?.backgroundColor = NSColor.blue.cgColor
        view.addSubview(rect)

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: rect)
        tapGesture.gestureUpdated = rectTapped(_:)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: rect)
        panGesture.gestureUpdated = rectPanned(_:)

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: rect)
        pinchGesture.gestureUpdated = rectPinched(_:)
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print("Socket error: \(message)")
    }

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        gestureManager.handle(touch)
    }


    // MARK: Gesture handling

    func rectTapped(_ gesture: GestureRecognizer) {
        rect.frame.size.width *= 1.1
        rect.frame.size.height *= 1.1
    }

    func rectPanned(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        rect.frame.origin += pan.delta
    }

    func rectPinched(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        rect.frame.size *= pinch.scale
    }
}
