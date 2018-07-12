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

        for (level, entities) in entitiesInLevel.enumerated() {
            guard let nodeBoundingEntity = nodeBoundingEntityForLevel[level] else { continue }
            nodeBoundingEntity.nodeBoundingRenderComponent.contactEntities = entities

            if let previousNodeBoundingEntity = nodeBoundingEntityForLevel[level - 1] {
                nodeBoundingEntity.nodeBoundingRenderComponent.previousNodeBoundingEntity = previousNodeBoundingEntity
            }
        }
    }

    func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = nodeBoundingEntityForLevel[0]?.nodeBoundingRenderComponent.node else {
            return 0.0
        }
        let dX = Float(rootBoundingNode.position.x - entity.renderComponent.recordNode.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.renderComponent.recordNode.position.y)
        return CGFloat(hypotf(dX, dY))
    }


    // MARK: Helpers

    private func createBoundingEntities(forLevels levels: Int) {
        var level = 0
        var radius = NodeConfiguration.Record.physicsBodyRadius + Constants.boundingNodeRadiusOffset

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

            // update the minimum radius to be able to hold one full node plus an offset
//            radius += (NodeConfiguration.Record.physicsBodyRadius * 2) + Constants.boundingNodeRadiusOffset
            level += 1
        }
    }

    private func createBoundingNode(ofRadius radius: CGFloat, level: Int) -> SKNode {
        let boundingNode = SKShapeNode(circleOfRadius: radius)
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
