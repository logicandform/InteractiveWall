//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides different types of physics movement based on the current `RecordState`.
class MovementComponent: GKComponent {

    var state = EntityState.falling {
        didSet {
            exit(state: oldValue)
            enter(state: state)
        }
    }

    private struct Constants {
        static let strength: CGFloat = 1000
        static let dt: CGFloat = 1 / 5000
        static let distancePadding: CGFloat = -10
        static let speed: CGFloat = 200
        static let maxVerticalVelocity: CGFloat = 8
        static let maxHorizontalVelocity: CGFloat = 15
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        switch state {
        case .falling:
            fall()
        case .seekEntity(let entity):
            seek(entity)
        case .seekLevel(let level):
            move(to: level)
        case .tapped:
            // Animation only needs to be run once in the enter function.
            break
        case .panning:
            break
        }
    }


    // MARK: Helpers

    private func exit(state: EntityState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch state {
        case .falling:
            entity.physicsBody.affectedByGravity = false
        case .tapped:
            entity.physicsBody.isDynamic = true
        case .panning:
            entity.physicsBody.isDynamic = true
            entity.cluster?.updateLayerLevels(forPan: false)
        default:
            break
        }
    }

    private func enter(state: EntityState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch state {
        case .falling:
            entity.physicsBody.affectedByGravity = true
        case .seekLevel(_), .seekEntity(_):
            entity.physicsBody.restitution = 0
            entity.physicsBody.friction = 1
            entity.physicsBody.linearDamping = 1
        case .tapped:
            entity.physicsBody.isDynamic = false
            cluster()
        case .panning:
            entity.physicsBody.isDynamic = false
            entity.node.removeAllActions()
            entity.cluster?.updateLayerLevels(forPan: true)
        }
    }

    private func fall() {
        guard let entity = entity as? RecordEntity, let sceneFrame = entity.node.scene?.frame else {
            return
        }

        // Limit the velocity that can accumulate from gravity / node clustering
        entity.physicsBody.velocity.dy = clamp(entity.physicsBody.velocity.dy, min: -Constants.maxVerticalVelocity, max: Constants.maxVerticalVelocity)
        entity.physicsBody.velocity.dx = clamp(entity.physicsBody.velocity.dx, min: -Constants.maxHorizontalVelocity, max: Constants.maxHorizontalVelocity)

        // Determine if the position of the node needs to be repositioned to the top of the scene
        if entity.position.y < -style.nodePhysicsBodyRadius {
            let topPosition = sceneFrame.height + style.nodePhysicsBodyRadius
            entity.set(position: CGPoint(x: entity.position.x, y: topPosition))
        }

        // Determine if the position of the node needs to be repositioned to the left of the scene
        if entity.position.x > sceneFrame.width + style.nodePhysicsBodyRadius {
            let leftPosition = -style.nodePhysicsBodyRadius
            entity.set(position: CGPoint(x: leftPosition, y: entity.position.y))
        }
    }

    private func cluster() {
        guard let entity = entity as? RecordEntity, let cluster = entity.cluster else {
            return
        }

        entity.set(state: .goToPoint(cluster.center))
    }

    /// Applies appropriate physics that moves the entity to the appropriate higher level before entering next state and setting its bitMasks
    private func move(to level: Int) {
        guard let entity = entity as? RecordEntity, let cluster = entity.cluster, let referenceNode = cluster.layerForLevel[level]?.nodeBoundingRenderComponent.node else {
            return
        }

        // Find the unit vector from the distance between this component's entity and the center root node
        let deltaX = entity.position.x - referenceNode.position.x
        let deltaY = entity.position.y - referenceNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let distanceBetweenNodeAndCenter = distanceOf(x: deltaX, y: deltaY)

        var unitVector: CGVector
        // Check whether the entity is currently in the center in order to apply a non-zero unit vector for movement
        if distanceBetweenNodeAndCenter > 0 {
            unitVector = CGVector(dx: displacement.dx / distanceBetweenNodeAndCenter, dy: displacement.dy / distanceBetweenNodeAndCenter)
        } else {
            unitVector = CGVector(dx: 0.5, dy: 0)
        }

        // Find the difference in distance. This gives the total distance that is left to travel for the node
        guard let currentLevel = entity.clusterLevel.currentLevel,
            let currentLevelBoundingEntityComponent = cluster.layerForLevel[currentLevel]?.nodeBoundingRenderComponent else {
                return
        }

        let r2 = currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < Constants.distancePadding {
            // Enter SeekState and provide the appropriate bitmasks and entityToSeek for the MovementComponent
//            entity.physicsBody.categoryBitMask = LayerBitMasks.outerBoundingNodeBitMask
//            entity.physicsBody.collisionBitMask = LayerBitMasks.outerBoundingNodeBitMask
//            entity.physicsBody.contactTestBitMask = LayerBitMasks.outerBoundingNodeBitMask
//            entity.setBitMasks(forLevel: currentLevel)
            entity.set(state: .seekEntity(cluster.selectedEntity))
            state = .seekEntity(cluster.selectedEntity)
        } else {
            // Apply velocity
            entity.physicsBody.velocity = CGVector(dx: Constants.speed * unitVector.dx, dy: Constants.speed * unitVector.dy)
        }
    }

    /// Applies appropriate physics that emulates a gravitational pull between this component's entity and the entity that it should seek
    private func seek(_ targetEntity: RecordEntity) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        // Check the radius between its own entity and the nodeToSeek, and apply the appropriate physics
        let deltaX = targetEntity.position.x - entity.position.x
        let deltaY = targetEntity.position.y - entity.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)

        let radius = distanceOf(x: deltaX, y: deltaY)

        let targetEntityMass = targetEntity.physicsBody.mass * Constants.strength * radius
        let entityMass = entity.physicsBody.mass * Constants.strength * radius

        let unitVector = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)
        let force = (targetEntityMass * entityMass) / (radius * radius)
        let impulse = CGVector(dx: force * Constants.dt * unitVector.dx, dy: force * Constants.dt * unitVector.dy)

        entity.physicsBody.velocity = CGVector(dx: entity.physicsBody.velocity.dx + impulse.dx, dy: entity.physicsBody.velocity.dy + impulse.dy)
    }

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
