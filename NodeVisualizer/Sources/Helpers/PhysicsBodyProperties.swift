//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit


struct PhysicsBodyProperties {
    let mass: CGFloat
    let restitution: CGFloat
    let friction: CGFloat
    let linearDamping: CGFloat
    let isDynamic: Bool


    // MARK: API

    static func defaultProperties() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.defaultBodyMass,
            restitution: style.defaultBodyRestitution,
            friction: style.defaultBodyFriction,
            linearDamping: style.defaultLinearDamping,
            isDynamic: true)
    }

    static func propertiesForSelectedEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.selectedBodyMass,
            restitution: style.selectedBodyRestitution,
            friction: style.selectedBodyFriction,
            linearDamping: style.selectedLinearDamping,
            isDynamic: false)
    }

    static func propertiesForSeekingDraggingEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.seekingPannedBodyMass,
            restitution: style.seekingPannedBodyRestitution,
            friction: style.seekingPannedBodyFriction,
            linearDamping: style.seekingPannedBodyLinearDamping,
            isDynamic: true)
    }

    static func propertiesForResettingAndRemovingEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.defaultBodyMass,
            restitution: 0,
            friction: 0,
            linearDamping: 0,
            isDynamic: false)
    }

    static func properties(forLevel level: Int?) -> PhysicsBodyProperties {
        guard let level = level else {
            return PhysicsBodyProperties.defaultProperties()
        }

        var mass: CGFloat
        var restitution: CGFloat
        var friction: CGFloat
        var damping: CGFloat

        switch level {
        case 0:
            mass = style.seekingLevelZeroBodyMass
            restitution = style.seekingLevelZeroBodyRestitution
            friction = style.seekingLevelZeroBodyFriction
            damping = style.seekingLevelZeroBodyLinearDamping
        case 1:
            mass = style.seekingLevelOneBodyMass
            restitution = style.seekingLevelOneBodyRestitution
            friction = style.seekingLevelOneBodyFriction
            damping = style.seekingLevelOneBodyLinearDamping
        case 2:
            mass = style.seekingLevelTwoBodyMass
            restitution = style.seekingLevelTwoBodyRestitution
            friction = style.seekingLevelTwoBodyFriction
            damping = style.seekingLevelTwoBodyLinearDamping
        case 3:
            mass = style.seekingLevelThreeBodyMass
            restitution = style.seekingLevelThreeBodyRestitution
            friction = style.seekingLevelThreeBodyFriction
            damping = style.seekingLevelThreeBodyLinearDamping
        case 4:
            mass = style.seekingLevelFourBodyMass
            restitution = style.seekingLevelFourBodyRestitution
            friction = style.seekingLevelFourBodyFriction
            damping = style.seekingLevelFourBodyLinearDamping
        default:
            return PhysicsBodyProperties.defaultProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping, isDynamic: true)
    }

    static func propertiesForLayerCollidedEntity(entity: RecordEntity) -> PhysicsBodyProperties {
        var mass: CGFloat
        var restitution: CGFloat
        var friction: CGFloat
        var damping: CGFloat

        switch entity.clusterLevel.currentLevel {
        case 0:
            mass = style.collidedLayerZeroBodyMass
            restitution = style.collidedLayerZeroBodyRestitution
            friction = style.collidedLayerZeroBodyFriction
            damping = style.collidedLayerZeroBodyLinearDamping
        case 1:
            mass = style.collidedLayerOneBodyMass
            restitution = style.collidedLayerOneBodyRestitution
            friction = style.collidedLayerOneBodyFriction
            damping = style.collidedLayerOneBodyLinearDamping
        case 2:
            mass = style.collidedLayerTwoBodyMass
            restitution = style.collidedLayerTwoBodyRestitution
            friction = style.collidedLayerTwoBodyFriction
            damping = style.collidedLayerTwoBodyLinearDamping
        case 3:
            mass = style.collidedLayerThreeBodyMass
            restitution = style.collidedLayerThreeBodyRestitution
            friction = style.collidedLayerThreeBodyFriction
            damping = style.collidedLayerThreeBodyLinearDamping
        case 4:
            mass = style.collidedLayerFourBodyMass
            restitution = style.collidedLayerFourBodyRestitution
            friction = style.collidedLayerFourBodyFriction
            damping = style.collidedLayerFourBodyLinearDamping
        default:
            return PhysicsBodyProperties.defaultProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping, isDynamic: true)
    }
}
