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

    private(set) var center: CGPoint
    private(set) var selectedEntity: RecordEntity
    private(set) var entitiesForLevel = EntityLevels()
    private(set) var layerForLevel = [Int: ClusterLayer]()
    private let scene: MainScene

    var hashValue: Int {
        return selectedEntity.hashValue
    }

    private lazy var componentSystems: [GKComponentSystem] = {
        let renderSystem = GKComponentSystem(componentClass: LayerRenderComponent.self)
        return [renderSystem]
    }()

    private struct Constants {
        static let boundingNodeName = "boundingNode"
        static let defaultLayerRadius: CGFloat = style.selectedNodeRadius
    }


    // MARK: Init

    init(scene: MainScene, entity: RecordEntity) {
        self.scene = scene
        self.selectedEntity = entity
        self.center = selectedEntity.position
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
        attach(to: entity)
        setLayers(toLevel: entitiesForLevel.count)
        updateStatesForEntities()
    }

    /// Updates the layers in the cluster for when the selected entity is panning
    func updateLayerLevels(forPan pan: Bool) {
        let level = pan ? 0 : entitiesForLevel.count
        setLayers(toLevel: level)
        updateInnerMostLayerBitMasks(forPan: pan)
        for entities in entitiesForLevel {
            for entity in entities {
                entity.hasCollidedWithBoundingNode = false
                entity.updateBitMasks()
            }
        }
    }

    /// Updates center point and bounding nodes to the new panned position
    func updateClusterPosition(to position: CGPoint) {
        center = position
        for (_, layer) in layerForLevel {
            layer.renderComponent.node?.position = position
        }
    }

    /// Removes all entities currently formed in the cluster and removes all bounding layers
    func reset() {
        // Reset all entities
        EntityManager.instance.release(selectedEntity)
        for level in entitiesForLevel {
            for entity in level {
                EntityManager.instance.release(entity)
            }
        }

        // Remove all layers
        for (level, _) in layerForLevel.enumerated() {
            removeLayer(level: level)
        }
    }

    /// Calculates the distance from the root bounding node to the specified entity
    func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = layerForLevel[0]?.renderComponent.node else {
            return 0
        }
        let dX = Float(rootBoundingNode.position.x - entity.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.position.y)
        return CGFloat(hypotf(dX, dY).magnitude)
    }

    /// Calculates the distance between two points
    func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }


    // MARK: Helpers

    /// Requests all entities for related records of the given entity. Sets their `cluster` to `self`.
    private func attach(to entity: RecordEntity) {
        let currentEntities = flatten(entitiesForLevel)
        let newLevels = EntityManager.instance.requestEntityLevels(for: entity, in: self)
        let entitiesToRelease = currentEntities.subtracting(flatten(newLevels) + [entity])

        selectedEntity = entity
        entity.cluster = self
        entitiesForLevel = newLevels

        for entity in entitiesToRelease {
            EntityManager.instance.release(entity)
        }
    }

    private func updateStatesForEntities() {
        selectedEntity.set(state: .tapped)

        // Update the tapped entity's descendants to the appropriate state with appropriate movement
        for (level, entities) in entitiesForLevel.enumerated() {
            for entity in entities {
                entity.set(state: .seekLevel(level))
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
        let radius = layerForLevel[level - 1]?.renderComponent.maxRadius ?? Constants.defaultLayerRadius
        let node = layerNode(radius: radius, level: level)

        let layer = ClusterLayer(cluster: self)
        layer.renderComponent.node = node
        layer.renderComponent.maxRadius = radius
        layer.renderComponent.minRadius = radius
        layer.renderComponent.level = level
        layerForLevel[level] = layer

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: layer)
        }
    }

    /// Removes layer and its components from the cluster
    private func removeLayer(level: Int) {
        guard let layer = layerForLevel[level], let node = layer.renderComponent.node else {
            return
        }

        node.removeFromParent()
        layerForLevel.removeValue(forKey: level)
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: layer)
        }
    }

    private func updateInnerMostLayerBitMasks(forPan pan: Bool) {
        guard let innerMostLayerPhysicsBody = layerForLevel[0]?.renderComponent.node?.physicsBody else {
            return
        }

        if pan {
            innerMostLayerPhysicsBody.categoryBitMask = ColliderType.panBoundingNode
            innerMostLayerPhysicsBody.collisionBitMask = ColliderType.panBoundingNode
            innerMostLayerPhysicsBody.contactTestBitMask = ColliderType.panBoundingNode
        } else {
            let bitMasks = layerBitMasks(forLevel: 0)
            innerMostLayerPhysicsBody.categoryBitMask = bitMasks.categoryBitMask
            innerMostLayerPhysicsBody.collisionBitMask = bitMasks.collisionBitMask
            innerMostLayerPhysicsBody.contactTestBitMask = bitMasks.contactTestBitMask
        }
    }

    /// Creates the bounding node with the appropriate physics bodies and adds it to the scene
    private func layerNode(radius: CGFloat, level: Int) -> SKNode {
        let boundingNode = SKNode()
        boundingNode.name = Constants.boundingNodeName
        boundingNode.zPosition = 1
        boundingNode.position = center

        boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        boundingNode.physicsBody?.mass = style.nodePhysicsBodyMass
        boundingNode.physicsBody?.isDynamic = false
        boundingNode.physicsBody?.friction = 0
        boundingNode.physicsBody?.restitution = 0
        boundingNode.physicsBody?.linearDamping = 0

        let bitMasks = layerBitMasks(forLevel: level)
        boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
        boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask
        boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask

        scene.addChild(boundingNode)
        return boundingNode
    }

    /// Provides the bitMasks for the bounding node's physics bodies. The bits are offset by 10 in order to make them unique from the level entity's bitMasks.
    private func layerBitMasks(forLevel level: Int) -> ColliderType {
        let levelBit = 10 + level
        let categoryBitMask: UInt32 = 1 << levelBit
        let contactTestBitMask: UInt32 = 1 << levelBit
        let collisionBitMask: UInt32 = 1 << levelBit

        return ColliderType(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }

    private func flatten(_ levels: EntityLevels) -> Set<RecordEntity> {
        return levels.reduce(Set<RecordEntity>()) { return $0.union($1) }
    }

    static func == (lhs: NodeCluster, rhs: NodeCluster) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
