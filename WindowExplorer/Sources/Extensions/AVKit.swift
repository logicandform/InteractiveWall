//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AVKit

extension CMTime {

    var hoursMinutesSeconds: (hours: Int, minutes: Int, seconds: Int) {
        let totalSeconds = Int(seconds)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = (totalSeconds % 3600) % 60
        return (h, m, s)
    }
}
