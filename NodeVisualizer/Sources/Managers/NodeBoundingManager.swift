//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    Class that manages the bounding diameter level nodes for the scene.
 */

import Foundation
import SpriteKit
import GameplayKit


final class NodeBoundingManager {

    /// Reference to the scene where we should add the bounding nodes to
    var scene: MainScene!

    /// Dictionary of the bounding invisible node entity for a particular level
    private(set) var nodeBoundingEntityForLevel = [Int: NodeBoundingEntity]()

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
        static let boundingNodeRadiusOffset: CGFloat = 5.0
    }


    // MARK: Singleton instance

    static let instance = NodeBoundingManager()
    private init() { }


    // MARK: API

    /// Updates all component systems that the NodeBoundingManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    /// Creates or removes node bounding entities from the scene depending on the most recently formed EntityManager's entitiesInLevel
    func createNodeBoundingEntities() {
        let entitiesInLevelCount = EntityManager.instance.entitiesInLevel.count
        let nodeBoundingEntityForLevelCount = nodeBoundingEntityForLevel.count

        if entitiesInLevelCount > nodeBoundingEntityForLevelCount {
            createBoundingEntities(forLevels: entitiesInLevelCount)
        } else if entitiesInLevelCount < nodeBoundingEntityForLevelCount {
            removeEntities(ofLevels: entitiesInLevelCount)
        }
    }

    /// Removes all node bounding entities from the scene
    func reset() {
        removeEntities(ofLevels: 0)
    }

    /// Calculates the distance from the root bounding node to the specified entity
    func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = nodeBoundingEntityForLevel[0]?.nodeBoundingRenderComponent.node else {
            return 0.0
        }
        let dX = Float(rootBoundingNode.position.x - entity.renderComponent.recordNode.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.renderComponent.recordNode.position.y)
        return CGFloat(hypotf(dX, dY).magnitude)
    }


    // MARK: Helpers

    /// Creates and adds node bounding entities based on the difference between the `levels` to go to and the current number of elements in nodeBoundingEntityForLevel
    private func createBoundingEntities(forLevels levels: Int) {
        var level = nodeBoundingEntityForLevel.count

        var radius: CGFloat
        if let entity = nodeBoundingEntityForLevel[level - 1] {
            radius = entity.nodeBoundingRenderComponent.maxRadius
        } else {
            radius = NodeConfiguration.Record.physicsBodyRadius + Constants.boundingNodeRadiusOffset
        }

        while level < levels {
            let boundingNode = createBoundingNode(ofRadius: radius, level: level)

            // create node bounding entity
            let nodeBoundingEntity = NodeBoundingEntity()
            nodeBoundingEntity.nodeBoundingRenderComponent.node = boundingNode
            nodeBoundingEntity.nodeBoundingRenderComponent.maxRadius = radius
            nodeBoundingEntity.nodeBoundingRenderComponent.minRadius = radius
            nodeBoundingEntity.nodeBoundingRenderComponent.level = level
            add(nodeBoundingEntity, toLevel: level)

            level += 1
        }
    }

    /// Creates the bounding node with the appropriate physics bodies and adds it to the scene
    private func createBoundingNode(ofRadius radius: CGFloat, level: Int) -> SKNode {
        let boundingNode = SKNode()
        boundingNode.name = Constants.boundingNodeName
        boundingNode.zPosition = 1
        boundingNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)

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

    /// Associates the entity to its level by adding it to the nodeBoundingEntityForLevel. Adds the entity's component to the component system
    private func add(_ entity: NodeBoundingEntity, toLevel level: Int) {
        nodeBoundingEntityForLevel[level] = entity

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    /// Removes node bounding entities down to the specified level. Removes the SKNode from the scene and all the entity's components from the component system
    private func removeEntities(ofLevels levels: Int) {
        var level = nodeBoundingEntityForLevel.count - 1

        while level >= levels {
            if let entityToRemove = nodeBoundingEntityForLevel[level], let nodeToRemove = entityToRemove.nodeBoundingRenderComponent.node {
                nodeToRemove.removeFromParent()
                nodeBoundingEntityForLevel.removeValue(forKey: level)

                for componentSystem in componentSystems {
                    componentSystem.removeComponent(foundIn: entityToRemove)
                }
            }

            level -= 1
        }
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
}
