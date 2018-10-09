//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MONode

extension PacketType {

    // MapHandling
    static let zoomAndCenter = PacketType(rawValue: 123400)
    static let disconnection = PacketType(rawValue: 123401)
    static let reset = PacketType(rawValue: 123402)

    // TouchHandling
    static let touchDown = PacketType(rawValue: 1000)
    static let touchUp = PacketType(rawValue: 1001)
    static let touchMove = PacketType(rawValue: 1002)
}

extension Packet {

    func hasPrecedence(deviceID: Int32, pairedID: Int32) -> Bool {
        return abs(id - deviceID) < abs(pairedID - deviceID)
    }
}
