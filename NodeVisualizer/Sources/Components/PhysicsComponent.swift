//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


struct ColliderType {
    static let staticNode: UInt32 = 0x00000000
    static let panBoundingNode: UInt32 = 1 << 20
    static let clonedRecordNode: UInt32 = 1 << 21
    static let tappedRecordNode: UInt32 = 1 << 22

    let categoryBitMask: UInt32
    let collisionBitMask: UInt32
    let contactTestBitMask: UInt32
}


/// A `GKComponent` that provides an `SKPhysicsBody` for an entity. This enables the entity to be represented in the SpriteKit physics world.
class PhysicsComponent: GKComponent {

    private(set) var physicsBody: SKPhysicsBody


    // MARK: Initializer

    init(physicsBody: SKPhysicsBody) {
        self.physicsBody = physicsBody
        super.init()
        setupInitialPhysicsBodyProperties()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard let entity = entity as? RecordEntity, !entity.hasCollidedWithLayer, let cluster = entity.cluster, cluster.selectedEntity.state != .dragging else {
            return
        }

        // Check if the contactedBodies belong to the same level, the same cluster, and the same bounding node
        let contactedBodies = physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            if let boundingNode = contactedBody.node, boundingNode.name == "boundingNode",
                let currentLevel = entity.clusterLevel.currentLevel,
                cluster.layerForLevel[currentLevel]?.renderComponent.node === boundingNode,
                !entity.hasCollidedWithLayer {
                entity.hasCollidedWithLayer = true
                return
            } else if let contactedEntity = contactedBody.node?.entity as? RecordEntity,
                let contactedEntityCluster = contactedEntity.cluster, cluster === contactedEntityCluster,
                contactedEntity.clusterLevel.currentLevel == entity.clusterLevel.currentLevel,
                contactedEntity.hasCollidedWithLayer, !entity.hasCollidedWithLayer {
                entity.hasCollidedWithLayer = true
                return
            }
        }
    }


    // MARK: API

    func updateBitMasks() {
        guard let entity = entity as? RecordEntity, let cluster = entity.cluster, entity.previousCluster == nil else {
            return
        }

        if cluster.selectedEntity.state == .dragging {
            setPanningBitMasks()
            return
        }

        switch entity.state {
        case .selected:
            setTappedEntityBitMasks()
        case .seekLevel(let level):
            setSeekingLevelBitMasks(forLevel: level)
        case .seekEntity(_):
            setSeekingEntityBitMasks()
        default:
            return
        }
    }

    /// Sets the cloned entity's bitMasks
    func setClonedNodeBitMasks() {
        physicsBody.categoryBitMask = ColliderType.clonedRecordNode
        physicsBody.collisionBitMask = ColliderType.clonedRecordNode
        physicsBody.contactTestBitMask = ColliderType.clonedRecordNode
    }

    /// Resets the entity's bitMask to interact with nothing
    func resetBitMasks() {
        physicsBody.categoryBitMask = ColliderType.staticNode
        physicsBody.collisionBitMask = ColliderType.staticNode
        physicsBody.contactTestBitMask = ColliderType.staticNode
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
        physicsBody.isDynamic = false
        physicsBody.mass = style.nodePhysicsBodyMass
        resetBitMasks()
    }

    private func setPanningBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let cluster = entity.cluster,
            let panBoundingPhysicsBody = cluster.layerForLevel[0]?.renderComponent.node?.physicsBody else {
            return
        }

        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | panBoundingPhysicsBody.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | panBoundingPhysicsBody.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | panBoundingPhysicsBody.contactTestBitMask
    }

    private func setTappedEntityBitMasks() {
        physicsBody.categoryBitMask = ColliderType.tappedRecordNode
        physicsBody.collisionBitMask = ColliderType.tappedRecordNode
        physicsBody.contactTestBitMask = ColliderType.tappedRecordNode
    }

    private func setSeekingLevelBitMasks(forLevel level: Int) {
        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask
    }

    private func setSeekingEntityBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let boundingNode = entity.cluster?.layerForLevel[level]?.renderComponent.node,
            let boundingNodePhysicsBody = boundingNode.physicsBody else {
            return
        }

        let levelBitMasks = bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | boundingNodePhysicsBody.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | boundingNodePhysicsBody.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | boundingNodePhysicsBody.contactTestBitMask
    }

    /// Returns the bitMasks for the entity's level
    private func bitMasks(forLevel level: Int) -> ColliderType {
        let categoryBitMask: UInt32 = 1 << level
        let collisionBitMask: UInt32 = 1 << level
        let contactTestBitMask: UInt32 = 1 << level

        return ColliderType(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }
}
