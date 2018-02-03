// Copyright © 2017 JABT Labs Inc. All rights reserved.

import C4

public struct RemoteInteraction {
    /// The interaction point in universe coordinates
    public var point: CGPoint

    /// The ID of the source device
    public var deviceID: Int

    /// The timestamp, from the local clock
    public var timestamp: TimeInterval
}
