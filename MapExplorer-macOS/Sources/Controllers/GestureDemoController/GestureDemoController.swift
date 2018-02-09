//  Copyright © 2017 JABT. All rights reserved.

import MONode

class GestureDemoController: NSViewController, SocketManagerDelegate, TouchResponder {
    static let config = NetworkConfiguration(broadcastHost: "192.168.1.255", nodePort: 12211)

    let socketManager = SocketManager(networkConfiguration: config)
    var touchHandler: TouchHandler!
    var rect: GestureView!

    override func viewDidLoad() {
        super.viewDidLoad()

        socketManager.delegate = self
        touchHandler = TouchHandler(responder: self)

        rect = GestureView(frame: CGRect(x: 300, y: 300, width: 400, height: 400))
        rect.wantsLayer = true
        rect.layer?.backgroundColor = NSColor.blue.cgColor
        view.addSubview(rect)

        let tapGesture = TapGestureRecognizer()
        rect.add(tapGesture)
        tapGesture.gestureUpdated = rectTapped(_:)

        let panGesture = PanGestureRecognizer()
        rect.add(panGesture)
        panGesture.gestureUpdated = rectPanned(_:)

        let pinchGesture = PinchGestureRecognizer()
        rect.add(pinchGesture)
        pinchGesture.gestureUpdated = rectPinched(_:)
    }


    // MARK: TouchResponder

    /// Returns the GestureView located at the point
    func view(for point: CGPoint) -> GestureView? {
        let gestureViews = view.subviews.flatMap { $0 as? GestureView }

        for subview in gestureViews.reversed() {
            if let target = subview.view(for: point) {
                return target
            }
        }

        return nil
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print("Socket error: \(message)")
    }

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        touchHandler.handle(touch)
    }

    // MARK: GestureHandlerDelegate

    func rectTapped(_ gesture: GestureRecognizer) {
        rect.frame.size.width *= 1.1
        rect.frame.size.height *= 1.1
    }

    func rectPanned(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }
        print(pan.delta)
        rect.frame.origin += pan.delta
    }

    func rectPinched(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        rect.frame.size *= pinch.scale
    }
}
