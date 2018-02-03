// Copyright © 2017 JABT Labs Inc. All rights reserved.

import C4
import MONode
import UIKit

let frameGap = 229.0
let frameCanvasWidth = 997.0

open class UniverseController: CanvasController {
    open override func viewDidLoad() {
        canvas.backgroundColor = clear
        super.viewDidLoad()
    }

    open lazy var deviceID: Int32 = {
        var deviceName = UIDevice.current.name
        deviceName = deviceName.replacingOccurrences(of: "MO", with: "")
        if let deviceID = Int32(deviceName) {
            return deviceID
        }
        return Int32(arc4random() & 0x0FFFFFFF)
    }()

    var dx: Double {
        return Double(self.deviceID-1) * frameCanvasWidth - frameGap/2.0
    }
}
