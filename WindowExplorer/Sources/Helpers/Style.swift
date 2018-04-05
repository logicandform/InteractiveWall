//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    let darkBackground = NSColor.black.withAlphaComponent(0.9)
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let clear = NSColor.clear

    // Records
    let artifactColor = NSColor(calibratedRed: 41/255, green: 205/255, blue: 168/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 0, green: 201/255, blue: 255/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 108/255, green: 136/255, blue: 255/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 193/255, green: 79/255, blue: 231/255, alpha: 1)

    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let noRelatedItemsColor = NSColor(calibratedRed: 33/255, green: 33/255, blue: 33/255, alpha: 1)

    let dragAreaBackground = NSColor.lightGray.withAlphaComponent(0.33)
}
