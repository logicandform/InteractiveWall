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

//        let tapGesture = TapGestureRecognizer()
//        gestureManager.add(tapGesture, to: rect)
//        tapGesture.gestureUpdated = rectTapped(_:)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: rect)
        panGesture.gestureUpdated = rectPanned(_:)

        let twoFingerPan = PanGestureRecognizer(withFingers: 2)
        gestureManager.add(twoFingerPan, to: rect)
        twoFingerPan.gestureUpdated = rectPanned(_:)

        let threeFingerPan = PanGestureRecognizer(withFingers: 3)
        gestureManager.add(threeFingerPan, to: rect)
        threeFingerPan.gestureUpdated = rectPanned(_:)

        let fourFingerPan = PanGestureRecognizer(withFingers: 4)
        gestureManager.add(fourFingerPan, to: rect)
        fourFingerPan.gestureUpdated = rectPanned(_:)

        let fiveFingerPan = PanGestureRecognizer(withFingers: 5)
        gestureManager.add(fiveFingerPan, to: rect)
        fiveFingerPan.gestureUpdated = rectPanned(_:)
//
//        let pinchGesture = PinchGestureRecognizer()
//        gestureManager.add(pinchGesture, to: rect)
//        pinchGesture.gestureUpdated = rectPinched(_:)
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

    var hitTop = false
    var hitBottom = false
    var hitLeft = false
    var hitRight = false

    func rectPanned(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            let newFrameOriginX = min(view.frame.origin.x + view.frame.width - rect.frame.width, max(view.frame.origin.x, rect.frame.origin.x + pan.delta.dx))
            let newFrameOriginY = min(view.frame.origin.y + view.frame.height - rect.frame.height, max(view.frame.origin.y, rect.frame.origin.y + pan.delta.dy))
            rect.frame.origin = CGPoint(x: newFrameOriginX, y: newFrameOriginY)

            displayTouchIndicator(at: pan.centerOfGravity)
        default:
            return
        }

//        switch pan.state {
//        case .recognized:
//            let newFrameOriginX = min(view.frame.origin.x + view.frame.width - rect.frame.width, max(view.frame.origin.x, rect.frame.origin.x + pan.delta.dx))
//            let newFrameOriginY = min(view.frame.origin.y + view.frame.height - rect.frame.height, max(view.frame.origin.y, rect.frame.origin.y + pan.delta.dy))
//            rect.frame.origin = CGPoint(x: newFrameOriginX, y: newFrameOriginY)
//
//            displayTouchIndicator(at: pan.centerOfGravity)
//        case .momentum:
//            var delta = pan.delta
//
//            if hitTop || hitBottom {
//                delta.dy = -delta.dy
//            }
//
//            if hitLeft || hitRight {
//                delta.dx = -delta.dx
//            }
//
//            if view.frame.origin.y + view.frame.height - rect.frame.height <= rect.frame.origin.y + delta.dy {
//                if !hitBottom {
//                    hitTop = true
//                }
//                delta.dy = -delta.dy
//                hitBottom = false
//            } else if view.frame.origin.y >= rect.frame.origin.y + pan.delta.dy {
//                if !hitTop {
//                    hitBottom = true
//                }
//                delta.dy = -delta.dy
//                hitTop = false
//            }
//
//            if view.frame.origin.x + view.frame.width - rect.frame.width <= rect.frame.origin.x + delta.dx {
//                if !hitLeft {
//                    hitRight = true
//                }
//                delta.dx = -delta.dx
//                hitLeft = false
//            } else if view.frame.origin.x >= rect.frame.origin.x + pan.delta.dx {
//                if !hitRight {
//                    hitLeft = true
//                }
//                delta.dx = -delta.dx
//                hitRight = false
//            }
//
//            let newFrameOriginX = rect.frame.origin.x + delta.dx
//            let newFrameOriginY = rect.frame.origin.y + delta.dy
//            rect.frame.origin = CGPoint(x: newFrameOriginX, y: newFrameOriginY)
//
//        default:
//            return
//        }
    }

    func rectPinched(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        rect.frame.size *= pinch.scale
    }


    private func displayTouchIndicator(at position: CGPoint) {
        let radius: CGFloat = 20
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let touchIndicator = NSView(frame: frame)
        touchIndicator.wantsLayer = true
        touchIndicator.layer?.cornerRadius = radius
        touchIndicator.layer?.masksToBounds = true
        touchIndicator.layer?.borderWidth = radius / 4
        touchIndicator.layer?.borderColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        view.addSubview(touchIndicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1
            touchIndicator.animator().alphaValue = 0.0
        })
    }
}
