//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SceneKit
import GameplayKit


/// Handles the transitions between states for a `RecordEntity`.
final class RecordStateMachine {

    unowned let entity: RecordEntity

    var state = EntityState.static {
        didSet {
            exit(state: oldValue)
            enter(state: state)
        }
    }

    private struct Constants {
        static let draggingLevel = -2
    }


    // MARK: Init

    init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: Helpers

    private func exit(state: EntityState) {
        switch state {
        case .static, .selected, .reset, .remove:
            break
        case .seekLevel(_), .seekEntity(_):
            entity.node.removeAllActions()
        case .dragging:
            if entity.clusterLevel.currentLevel == NodeCluster.selectedEntityLevel {
                entity.cluster?.updateLayerLevels(forPan: false)
            }
        }
    }

    private func enter(state: EntityState) {
        switch state {
        case .static:
            break
        case .selected:
            entity.set(level: NodeCluster.selectedEntityLevel)
            entity.hasCollidedWithLayer = false
            entity.updateBitMasks()
            entity.physicsBody.isDynamic = false
            entity.node.removeAllActions()
            updateTitleFor(level: NodeCluster.selectedEntityLevel)
            cluster()
        case .seekLevel(let level):
            entity.set(level: level)
            entity.hasCollidedWithLayer = false
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
        case .dragging:
            entity.removeAnimation(forKey: AnimationType.move(.zero).key)
            entity.physicsBody.isDynamic = false
            entity.node.setZ(level: Constants.draggingLevel)
            if entity.clusterLevel.currentLevel == NodeCluster.selectedEntityLevel {
                entity.cluster?.updateLayerLevels(forPan: true)
            }
        case .reset:
            reset()
        case .remove:
            remove()
        }
    }

    /// Fade out, resize and set to initial position
    private func reset() {
        let entity = self.entity
        entity.resetBitMasks()
        entity.physicsBody.isDynamic = false
        let fade = SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.perform(action: fade) {
            entity.reset()
            // Only set alpha = 1 while in development
            entity.node.alpha = 1
            entity.set(state: .static)
        }
    }

    private func remove() {
        let entity = self.entity
        entity.resetBitMasks()
        entity.physicsBody.isDynamic = false
        let fade = SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.perform(action: fade) {
            EntityManager.instance.remove(entity)
        }
    }

    /// Move and scale to the proper size for center of cluster
    private func cluster() {
        if let cluster = entity.cluster {
            let moveAnimation = AnimationType.move(cluster.center)
            let scaleAnimation = AnimationType.scale(NodeCluster.sizeFor(level: -1))
            entity.apply([moveAnimation, scaleAnimation])
        }
    }

    /// Scale to the proper size for the current cluster level else scale to default size
    private func scale() {
        let size = NodeCluster.sizeFor(level: entity.clusterLevel.currentLevel)
        let scale = AnimationType.scale(size)
        let fade = AnimationType.fade(out: false)
        entity.apply([scale, fade])
    }

    /// Fades the title node for the entity appropriately for the given level
    private func updateTitleFor(level: Int) {
        let showTitle = level < 1 ? true : false
        let fade = showTitle ? SKAction.fadeIn(withDuration: style.fadeAnimationDuration) : SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.node.titleNode.run(fade)
    }
}
