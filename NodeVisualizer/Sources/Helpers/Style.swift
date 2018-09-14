//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

final class Style {

    // MARK: Generic
    let darkBackground = NSColor.black.withAlphaComponent(0.85)
    let selectedColor = NSColor(calibratedRed: 0, green: 200/255, blue: 1, alpha: 1)
    let unselectedRecordIcon = NSColor.gray
    let dragAreaBackground = NSColor.black.withAlphaComponent(0.85)


    // MARK: Records
    let artifactColor = NSColor(calibratedRed: 128/255, green: 1/255, blue: 206/255, alpha: 1)
    let schoolColor = NSColor(calibratedRed: 78/255, green: 106/255, blue: 200/255, alpha: 1)
    let eventColor = NSColor(calibratedRed: 145/255, green: 18/255, blue: 88/255, alpha: 1)
    let organizationColor = NSColor(calibratedRed: 16/255, green: 147/255, blue: 79/255, alpha: 1)
    let imageFilterTypeColor = NSColor.red


    // MARK: Node Sizes
    let defaultBodyRadius: CGFloat = 50
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


    // MARK: Movement Multipliers
    let forceMultiplier: CGFloat = 40
    let forceDivisor: CGFloat = 1000
    let panningForceMultiplier: CGFloat = 30


    // MARK: Default Properties
    let defaultBodyMass: CGFloat = 5
    let defaultBodyRestitution: CGFloat = 0
    let defaultBodyFriction: CGFloat = 1
    let defaultLinearDamping: CGFloat = 1


    // MARK: Selected Properties
    let selectedBodyMass: CGFloat = 5
    let selectedBodyRestitution: CGFloat = 0
    let selectedBodyFriction: CGFloat = 1
    let selectedLinearDamping: CGFloat = 1


    // MARK: Seeking Properties - Level 0
    let seekingLevelZeroBodyMass: CGFloat = 5
    let seekingLevelZeroBodyRestitution: CGFloat = 0.2
    let seekingLevelZeroBodyFriction: CGFloat = 0.8
    let seekingLevelZeroBodyLinearDamping: CGFloat = 0.8

    // MARK: Seeking Properties - Level 1
    let seekingLevelOneBodyMass: CGFloat = 5
    let seekingLevelOneBodyRestitution: CGFloat = 0.2
    let seekingLevelOneBodyFriction: CGFloat = 0.8
    let seekingLevelOneBodyLinearDamping: CGFloat = 0.8

    // MARK: Seeking Properties - Level 2
    let seekingLevelTwoBodyMass: CGFloat = 5
    let seekingLevelTwoBodyRestitution: CGFloat = 0.2
    let seekingLevelTwoBodyFriction: CGFloat = 0.8
    let seekingLevelTwoBodyLinearDamping: CGFloat = 0.8

    // MARK: Seeking Properties - Level 3
    let seekingLevelThreeBodyMass: CGFloat = 5
    let seekingLevelThreeBodyRestitution: CGFloat = 0.2
    let seekingLevelThreeBodyFriction: CGFloat = 0.8
    let seekingLevelThreeBodyLinearDamping: CGFloat = 0.8

    // MARK: Seeking Properties - Level 4
    let seekingLevelFourBodyMass: CGFloat = 5
    let seekingLevelFourBodyRestitution: CGFloat = 0.2
    let seekingLevelFourBodyFriction: CGFloat = 0.8
    let seekingLevelFourBodyLinearDamping: CGFloat = 0.8


    // MARK: hasCollidedWithBoundingNode Properties - Level 0
    let collidedLayerZeroBodyMass: CGFloat = 5
    let collidedLayerZeroBodyRestitution: CGFloat = 0
    let collidedLayerZeroBodyFriction: CGFloat = 0.37
    let collidedLayerZeroBodyLinearDamping: CGFloat = 0.37

    // MARK: hasCollidedWithBoundingNode Properties - Level 1
    let collidedLayerOneBodyMass: CGFloat = 5
    let collidedLayerOneBodyRestitution: CGFloat = 0
    let collidedLayerOneBodyFriction: CGFloat = 0.37
    let collidedLayerOneBodyLinearDamping: CGFloat = 0.37

    // MARK: hasCollidedWithBoundingNode Properties - Level 2
    let collidedLayerTwoBodyMass: CGFloat = 5
    let collidedLayerTwoBodyRestitution: CGFloat = 0
    let collidedLayerTwoBodyFriction: CGFloat = 0.37
    let collidedLayerTwoBodyLinearDamping: CGFloat = 0.37

    // MARK: hasCollidedWithBoundingNode Properties - Level 3
    let collidedLayerThreeBodyMass: CGFloat = 5
    let collidedLayerThreeBodyRestitution: CGFloat = 0
    let collidedLayerThreeBodyFriction: CGFloat = 0.37
    let collidedLayerThreeBodyLinearDamping: CGFloat = 0.37

    // MARK: hasCollidedWithBoundingNode Properties - Level 4
    let collidedLayerFourBodyMass: CGFloat = 5
    let collidedLayerFourBodyRestitution: CGFloat = 0
    let collidedLayerFourBodyFriction: CGFloat = 0.37
    let collidedLayerFourBodyLinearDamping: CGFloat = 0.37


    // MARK: Seeking while selected node is panning properties
    let seekingPannedBodyMass: CGFloat = 5
    let seekingPannedBodyRestitution: CGFloat = 0.3
    let seekingPannedBodyFriction: CGFloat = 0.5
    let seekingPannedBodyLinearDamping: CGFloat = 0.5


    // MARK: Animations
    let fadeAnimationDuration = 1.0
    let moveAnimationDuration = 1.2
    let scaleAnimationDuration = 1.2


    // MARK: Titles
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
