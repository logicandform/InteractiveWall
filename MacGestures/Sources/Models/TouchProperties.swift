//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import CoreGraphics


/// A data structure to hold information about a set of touches.
public struct TouchProperties {

    // Current number of active fingers
    let touchCount: Int

    // Center of gravity of all the active touches
    let cog: CGPoint

    // Angle of all the active touches
    let angle: CGFloat

    // Total distance between all touches
    let spread: CGFloat
}
