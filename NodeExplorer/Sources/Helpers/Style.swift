//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class Style {

    // Generic
    let darkBackgroundOpaque = NSColor(srgbRed: 17/255, green: 17/255, blue: 17/255, alpha: 1)

    // Records
    let artifactColor = NSColor(srgbRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(srgbRed: 7/255, green: 61/255, blue: 224/255, alpha: 1)
    let eventColor = NSColor(srgbRed: 228/255, green: 54/255, blue: 188/255, alpha: 1)
    let organizationColor = NSColor(srgbRed: 0/255, green: 159/255, blue: 75/255, alpha: 1)
    let collectionColor = NSColor(srgbRed: 229/255, green: 121/255, blue: 0/255, alpha: 1)
    let individualColor = NSColor(srgbRed: 205/255, green: 33/255, blue: 54/255, alpha: 1)
    let themeColor = NSColor(srgbRed: 0/255, green: 154/255, blue: 254/255, alpha: 1)

    // Windows
    let nodeWindowLevel = NSWindow.Level(27)

    // Nodes
    let nodePhysicsBodyMass: CGFloat = 0.25
    let defaultNodePhysicsBodyRadius: CGFloat = 50
    let defaultNodeSize = CGSize(width: 100, height: 100)

    static let selectedNodeRadius: CGFloat = 150
    static let levelZeroNodeRadius: CGFloat = 50
    static let levelOneNodeRadius: CGFloat = 33
    static let levelTwoNodeRadius: CGFloat = 25
    static let levelThreeNodeRadius: CGFloat = 16
    static let levelFourNodeRadius: CGFloat = 10

    let selectedNodeSize = CGSize(width: selectedNodeRadius * 2, height: selectedNodeRadius * 2)
    let levelZeroNodeSize = CGSize(width: levelZeroNodeRadius * 2, height: levelZeroNodeRadius * 2)
    let levelOneNodeSize = CGSize(width: levelOneNodeRadius * 2, height: levelOneNodeRadius * 2)
    let levelTwoNodeSize = CGSize(width: levelTwoNodeRadius * 2, height: levelTwoNodeRadius * 2)
    let levelThreeNodeSize = CGSize(width: levelThreeNodeRadius * 2, height: levelThreeNodeRadius * 2)
    let levelFourNodeSize = CGSize(width: levelFourNodeRadius * 2, height: levelFourNodeRadius * 2)


    // MARK: Drifting Theme Properties

    let themeDxRange = ClosedRange<CGFloat>(uncheckedBounds: (20, 100))
    let themeDyRange = ClosedRange<CGFloat>(uncheckedBounds: (-20, 20))

    // Animations
    let fadeAnimationDuration = 1.0
    let moveAnimationDuration = 1.2
    let scaleAnimationDuration = 1.2

    // Titles
    var windowTitleAttributes: [NSAttributedString.Key: Any] {
        let font = NSFont(name: "Soleil", size: 16) ?? NSFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1.5]
    }
}
