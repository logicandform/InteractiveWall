//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


// Class that manages the bounding diameter level nodes for the scene
final class NodeBoundingManager {

    static let instance = NodeBoundingManager()

    var scene: MainScene!

    /// The center root bounding node that "contains" the tapped entity node
    private(set) var rootBoundingNode: SKNode?

    /// Dictionary of the bounding invisible node for a particular level
    private(set) var boundingNodesForLevel = [Int: SKNode]()

    private var nodeBoundingEntities = [NodeBoundingEntity]()

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
    }


    // Use singleton instance
    private init() { }


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    func createRootSeekNodeBoundingEntity() {
        let rootSeekNode = SKShapeNode(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        rootSeekNode.name = Constants.boundingNodeName
        rootSeekNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)

        rootSeekNode.physicsBody = SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        rootSeekNode.physicsBody?.isDynamic = false

        rootSeekNode.physicsBody?.collisionBitMask = 0x1 << 0
        rootSeekNode.physicsBody?.contactTestBitMask = 0x1 << 0
        rootSeekNode.physicsBody?.categoryBitMask = 0x1 << 0

        rootBoundingNode = rootSeekNode
        scene.addChild(rootSeekNode)

        let rootSeekNodeBoundingEntity = NodeBoundingEntity()
        rootSeekNodeBoundingEntity.nodeBoundingRenderComponent.node = rootSeekNode
        nodeBoundingEntities.append(rootSeekNodeBoundingEntity)
    }

    func createNodeBoundingEntities() {
        let entitiesInLevel = EntityManager.instance.entitiesInLevel
        createBoundingEntities(forLevels: entitiesInLevel.count)

        for (level, entities) in entitiesInLevel.enumerated() {
            guard let nodeBoundingEntity = nodeBoundingEntities.at(index: level) else { continue }
            nodeBoundingEntity.nodeBoundingRenderComponent.contactEntities = entities

            if let contactEntitiesBoundingEntity = nodeBoundingEntities.at(index: level + 1) {
                nodeBoundingEntity.nodeBoundingRenderComponent.contactEntitiesBoundingEntity = contactEntitiesBoundingEntity
            }
        }
    }


    // MARK: Helpers

    private func createBoundingEntities(forLevels levels: Int) {
        var level = 1
        let radius = NodeConfiguration.Record.physicsBodyRadius * 8

        while level < levels {
            let boundingNode = SKShapeNode(circleOfRadius: radius)
            boundingNode.name = Constants.boundingNodeName
            boundingNode.zPosition = 1
            boundingNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)

            boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            boundingNode.physicsBody?.mass = NodeConfiguration.Record.physicsBodyMass
            boundingNode.physicsBody?.isDynamic = false

            let bitMasks = boundingNodeBitMasks(forLevel: level)
            boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
            boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask
            boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask

            scene.addChild(boundingNode)

            let nodeBoundingEntity = NodeBoundingEntity()
            nodeBoundingEntity.nodeBoundingRenderComponent.node = boundingNode
            nodeBoundingEntities.append(nodeBoundingEntity)

            for componentSystem in componentSystems {
                componentSystem.addComponent(foundIn: nodeBoundingEntity)
            }

            level += 1
        }
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

    private func distance(to entity: RecordEntity) -> CGFloat {
        guard let rootBoundingNode = rootBoundingNode else {
            return 0.0
        }
        let dX = Float(rootBoundingNode.position.x - entity.renderComponent.recordNode.position.x)
        let dY = Float(rootBoundingNode.position.y - entity.renderComponent.recordNode.position.y)
        return CGFloat(hypotf(dX, dY))
    }


}
