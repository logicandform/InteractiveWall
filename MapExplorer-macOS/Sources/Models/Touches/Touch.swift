//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode


class Touch: Hashable, CustomStringConvertible {

    var position: CGPoint
    var state: TouchState
    var time: CGFloat
    let screen: Int
    let id: Int

    var positionsAndTimes = [PositionAndTime]()

    var velocity: CGVector? {
        guard positionsAndTimes.count == 3, let last = positionsAndTimes.last, let secondLast = positionsAndTimes.first else {
            return nil
        }
        return ((last.position - secondLast.position) / (last.time - secondLast.time)).asVector * CGFloat(Configuration.refreshRate)
    }

    var hashValue: Int {
        return id ^ screen
    }

    var description: String {
        return "( [Touch] ID: \(id), Position: \(position), State: \(state), Time: \(time) )"
    }


    // MARK: Initializers

    init(position: CGPoint, state: TouchState, id: Int, screen: Int, time: CGFloat) {
        self.position = position
        self.state = state
        self.screen = screen
        self.id = id
        self.time = time
    }

    init?(from packet: Packet) {
        guard let payload = packet.payload, let touchState = TouchState(from: packet.packetType) else {
            return nil
        }

        var index = 0
        self.screen = Int(payload.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        self.id = Int(payload.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let xPos = payload.extract(Int32.self, at: index)
        index += MemoryLayout<Int32>.size
        let yPos = payload.extract(Int32.self, at: index)
        index += MemoryLayout<Int32>.size
        self.time = CGFloat(payload.extract(Float32.self, at: index))
        self.position = CGPoint(x: CGFloat(xPos), y: CGFloat(yPos))
        self.state = touchState
    }

    init?(data: Data) {
        var index = 0
        let packetSize = data.extract(UInt32.self, at: index)
        if data.count < Int(packetSize) {
            return nil
        }
        index += MemoryLayout.size(ofValue: packetSize)
        self.id = Int(data.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        self.screen = Int(data.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let stateRawValue = Int(data.extract(Int8.self, at: index))
        guard let touchState = TouchState(rawValue: stateRawValue) else {
            return nil
        }
        self.state = touchState
        index += MemoryLayout<Int8>.size
        let x = data.extract(CGFloat.self, at: index)
        index += MemoryLayout<CGFloat>.size
        let y = data.extract(CGFloat.self, at: index)
        index += MemoryLayout<CGFloat>.size
        self.time = CGFloat(data.extract(Float32.self, at: index))
        position = CGPoint(x: x, y: y)
    }


    // MARK: API

    // Updates the values of `self` if the touches are equal
    func update(with touch: Touch) {
        if self == touch {
            self.position = touch.position
            self.state = touch.state
            self.time = touch.time

            if positionsAndTimes.count == 3 {
                positionsAndTimes.removeFirst()
            }

            positionsAndTimes.append(PositionAndTime(position: self.position, time: self.time))
        }
    }

    func copy() -> Touch {
        return Touch(position: position, state: state, id: id, screen: screen, time: time)
    }

    func toData() -> Data {
        let basePacketSize = MemoryLayout<UInt32>.size * 3 + MemoryLayout<UInt8>.size + MemoryLayout<CGFloat>.size * 2
        let packetSize = UInt32(basePacketSize)
        var packetData = Data(capacity: Int(packetSize))

        packetData.append(packetSize)
        packetData.append(Int32(id))
        packetData.append(Int32(screen))
        packetData.append(Int8(state.rawValue))
        packetData.append(position.x)
        packetData.append(position.y)
        packetData.append(time)
        return packetData
    }

    static func == (lhs: Touch, rhs: Touch) -> Bool {
        return lhs.id == rhs.id && lhs.screen == rhs.screen
    }
}

struct PositionAndTime: Hashable {
    var hashValue: Int {
        return position.x.hashValue + position.y.hashValue + Int(time)
    }

    var position: CGPoint
    var time: CGFloat
}
