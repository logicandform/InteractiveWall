//  Copyright © 2018 slant. All rights reserved.

import C4
import MONode
import UIKit

let frameGap = 229.0
let frameCanvasWidth = 997.0

let screenID: Int32 = {
    //        var screenName = UIDevice.current.name
    //        screenName = deviceName.replacingOccurrences(of: "MO", with: "")
    //        if let deviceID = Int32(deviceName) {
    //            return deviceID
    //        }
    //        return Int32(arc4random() & 0x0FFFFFFF)
    return Int32(1)
}()

open class UniverseController: CanvasController {
    open override func viewDidLoad() {
        canvas.bounds.origin.x = dx
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

    var physicalFrame: Rect {
        return Rect(dx-frameGap/2.0, 0, frameCanvasWidth, 1024)
    }

    var accesPoints: Int {
        return 5
    }

    var dx: Double {
//        return Double(self.deviceID-1) * frameCanvasWidth - frameGap/2.0
        return 0
    }
}
