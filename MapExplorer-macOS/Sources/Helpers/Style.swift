//  Copyright © 2018 slant. All rights reserved.

import Foundation
import AppKit

let style = Style()

final class Style {

    // Map Annotation Markers
    let artifactColor = NSColor(calibratedRed: 41/255, green: 205/255, blue: 168/255, alpha: 1)
    let schoolInnerColor = NSColor(calibratedRed: 0, green: 201/255, blue: 255/255, alpha: 1)
    let schoolOuterColor = NSColor(calibratedRed: 0, green: 201/255, blue: 255/255, alpha: 0.66)
    let eventInnerColor = NSColor(calibratedRed: 108/255, green: 136/255, blue: 255/255, alpha: 1)
    let eventOuterColor = NSColor(calibratedRed: 108/255, green: 136/255, blue: 255/255, alpha: 0.66)
    let organizationColor = NSColor(calibratedRed: 193/255, green: 79/255, blue: 231/255, alpha: 1)
    let relatedItemColor = NSColor(calibratedRed: 75/255, green: 91/255, blue: 100/255, alpha: 1)
    let outerAnnotationColor = NSColor.white
}
