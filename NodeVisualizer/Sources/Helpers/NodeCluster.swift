//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    Class that manages the bounding diameter level nodes for the scene.
 */

import Foundation
import SpriteKit
import GameplayKit


typealias EntityLevels = [Set<RecordEntity>]


final class NodeCluster: Hashable {

    let center: CGPoint
    private let scene: MainScene
    private(set) var selectedEntity: RecordEntity
    private(set) var entitiesForLevel = EntityLevels()
    private(set) var layerForLevel = [Int: NodeBoundingEntity]()

    var hashValue: Int {
        return selectedEntity.hashValue
    }

    private lazy var componentSystems: [GKComponentSystem] = {
        let renderSystem = GKComponentSystem(componentClass: NodeBoundingRenderComponent.self)
        return [renderSystem]
    }()

    private struct BoundingNodeBitMasks {
        let categoryBitMask: UInt32
        let contactTestBitMask: UInt32
        let collisionBitMask: UInt32
    }

    private struct Constants {
        static let boundingNodeName = "boundingNode"
        static let defaultLayerRadius = NodeConfiguration.Record.physicsBodyRadius + 5
    }


    // MARK: Init

    init(scene: MainScene, entity: RecordEntity) {
        self.scene = scene
        self.selectedEntity = entity
        self.center = selectedEntity.renderComponent.recordNode.frame.center
    }


    // MARK: API

    /// Updates all component systems
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    /// Updates the layers in the cluster for the selected entity and updates the levels for all current entities
    func select(_ entity: RecordEntity) {
        compareRecords(for: entity)
        attach(to: entity)
        setLayers(toLevel: entitiesForLevel.count)
        updateLevelsForSelectedEntity()
    }

    /// Removes all entities currently formed in the cluster and removes all bounding layers
    func reset() {
        // Reset all entities
        selectedEntity.reset()
        for level in entitiesForLevel {
            for entity in level {
                entity.reset()
            }
        }

        // TODO: UBC-530 Call entity manager to remove duplicate entities that were required to make the cluster

        // Remove all layers
        for (level, _) in layerForLevel.enumerated() {
            removeLayer(level: level)
        }
    }

    /// Calculates the distance from the root bounding node to the specified entity
    func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = layerForLevel[0]?.nodeBoundingRenderComponent.node else {
            return 0
        }
        let dX = Float(rootBoundingNode.position.x - entity.renderComponent.recordNode.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.renderComponent.recordNode.position.y)
        return CGFloat(hypotf(dX, dY).magnitude)
    }


    // MARK: Helpers

    /// Removes entities from the cluster that are not related to the new entity
    private func compareRecords(for newEntity: RecordEntity) {
        var oldRecords = selectedEntity.relatedRecords
        oldRecords.insert(selectedEntity.record.proxy)
        var newRecords = newEntity.relatedRecords
        newRecords.insert(newEntity.record.proxy)
        let recordsToRemove = oldRecords.subtracting(newRecords)
        remove(recordsToRemove)
    }

    /// Removes entities for each given proxy from `self`
    private func remove(_ proxies: Set<RecordProxy>) {
        var entities = Set<RecordEntity>()
        for entitiesInLevel in entitiesForLevel {
            entities.formUnion(entitiesInLevel)
        }

        for proxy in proxies {
            if let entity = entities.first(where: { $0.record.proxy == proxy }) {
                entity.reset()
            }
        }
    }

    /// Requests all entities for related records of the given entity. Sets their `cluster` to `self`.
    private func attach(to entity: RecordEntity) {
        var entityLevels = EntityLevels()
        for (index, level) in entity.relatedRecordsForLevel.enumerated() {
            let entitiesForLevel = EntityManager.instance.requestEntities(with: level, for: self)
            if entitiesForLevel.isEmpty {
                break
            }
            entityLevels.insert(entitiesForLevel, at: index)
            for entity in entitiesForLevel {
                entity.cluster = self
            }
        }
        entity.cluster = self
        entitiesForLevel = entityLevels
    }

    private func updateLevelsForSelectedEntity() {
        // Set selected node level to -1
        selectedEntity.clusterLevel.currentLevel = -1

        // Update the tapped entity's descendants to the appropriate state with appropriate movement
        for (level, entities) in entitiesForLevel.enumerated() {
            for entity in entities {
                entity.clusterLevel = (previousLevel: entity.clusterLevel.currentLevel, currentLevel: level)
                entity.physicsComponent.setLevelInteractingBitMasks(forLevel: level)
                entity.movementComponent.requestedMovementState = .moveToAppropriateLevel
                entity.intelligenceComponent.stateMachine.enter(SeekBoundingLevelNodeState.self)
            }
        }
    }

    /// Iterates through the levels between the current max level and the desired level and either adds or removes layers.
    private func setLayers(toLevel level: Int) {
        let minimum = min(level + 1, layerForLevel.count)
        let maximum = max(level, layerForLevel.count)

        for current in (minimum ... maximum) {
            if current > level {
                removeLayer(level: current)
            } else {
                addLayer(level: current)
            }
        }
    }

    /// Associates the entity to its level by adding it to the nodeBoundingEntityForLevel. Adds the entity's component to the component system
    private func addLayer(level: Int) {
        let radius = layerForLevel[level - 1]?.nodeBoundingRenderComponent.maxRadius ?? Constants.defaultLayerRadius
        let node = layerNode(radius: radius, level: level)

        let layer = NodeBoundingEntity(cluster: self)
        layer.nodeBoundingRenderComponent.node = node
        layer.nodeBoundingRenderComponent.maxRadius = radius
        layer.nodeBoundingRenderComponent.minRadius = radius
        layer.nodeBoundingRenderComponent.level = level
        layerForLevel[level] = layer

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: layer)
        }
    }

    /// Removes layer and it's components from the cluster
    private func removeLayer(level: Int) {
        guard let layer = layerForLevel[level], let node = layer.nodeBoundingRenderComponent.node else {
            return
        }

        node.removeFromParent()
        layerForLevel.removeValue(forKey: level)
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: layer)
        }
    }

    /// Creates the bounding node with the appropriate physics bodies and adds it to the scene
    private func layerNode(radius: CGFloat, level: Int) -> SKNode {
        let boundingNode = SKNode()
        boundingNode.name = Constants.boundingNodeName
        boundingNode.zPosition = 1
        boundingNode.position = center

        boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        boundingNode.physicsBody?.mass = NodeConfiguration.Record.physicsBodyMass
        boundingNode.physicsBody?.isDynamic = false
        boundingNode.physicsBody?.friction = 0
        boundingNode.physicsBody?.restitution = 0
        boundingNode.physicsBody?.linearDamping = 0

        let bitMasks = boundingNodeBitMasks(forLevel: level)
        boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
        boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask
        boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask

        scene.addChild(boundingNode)
        return boundingNode
    }

    /// Provides the bitMasks for the bounding node's physics bodies. The bits are offset by 20 in order to make them unique from the level entity's bitMasks.
    private func boundingNodeBitMasks(forLevel level: Int) -> BoundingNodeBitMasks {
        let levelBit = 20 + level
        let categoryBitMask: UInt32 = 0x1 << levelBit
        let contactTestBitMask: UInt32 = 0x1 << levelBit
        let collisionBitMask: UInt32 = 0x1 << levelBit

        return BoundingNodeBitMasks(
            categoryBitMask: categoryBitMask,
            contactTestBitMask: contactTestBitMask,
            collisionBitMask: collisionBitMask
        )
    }

    static func == (lhs: NodeCluster, rhs: NodeCluster) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
