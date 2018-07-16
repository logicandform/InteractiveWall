//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


// Class that manages the bounding diameter level nodes for the scene
final class NodeBoundingManager {

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

    static let instance = NodeBoundingManager()


    // Use singleton instance
    private init() { }


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    func createNodeBoundingEntities() {
        let entitiesInLevel = EntityManager.instance.entitiesInLevel
        createBoundingEntities(forLevels: entitiesInLevel.count)

        for (level, _) in entitiesInLevel.enumerated() {
            guard let nodeBoundingEntity = nodeBoundingEntityForLevel[level] else { continue }
            nodeBoundingEntity.nodeBoundingRenderComponent.level = level
        }
    }

    func testNewStructure() {
        let entitiesInLevelCount = EntityManager.instance.entitiesInLevel.count
        let nodeBoundingEntityForLevelCount = nodeBoundingEntityForLevel.count

        if entitiesInLevelCount > nodeBoundingEntityForLevelCount {
            createBoundingEntitiesTest(forLevels: entitiesInLevelCount)

            for (level, _) in EntityManager.instance.entitiesInLevel.enumerated() {
                guard let nodeBoundingEntity = nodeBoundingEntityForLevel[level] else { continue }
                nodeBoundingEntity.nodeBoundingRenderComponent.level = level
            }

        } else if entitiesInLevelCount < nodeBoundingEntityForLevelCount {
            removeEntities(ofLevels: entitiesInLevelCount)
        }
    }

    func reset() {
        // reset necessary variables when tapping on a completely new unrelated node
    }

    func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = nodeBoundingEntityForLevel[0]?.nodeBoundingRenderComponent.node else {
            return 0.0
        }
        let dX = Float(rootBoundingNode.position.x - entity.renderComponent.recordNode.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.renderComponent.recordNode.position.y)
        return CGFloat(hypotf(dX, dY).magnitude)
    }


    // MARK: Helpers

    private func createBoundingEntitiesTest(forLevels levels: Int) {
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
            add(nodeBoundingEntity, toLevel: level)

            level += 1
        }
    }

    private func add(_ entity: NodeBoundingEntity, toLevel level: Int) {
        nodeBoundingEntityForLevel[level] = entity

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

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



    private func createBoundingEntities(forLevels levels: Int) {
        var level = 0
        let radius = NodeConfiguration.Record.physicsBodyRadius + Constants.boundingNodeRadiusOffset

        while level < levels {
            let boundingNode = createBoundingNode(ofRadius: radius, level: level)

            // create node bounding entity
            let nodeBoundingEntity = NodeBoundingEntity()
            nodeBoundingEntity.nodeBoundingRenderComponent.node = boundingNode
            nodeBoundingEntity.nodeBoundingRenderComponent.maxRadius = radius
            nodeBoundingEntityForLevel[level] = nodeBoundingEntity

            for componentSystem in componentSystems {
                componentSystem.addComponent(foundIn: nodeBoundingEntity)
            }

            level += 1
        }
    }

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

    private func boundingNodeBitMasks(forLevel level: Int) -> BoundingNodeBitMasks {
        let categoryBitMask: UInt32 = 0x1 << level
        let contactTestBitMask: UInt32 = 0x1 << level
        let collisionBitMask: UInt32 = 0x1 << level

        return BoundingNodeBitMasks(
            categoryBitMask: categoryBitMask,
            contactTestBitMask: contactTestBitMask,
            collisionBitMask: collisionBitMask
        )
    }
}
