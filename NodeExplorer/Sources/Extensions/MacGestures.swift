//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode
import MacGestures


extension Touch {

    convenience init?(from packet: Packet) {
        guard let payload = packet.payload, let touchState = TouchState(from: packet.packetType) else {
            return nil
        }

        var index = 0
        let screen = Int(payload.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let id = Int(payload.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let xPos = payload.extract(Int32.self, at: index)
        index += MemoryLayout<Int32>.size
        let yPos = payload.extract(Int32.self, at: index)
        let position = CGPoint(x: CGFloat(xPos), y: CGFloat(yPos))
        let state = touchState
        self.init(position: position, state: state, id: id, screen: screen)
    }

    convenience init?(data: Data) {
        var index = 0
        let packetSize = data.extract(UInt32.self, at: index)
        if data.count < Int(packetSize) {
            return nil
        }
        index += MemoryLayout.size(ofValue: packetSize)
        let id = Int(data.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let screen = Int(data.extract(Int32.self, at: index))
        index += MemoryLayout<Int32>.size
        let stateRawValue = Int(data.extract(Int8.self, at: index))
        guard let touchState = TouchState(rawValue: stateRawValue) else {
            return nil
        }
        index += MemoryLayout<Int8>.size
        let x = data.extract(CGFloat.self, at: index)
        index += MemoryLayout<CGFloat>.size
        let y = data.extract(CGFloat.self, at: index)
        let position = CGPoint(x: x, y: y)
        self.init(position: position, state: touchState, id: id, screen: screen)
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
        return packetData
    }
}


extension TouchState {

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
