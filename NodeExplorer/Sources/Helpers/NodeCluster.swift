//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


typealias EntityLevels = [Set<RecordEntity>]


/// Class that creates layers for a selected entity.
final class NodeCluster: NSObject {
    static let selectedEntityLevel = -1
    static let maxRelatedLevels = 4

    let id: Int
    private(set) var center: CGPoint
    private(set) var selectedEntity: RecordEntity
    private(set) var entitiesForLevel = EntityLevels()
    private(set) var layerForLevel = [Int: ClusterLayer]()
    private unowned var scene: MainScene
    private weak var closeTimer: Foundation.Timer?

    private lazy var componentSystems: [GKComponentSystem] = {
        let renderSystem = GKComponentSystem(componentClass: LayerRenderComponent.self)
        return [renderSystem]
    }()


    // MARK: Init

    init(id: Int, scene: MainScene, entity: RecordEntity) {
        self.id = id
        self.scene = scene
        self.selectedEntity = entity
        self.center = selectedEntity.position
        super.init()
        self.resetCloseTimer()
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
        resetCloseTimer()
        attach(to: entity)
        setLayers(toLevel: entitiesForLevel.count - 1)
        updateStatesForEntities()
    }

    /// Updates the layers in the cluster for when the selected entity is panning
    func updateLayerLevels(forPan pan: Bool) {
        if pan {
            closeTimer?.invalidate()
            setLayers(toLevel: 0)
        } else {
            resetCloseTimer()
            removeLayer(level: 0)
            setLayers(toLevel: entitiesForLevel.count - 1)
        }

        for entities in entitiesForLevel {
            for entity in entities {
                entity.hasCollidedWithLayer = false
                entity.updateBitMasks()
            }
        }
    }

    /// Updates center point and bounding nodes to the new panned position
    func set(position: CGPoint) {
        center = position
        for (_, layer) in layerForLevel {
            layer.renderComponent.layerNode.position = position
        }
    }

    /// Removes all entities currently formed in the cluster and removes all bounding layers
    func reset() {
        // Reset all entities
        EntityManager.instance.release(selectedEntity)
        selectedEntity.cluster = nil
        for level in entitiesForLevel {
            for entity in level {
                entity.cluster = nil
                if entity.state != .dragging {
                    EntityManager.instance.release(entity)
                }
            }
        }

        // Remove all layers
        for (level, _) in layerForLevel.enumerated() {
            removeLayer(level: level)
        }
    }

    /// Calculates the distance from the center of self to the specified entity
    func distance(to entity: RecordEntity) -> CGFloat {
        let dX = Float(center.x - entity.position.x)
        let dY = Float(center.y - entity.position.y)
        return CGFloat(hypotf(dX, dY).magnitude)
    }

    /// Determines if the node for the given entity interests with the clusters max radius
    func intersects(_ entity: RecordEntity) -> Bool {
        guard let clusterRadius = layerForLevel[layerForLevel.count - 1]?.renderComponent.maxRadius else {
            return false
        }

        let nodeRadius = entity.node.frame.width / 2
        let result = distance(to: entity) <= clusterRadius + nodeRadius
        return result
    }

    /// Calculates the distance between two points
    func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }

    /// Returns the level for the given entity
    func level(for entity: RecordEntity) -> Int? {
        for (level, entities) in entitiesForLevel.enumerated() {
            if entities.contains(entity) {
                return level
            }
        }

        return nil
    }

    static func sizeFor(level: Int?) -> CGSize {
        guard let level = level else {
            return style.defaultNodeSize
        }

        switch level {
        case -1:
            return style.selectedNodeSize
        case 0:
            return style.levelZeroNodeSize
        case 1:
            return style.levelOneNodeSize
        case 2:
            return style.levelTwoNodeSize
        case 3:
            return style.levelThreeNodeSize
        case 4:
            return style.levelFourNodeSize
        default:
            return style.defaultNodeSize
        }
    }

    func resetCloseTimer() {
        closeTimer?.invalidate()
        closeTimer = Timer.scheduledTimer(withTimeInterval: Configuration.clusterTimeoutDuration, repeats: false) { [weak self] _ in
            self?.closeTimerFired()
        }
    }

    /// Determines if a certain level should show or hide its title
    static func showTitleFor(level: Int) -> Bool {
        return level < 1
    }

    static func showIconFor(level: Int) -> Bool {
        return level > 0
    }


    // MARK: Helpers

    /// Requests all entities for related records of the given entity. Sets their `cluster` to `self`.
    private func attach(to entity: RecordEntity) {
        let currentEntities = flatten(entitiesForLevel).union([selectedEntity])
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
        selectedEntity.set(state: .selected)

        // Update the tapped entity's descendants to the appropriate state with appropriate movement
        for (level, entities) in entitiesForLevel.enumerated() {
            for entity in entities {
                if entity.state != .dragging {
                    entity.set(state: .seekLevel(level))
                }
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
        let radius = layerForLevel[level - 1]?.renderComponent.maxRadius
        let layer = ClusterLayer(level: level, radius: radius, cluster: self, center: center)

        layerForLevel[level] = layer
        scene.addChild(layer.renderComponent.layerNode)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: layer)
        }
    }

    /// Removes layer and its components from the cluster
    private func removeLayer(level: Int) {
        guard let layer = layerForLevel[level] else {
            return
        }

        layer.renderComponent.layerNode.removeFromParent()
        layerForLevel.removeValue(forKey: level)
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: layer)
        }
    }

    private func flatten(_ levels: EntityLevels) -> Set<RecordEntity> {
        return levels.reduce(Set<RecordEntity>()) { return $0.union($1) }
    }

    private func closeTimerFired() {
        scene.remove(cluster: self)
    }

    static func == (lhs: NodeCluster, rhs: NodeCluster) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
