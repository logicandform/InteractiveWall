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
        static let backgroundLevel = 0
        static let driftingAlpha: CGFloat = 0.8
    }


    // MARK: Init

    init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: Helpers

    private func exit(state: EntityState) {
        switch state {
        case .static, .drift, .selected, .reset, .remove:
            break
        case .seekLevel, .seekEntity:
            entity.node.removeAllActions()
        case .dragging:
            if entity.isSelected {
                entity.cluster?.updateLayerLevels(forPan: false)
            }
        }
    }

    private func enter(state: EntityState) {
        entity.updateBitMasks()

        switch state {
        case .static:
            break
        case .drift:
            entity.resetProperties()
            entity.physicsBody.velocity.dy = CGFloat.random(in: style.themeDyRange)
            entity.physicsBody.isDynamic = true
            entity.physicsBody.friction = 0
            entity.physicsBody.linearDamping = 0
            entity.physicsBody.restitution = 0
            entity.physicsBody.angularDamping = 0
            entity.node.removeAllActions()
            updateViews(level: Constants.backgroundLevel)
            entity.node.setZ(level: Constants.backgroundLevel, clusterID: 0)
            scale()
        case .selected:
            entity.set(level: NodeCluster.selectedEntityLevel)
            entity.hasCollidedWithLayer = false
            entity.physicsBody.isDynamic = false
            entity.node.removeAllActions()
            updateViews(level: NodeCluster.selectedEntityLevel)
            cluster()
        case .seekLevel(let level):
            entity.set(level: level)
            entity.hasCollidedWithLayer = false
            entity.physicsBody.isDynamic = true
            entity.physicsBody.restitution = 0
            entity.physicsBody.friction = 1
            entity.physicsBody.linearDamping = 1
            entity.node.removeAllActions()
            updateViews(level: level)
            scale()
        case .seekEntity:
            entity.physicsBody.isDynamic = true
            entity.physicsBody.restitution = 0
            entity.physicsBody.friction = 1
            entity.physicsBody.linearDamping = 1
            entity.node.removeAllActions()
            scale()
        case .dragging:
            entity.removeAnimation(forKey: AnimationType.move(.zero).key)
            entity.physicsBody.isDynamic = false
            entity.node.setZ(level: Constants.draggingLevel, clusterID: entity.cluster?.id ?? 0)
            if entity.isSelected {
                entity.cluster?.updateLayerLevels(forPan: true)
            }
        case .reset:
            updateViews(level: Constants.backgroundLevel)
            reset()
        case .remove:
            remove()
        }
    }

    /// Fade out, resize and set to initial position
    private func reset() {
        let entity = self.entity
        entity.physicsBody.isDynamic = false
        let fade = SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.perform(action: fade) {
            entity.resetProperties()
            entity.resetNode()
            entity.set(state: .static)
        }
    }

    private func remove() {
        let entity = self.entity
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
    private func updateViews(level: Int) {
        let showTitle = NodeCluster.showTitleFor(level: level)
        let titleAction = showTitle ? SKAction.fadeIn(withDuration: style.fadeAnimationDuration) : SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.node.titleNode.run(titleAction)
        let showButtons = level == NodeCluster.selectedEntityLevel
        let buttonAction = showButtons ? SKAction.fadeIn(withDuration: style.fadeAnimationDuration) : SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.node.closeNode.run(buttonAction)
        entity.node.openNode.run(buttonAction)
        let showIcon = NodeCluster.showIconFor(level: level)
        let iconAction = showIcon ? SKAction.fadeIn(withDuration: style.fadeAnimationDuration) : SKAction.fadeOut(withDuration: style.fadeAnimationDuration)
        entity.node.iconNode.run(iconAction)
    }
}
