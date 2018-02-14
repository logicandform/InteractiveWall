//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode


enum TouchState {
    case down
    case up
    case moved

    init?(from type: PacketType) {
        switch type {
        case .touchDown:
            self = .down
        case .touchUp:
            self = .up
        case .touchMove:
            self = .moved
        default:
            return nil
        }
    }
}


class Touch: Hashable, CustomStringConvertible {

    var position: CGPoint
    var state: TouchState
    let id: Int

    var hashValue: Int {
        return id
    }

    var description: String {
        return "( [Touch] ID: \(id), Position: \(position), State: \(state) )"
    }

    private struct Constants {
        static let planarScreenRatio: CGFloat = 23.0 / 42.0
    }


    // MARK: Initializers

    init(position: CGPoint, state: TouchState, id: Int) {
        self.position = position
        self.state = state
        self.id = id
    }

    init?(from packet: Packet) {
        guard let payload = packet.payload, let touchState = TouchState(from: packet.packetType) else {
            return nil
        }

        var index = 0
        let screen = payload.extract(Int32.self, at: index)

        // Ensure that the packet is intended for this device
        guard screen == deviceID else {
            return nil
        }

        index += MemoryLayout<Int32>.size
        self.id = Int(payload.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let xPos = payload.extract(Int32.self, at: index)
        index += MemoryLayout<Int32>.size
        let yPos = payload.extract(Int32.self, at: index)
        self.position = CGPoint(x: CGFloat(xPos), y: CGFloat(yPos) * Constants.planarScreenRatio)
        self.state = touchState
    }


    // MARK: API

    // Updates the values of `self` if the touches are equal
    func update(with touch: Touch) {
        if self == touch {
            self.position = touch.position
            self.state = touch.state
        }
    }

    func copy() -> Touch {
        return Touch(position: position, state: state, id: id)
    }

    static func == (lhs: Touch, rhs: Touch) -> Bool {
        return lhs.id == rhs.id
    }
}
