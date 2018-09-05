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


    // MARK: Physics Body Properties

    let defaultBodyMass: CGFloat = 0.25
    let defaultBodyRestitution: CGFloat = 0
    let defaultBodyFriction: CGFloat = 1
    let defaultLinearDamping: CGFloat = 1

    let forceMultiplier: CGFloat = 1 / 2000
    let panningMultiplier: CGFloat = 8000
    let multiplier: CGFloat = 100

    static let sameMass: CGFloat = 0.3
    static let sameRestitution: CGFloat = 0
    static let sameFriction: CGFloat = 0.8
    static let sameDamping: CGFloat = 0.8

    // MARK: Selected Node
    let selectedBodyMass: CGFloat = 0.25
    let selectedBodyRestitution: CGFloat = 0
    let selectedBodyFriction: CGFloat = 1
    let selectedLinearDamping: CGFloat = 1

    // MARK: Seeking - Level 0
    let seekingLevelZeroBodyMass: CGFloat = sameMass
    let seekingLevelZeroBodyRestitution: CGFloat = sameRestitution
    let seekingLevelZeroBodyFriction: CGFloat = sameFriction
    let seekingLevelZeroBodyLinearDamping: CGFloat = sameDamping

    // MARK: Seeking - Level 1
    let seekingLevelOneBodyMass: CGFloat = sameMass
    let seekingLevelOneBodyRestitution: CGFloat = sameRestitution
    let seekingLevelOneBodyFriction: CGFloat = sameFriction
    let seekingLevelOneBodyLinearDamping: CGFloat = sameDamping

    // MARK: Seeking - Level 2
    let seekingLevelTwoBodyMass: CGFloat = sameMass
    let seekingLevelTwoBodyRestitution: CGFloat = sameRestitution
    let seekingLevelTwoBodyFriction: CGFloat = sameFriction
    let seekingLevelTwoBodyLinearDamping: CGFloat = sameDamping

    // MARK: Seeking - Level 3
    let seekingLevelThreeBodyMass: CGFloat = sameMass
    let seekingLevelThreeBodyRestitution: CGFloat = sameRestitution
    let seekingLevelThreeBodyFriction: CGFloat = sameFriction
    let seekingLevelThreeBodyLinearDamping: CGFloat = sameDamping

    // MARK: Seeking - Level 4
    let seekingLevelFourBodyMass: CGFloat = sameMass
    let seekingLevelFourBodyRestitution: CGFloat = sameRestitution
    let seekingLevelFourBodyFriction: CGFloat = sameFriction
    let seekingLevelFourBodyLinearDamping: CGFloat = sameDamping


    // MARK: hasCollidedWithBoundingNode - Level 0
    let collidedLevelZeroBodyMass: CGFloat = 0.5
    let collidedLevelZeroBodyRestitution: CGFloat = 0
    let collidedLevelZeroBodyFriction: CGFloat = 1
    let collidedLevelZeroBodyLinearDamping: CGFloat = 1

    // MARK: hasCollidedWithBoundingNode - Level 1
    let collidedLevelOneBodyMass: CGFloat = 0.5
    let collidedLevelOneBodyRestitution: CGFloat = 0
    let collidedLevelOneBodyFriction: CGFloat = 1
    let collidedLevelOneBodyLinearDamping: CGFloat = 1

    // MARK: hasCollidedWithBoundingNode - Level 2
    let collidedLevelTwoBodyMass: CGFloat = 0.5
    let collidedLevelTwoBodyRestitution: CGFloat = 0
    let collidedLevelTwoBodyFriction: CGFloat = 1
    let collidedLevelTwoBodyLinearDamping: CGFloat = 1

    // MARK: hasCollidedWithBoundingNode - Level 3
    let collidedLevelThreeBodyMass: CGFloat = 0.5
    let collidedLevelThreeBodyRestitution: CGFloat = 0
    let collidedLevelThreeBodyFriction: CGFloat = 1
    let collidedLevelThreeBodyLinearDamping: CGFloat = 1

    // MARK: hasCollidedWithBoundingNode - Level 4
    let collidedLevelFourBodyMass: CGFloat = 0.5
    let collidedLevelFourBodyRestitution: CGFloat = 0
    let collidedLevelFourBodyFriction: CGFloat = 1
    let collidedLevelFourBodyLinearDamping: CGFloat = 1


    // MARK: Seeking while selected node is panning
    let seekingPannedBodyMass: CGFloat = 0.5
    let seekingPannedBodyRestitution: CGFloat = 0
    let seekingPannedBodyFriction: CGFloat = 0.3
    let seekingPannedBodyLinearDamping: CGFloat = 0.3


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
