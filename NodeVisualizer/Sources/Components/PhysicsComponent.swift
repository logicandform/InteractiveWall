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

struct PhysicsBodyProperties {
    let mass: CGFloat
    let restitution: CGFloat
    let friction: CGFloat
    let linearDamping: CGFloat
    let isDynamic: Bool
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
            setDraggingBitMasks()
            return
        }

        switch entity.state {
        case .selected:
            setSelectedEntityBitMasks()
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

    func setPhysicsBodyProperties() {
        if let entity = entity as? RecordEntity {
            let properties = physicsBodyProperties(for: entity)
            set(properties)
        }
    }

    func physicsBodyProperties(for entity: RecordEntity) -> PhysicsBodyProperties {
        var properties: PhysicsBodyProperties

        if entity.state == .selected {
            properties = physicsBodyPropertiesForSelectedEntity()
        } else if entity.cluster?.selectedEntity.state == .dragging {
            properties = physicsBodyPropertiesForSeekingDraggedEntity()
        } else if case .seekLevel(entity.clusterLevel.currentLevel) = entity.state {
            properties = physicsBodyPropertiesForSeekingEntity()
        } else if entity.hasCollidedWithLayer {
            properties = physicsBodyPropertiesForLayerCollidedEntity()
        } else if case .seekEntity(entity.cluster?.selectedEntity) = entity.state {
            properties = physicsBodyPropertiesForSeekingEntity()
        } else {
            properties = defaultPhysicsBodyProperties()
        }

        return properties
    }

    func resetPhysicsBodyProperties() {
        physicsBody.mass = style.defaultBodyMass
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0
        physicsBody.isDynamic = false
    }


    // MARK: Helpers

    private func setupInitialPhysicsBodyProperties() {
        resetPhysicsBodyProperties()
        resetBitMasks()
    }


    // MARK: Helpers - BitMasks

    private func setDraggingBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let cluster = entity.cluster,
            let panBoundingPhysicsBody = cluster.layerForLevel[0]?.renderComponent.layerNode.physicsBody else {
            return
        }

        let levelBitMasks = RecordNode.bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask | panBoundingPhysicsBody.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask | panBoundingPhysicsBody.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask | panBoundingPhysicsBody.contactTestBitMask
    }

    private func setSelectedEntityBitMasks() {
        physicsBody.categoryBitMask = ColliderType.tappedRecordNode
        physicsBody.collisionBitMask = ColliderType.tappedRecordNode
        physicsBody.contactTestBitMask = ColliderType.tappedRecordNode
    }

    private func setSeekingLevelBitMasks(forLevel level: Int) {
        let levelBitMasks = RecordNode.bitMasks(forLevel: level)
        physicsBody.categoryBitMask = levelBitMasks.categoryBitMask
        physicsBody.collisionBitMask = levelBitMasks.collisionBitMask
        physicsBody.contactTestBitMask = levelBitMasks.contactTestBitMask
    }

    private func setSeekingEntityBitMasks() {
        guard let entity = entity as? RecordEntity,
            let level = entity.clusterLevel.currentLevel,
            let boundingNode = entity.cluster?.layerForLevel[level]?.renderComponent.layerNode,
            let boundingNodePhysicsBody = boundingNode.physicsBody else {
            return
        }

        let levelBitMasks = RecordNode.bitMasks(forLevel: level)
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


    // MARK: Helpers - Physics Body Properties

    private func physicsBodyPropertiesForSelectedEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.selectedBodyMass,
            restitution: style.selectedBodyRestitution,
            friction: style.selectedBodyFriction,
            linearDamping: style.selectedLinearDamping,
            isDynamic: false)
    }

    private func physicsBodyPropertiesForSeekingDraggedEntity() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.seekingPannedBodyMass,
            restitution: style.seekingPannedBodyRestitution,
            friction: style.seekingPannedBodyFriction,
            linearDamping: style.seekingPannedBodyLinearDamping,
            isDynamic: true)
    }

    private func physicsBodyPropertiesForLayerCollidedEntity() -> PhysicsBodyProperties {
        guard let entity = entity as? RecordEntity else {
            return defaultPhysicsBodyProperties()
        }

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
            return defaultPhysicsBodyProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping, isDynamic: true)
    }

    private func physicsBodyPropertiesForSeekingEntity() -> PhysicsBodyProperties {
        guard let entity = entity as? RecordEntity else {
            return defaultPhysicsBodyProperties()
        }

        var mass: CGFloat
        var restitution: CGFloat
        var friction: CGFloat
        var damping: CGFloat

        switch entity.clusterLevel.currentLevel {
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
            return defaultPhysicsBodyProperties()
        }

        return PhysicsBodyProperties(mass: mass, restitution: restitution, friction: friction, linearDamping: damping, isDynamic: true)
    }

    private func defaultPhysicsBodyProperties() -> PhysicsBodyProperties {
        return PhysicsBodyProperties(
            mass: style.defaultBodyMass,
            restitution: style.defaultBodyRestitution,
            friction: style.defaultBodyFriction,
            linearDamping: style.defaultLinearDamping,
            isDynamic: true)
    }

    private func set(_ properties: PhysicsBodyProperties) {
        physicsBody.isDynamic = properties.isDynamic
        physicsBody.mass = properties.mass
        physicsBody.restitution = properties.restitution
        physicsBody.friction = properties.friction
        physicsBody.linearDamping = properties.linearDamping
    }
}
