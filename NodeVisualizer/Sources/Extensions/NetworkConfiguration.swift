//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MONode

public extension NetworkConfiguration {

    public init(broadcast: String) {
        self.init()
        self.broadcastHost = broadcast
    }

    public init(broadcastHost: String, nodePort: UInt16) {
        self.init()
        self.broadcastHost = broadcastHost
        self.nodePort = nodePort
    }
}
