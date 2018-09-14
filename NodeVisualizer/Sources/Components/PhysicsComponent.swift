//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


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
            if let boundingNode = contactedBody.node, boundingNode.name == ClusterLayerNode.nodeName,
                let currentLevel = entity.clusterLevel.currentLevel,
                cluster.layerForLevel[currentLevel]?.renderComponent.layerNode === boundingNode,
                !entity.hasCollidedWithLayer {
                entity.hasCollidedWithLayer = true
                entity.updatePhysicsBodyProperties()
                return
            } else if let contactedEntity = contactedBody.node?.entity as? RecordEntity,
                let contactedEntityCluster = contactedEntity.cluster, cluster === contactedEntityCluster,
                contactedEntity.clusterLevel.currentLevel == entity.clusterLevel.currentLevel,
                contactedEntity.hasCollidedWithLayer, !entity.hasCollidedWithLayer {
                entity.hasCollidedWithLayer = true
                entity.updatePhysicsBodyProperties()
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
            let bitMasksForDraggingSelectedEntity = ColliderType.draggingBitMasks(for: entity)
            set(bitMasksForDraggingSelectedEntity)
            return
        }

        let bitMasks = entity.state.bitMasks
        set(bitMasks)
    }

    func setClonedNodeBitMasks() {
        let bitMasks = ColliderType.bitMasksForClonedEntity()
        set(bitMasks)
    }

    func resetBitMasks() {
        let bitMasks = ColliderType.resetBitMasks()
        set(bitMasks)
    }

    func updatePhysicsBodyProperties() {
        if let entity = entity as? RecordEntity {
            let properties = physicsBodyProperties(for: entity)
            set(properties)
        }
    }

    func physicsBodyProperties(for entity: RecordEntity) -> PhysicsBodyProperties {
        var properties: PhysicsBodyProperties

        if entity.cluster?.selectedEntity.state == .dragging {
            properties = PhysicsBodyProperties.propertiesForSeekingDraggingEntity()
        } else if entity.hasCollidedWithLayer {
            properties = PhysicsBodyProperties.propertiesForLayerCollidedEntity(entity: entity)
        } else {
            properties = entity.state.physicsBodyProperties
        }

        return properties
    }

    func resetPhysicsBodyProperties() {
        let properties = PhysicsBodyProperties.propertiesForResettingAndRemovingEntity()
        set(properties)
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        resetPhysicsBodyProperties()
        resetBitMasks()
    }

    private func set(_ bitMasks: ColliderType) {
        physicsBody.categoryBitMask = bitMasks.categoryBitMask
        physicsBody.collisionBitMask = bitMasks.collisionBitMask
        physicsBody.contactTestBitMask = bitMasks.contactTestBitMask
    }

    private func set(_ properties: PhysicsBodyProperties) {
        physicsBody.isDynamic = properties.isDynamic
        physicsBody.mass = properties.mass
        physicsBody.restitution = properties.restitution
        physicsBody.friction = properties.friction
        physicsBody.linearDamping = properties.linearDamping
    }
}
