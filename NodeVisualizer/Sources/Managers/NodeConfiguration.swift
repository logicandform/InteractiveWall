//  Copyright © 2018 JABT. All rights reserved.

import Foundation


class NodeConfiguration {

    struct Record {
        static let physicsBodyRadius: CGFloat = 15
        static let physicsBodyMass: CGFloat = 0.25
        static let agentMaxSpeed: Float = 200
        static let agentMaxAcceleration: Float = 100
        static let agentRadius = Float(physicsBodyRadius)
    }
}
