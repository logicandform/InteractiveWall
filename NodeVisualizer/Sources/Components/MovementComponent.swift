//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides different types of physics movement based on the current `RecordState`.
class MovementComponent: GKComponent {

    var state = EntityState.static {
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
        static let selectedEntityLevel = -1
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        checkAndUpdateBitMaskIfCloned()

        switch state {
        case .seekEntity(let entity):
            seek(entity)
        case .seekLevel(let level):
            move(to: level)
        case .static, .selected, .panning, .reset:
            break
        }
    }


    // MARK: Helpers

    private func checkAndUpdateBitMaskIfCloned() {
        if let entity = entity as? RecordEntity {
            if let previousCluster = entity.previousCluster,
                let outmostBoundingEntity = previousCluster.layerForLevel[previousCluster.layerForLevel.count - 1]?.renderComponent {
                let deltaX = entity.position.x - previousCluster.center.x
                let deltaY = entity.position.y - previousCluster.center.y
                let distance = previousCluster.distanceOf(x: deltaX, y: deltaY)

                // Update bitmasks if the entity has gone outside the cluster's maxRadius or if the selected entity is panned inside the cluster's maxRadius before
                // the entity has gone outside the maxRadius
                if distance > outmostBoundingEntity.maxRadius || (entity.cluster?.selectedEntity.state == .panning && distance < outmostBoundingEntity.maxRadius) {
                    entity.previousCluster = nil
                    entity.updateBitMasks()
                }
            } else if entity.physicsBody.categoryBitMask == ColliderType.clonedRecordNode {
                entity.previousCluster = nil
                entity.updateBitMasks()
            }
        }
    }

    private func exit(state: EntityState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch state {
        case .static, .selected, .reset:
            break
        case .seekLevel(_), .seekEntity(_):
            entity.node.removeAllActions()
        case .panning:
            entity.cluster?.updateLayerLevels(forPan: false)
        }
    }

    private func enter(state: EntityState) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch state {
        case .static:
            break
        case .selected:
            entity.set(level: Constants.selectedEntityLevel)
            entity.hasCollidedWithBoundingNode = false
            entity.updateBitMasks()
            entity.physicsBody.isDynamic = false
            entity.node.removeAllActions()
            updateTitleFor(level: Constants.selectedEntityLevel)
            cluster()
        case .seekLevel(let level):
            entity.set(level: level)
            entity.hasCollidedWithBoundingNode = false
            entity.updateBitMasks()
            entity.physicsBody.isDynamic = true
            entity.physicsBody.restitution = 0
            entity.physicsBody.friction = 1
            entity.physicsBody.linearDamping = 1
            entity.node.removeAllActions()
            updateTitleFor(level: level)
            scale()
        case .seekEntity(_):
            entity.updateBitMasks()
            entity.physicsBody.isDynamic = true
            entity.physicsBody.restitution = 0
            entity.physicsBody.friction = 1
            entity.physicsBody.linearDamping = 1
            entity.node.removeAllActions()
            scale()
        case .panning:
            entity.physicsBody.isDynamic = false
            entity.node.removeAllActions()
            entity.cluster?.updateLayerLevels(forPan: true)
        case .reset:
            entity.physicsBody.isDynamic = false
            reset()
        }
    }

    /// Fade out, resize and set to initial position
    private func reset() {
        guard let entity = entity as? RecordEntity else {
            return
        }

        entity.resetBitMasks()
        let fade = SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.perform(action: fade) {
            entity.reset()
            entity.node.alpha = 1
            entity.set(state: .static)
        }
    }

    /// Move and scale to the proper size for center of cluster
    private func cluster() {
        if let entity = entity as? RecordEntity, let cluster = entity.cluster {
            let moveAnimation = AnimationState.move(cluster.center)
            let scaleAnimation = AnimationState.scale(NodeCluster.sizeFor(level: -1))
            entity.set([moveAnimation, scaleAnimation])
        }
    }

    /// Scale to the proper size for the current cluster level else scale to default size
    private func scale() {
        if let entity = entity as? RecordEntity {
            let size = NodeCluster.sizeFor(level: entity.clusterLevel.currentLevel)
            let scale = AnimationState.scale(size)
            let fade = AnimationState.fade(out: false)
            entity.set([scale, fade])
        }
    }

    /// Fades the title node for the entity appropriately for the given level
    private func updateTitleFor(level: Int) {
        if let entity = entity as? RecordEntity {
            let showTitle = level < 1 ? true : false
            let fade = showTitle ? SKAction.fadeIn(withDuration: style.fadeAnimationDuration) : SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
            entity.node.titleNode.run(fade)
        }
    }


    // MARK: Physics Movement

    /// Applies appropriate physics that moves the entity to the appropriate higher level before entering next state and setting its bitMasks
    private func move(to level: Int) {
        guard let entity = entity as? RecordEntity,
            let cluster = entity.cluster,
            let referenceNode = cluster.layerForLevel[level]?.renderComponent.node else {
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
            let currentLevelBoundingEntityComponent = cluster.layerForLevel[currentLevel]?.renderComponent else {
                return
        }

        let r2 = currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < -entity.bodyRadius {
            entity.set(state: .seekEntity(cluster.selectedEntity))
        } else {
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

        let targetEntityMass = style.nodePhysicsBodyMass * Constants.strength * radius
        let entityMass = style.nodePhysicsBodyMass * Constants.strength * radius

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
