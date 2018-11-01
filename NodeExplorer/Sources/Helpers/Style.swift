//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class Style {


    // MARK: Generic Properties

    let darkBackgroundOpaque = NSColor(srgbRed: 17/255, green: 17/255, blue: 17/255, alpha: 1)


    // MARK: Record Type Colors

    let artifactColor = NSColor(srgbRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(srgbRed: 7/255, green: 61/255, blue: 224/255, alpha: 1)
    let eventColor = NSColor(srgbRed: 228/255, green: 54/255, blue: 188/255, alpha: 1)
    let organizationColor = NSColor(srgbRed: 0/255, green: 159/255, blue: 75/255, alpha: 1)
    let collectionColor = NSColor(srgbRed: 229/255, green: 121/255, blue: 0/255, alpha: 1)
    let individualColor = NSColor(srgbRed: 205/255, green: 33/255, blue: 54/255, alpha: 1)
    let themeColor = NSColor(srgbRed: 0/255, green: 154/255, blue: 254/255, alpha: 1)


    // MARK: Window Levels

    let nodeWindowLevel = NSWindow.Level(27)


    // MARK: Node Properties

    let nodePhysicsBodyMass: CGFloat = 0.25
    let defaultNodeSize = CGSize(width: 100, height: 100)
    let selectedNodeSize = CGSize(width: 300, height: 300)
    let driftingNodeSize = CGSize(width: 140, height: 140)
    let levelZeroNodeSize = CGSize(width: 100, height: 100)
    let levelOneNodeSize = CGSize(width: 66, height: 66)
    let levelTwoNodeSize = CGSize(width: 50, height: 50)
    let levelThreeNodeSize = CGSize(width: 32, height: 32)
    let levelFourNodeSize = CGSize(width: 20, height: 20)


    // MARK: Drifting Theme Properties

    let themeDxRange = ClosedRange<CGFloat>(uncheckedBounds: (40, 120))


    // MARK: Animations Properties

    let fadeAnimationDuration = 1.0
    let moveAnimationDuration = 1.2
    let scaleAnimationDuration = 1.2
}
