//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let clear = NSColor.clear
    let unselectedRecordIcon = NSColor.gray

    // Records
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)

    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let noRelatedItemsColor = NSColor(calibratedRed: 33/255, green: 33/255, blue: 33/255, alpha: 1)

    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)

    // Window Sizes
    let recordWindowSize = CGSize(width: 416, height: 640)
    let imageWindowSize = CGSize(width: 640, height: 410)
    let pdfWindowSize = CGSize(width: 600, height: 640)
    let playerWindowSize = CGSize(width: 640, height: 440)

    let minMediaWindowWidth: CGFloat = 550.0
    let maxMediaWindowWidth: CGFloat = 700.0
}
