//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 100
        static let minimumFingers = 1
    }

    var state = NSGestureRecognizer.State.possible
    var delta = CGVector.zero
    var lastPosition: CGPoint?
    var secondLastPosition: CGPoint?
    var thirdLastPosition: CGPoint?
    var fingers: Int

    //var momentumTimer = Timer!

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        if state == .began {
            state = .failed
        } else if state == .possible && properties.touchCount == fingers {
            state = .began
            lastPosition = properties.cog
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPosition = lastPosition else {
            return
        }

      //  momentumTimer = Timer.scheduledTimer(timeInterval: 1 / 60, target: self, selector: #selector(updatePan), userInfo: nil, repeats: true)
        switch state {
        case .began where abs(properties.cog.x - lastPosition.x) + abs(properties.cog.y - lastPosition.y) > Constants.recognizedThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            thirdLastPosition = secondLastPosition
            secondLastPosition = lastPosition
            self.lastPosition = properties.cog
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if properties.touchCount.isZero {
            state = .recognized
            guard let thirdLastPosition = thirdLastPosition, let lastPosition = lastPosition else {
                return
            }

            var difInPos = CGPoint(x: lastPosition.x - thirdLastPosition.x, y: lastPosition.y - thirdLastPosition.y)
            var factor: Double = 1

            print("Size: ", difInPos.magnitude())

            var count = 0 {
                didSet {
                    print(count)
                }
            }




            DispatchQueue.global(qos: .utility).async{
                while(difInPos.magnitude() > 5) {

                    factor += 0.01
                    difInPos /= factor
                    self.delta = CGVector(dx: difInPos.x, dy: difInPos.y)
                    DispatchQueue.main.async {
                        self.gestureUpdated?(self)
                        count += 1
                    }
                }
            }
            state = .possible
        } else {
            state = .failed
        }
        gestureUpdated?(self)
    }

    func reset() {
        state = .possible
        lastPosition = nil
        delta = .zero
    }

    func invalidate() {
        state = .failed
    }
}
