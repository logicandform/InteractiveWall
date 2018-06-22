//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct NodeConfiguration {

    struct Record {
        static let physicsBodyRadius: CGFloat = 15.0
        static let physicsBodyMass: CGFloat = 0.2

        static let agentMaxSpeed: Float = 200.0
        static let agentMaxAcceleration: Float = 100.0
        static let agentRadius = Float(physicsBodyRadius)
    }
}
