//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    // Generic
    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let unselectedRecordIcon = NSColor.gray
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)

    // Records
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)
    let imageFilterTypeColor = NSColor.red

    // Nodes
    let nodePhysicsBodyRadius: CGFloat = 15
    let nodePhysicsBodyMass: CGFloat = 0.25
    let nodeAgentMaxSpeed: Float = 200
    let nodeAgentMaxAcceleration: Float = 100
    let nodeAgentRadius = Float(15)

    let selectedNodeRadius: CGFloat = 45
    let levelZeroNodeRadius: CGFloat = 40
    let levelOneNodeRadius: CGFloat = 30
    let levelTwoNodeRadius: CGFloat = 25
    let levelThreeNodeRadius: CGFloat = 20
    let levelFourNodeRadius: CGFloat = 15
    let levelFiveNodeRadius: CGFloat = 10

    // TODO: will need to get the assets from Nic
    let selectedNodeSize = CGSize(width: 45, height: 45)
    let levelZeroNodeSize = CGSize(width: 40, height: 40)
    let levelOneNodeSize = CGSize(width: 30, height: 30)
    let levelTwoNodeSize = CGSize(width: 25, height: 25)
    let levelThreeNodeSize = CGSize(width: 20, height: 20)
    let levelFourNodeSize = CGSize(width: 15, height: 15)
    let levelFiveNodeSize = CGSize(width: 10, height: 10)

    // Titles
    var windowTitleAttributes: [NSAttributedStringKey: Any] {
        let font = NSFont(name: "Soleil", size: 16) ?? NSFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail

        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 1.5]
    }
}
