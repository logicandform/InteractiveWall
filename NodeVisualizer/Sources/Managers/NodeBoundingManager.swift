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

    private var elapsedTime: TimeInterval = 0.0

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
        elapsedTime += deltaTime

        if elapsedTime > 5 {

            // check the distance between the rootBoundingNode and entities in each level
            // scale the appropriate boundingNodeForLevel

            let entitiesInLevel = EntityManager.instance.entitiesInLevel

            for (level, entities) in entitiesInLevel.enumerated() {
                var maximumRadius: CGFloat = 0.0

                for case let entity in entities where entity.hasCollidedWithBoundingNode {
                    let radius = distance(to: entity)
                    if radius > maximumRadius {
                        maximumRadius = radius
                    }
                }

                if let boundingNode = boundingNodesForLevel[level + 1] {
                    let currentBoundingNodeRadius = (boundingNode.frame.height / 2)
                    let newBoundingNodeRadius = maximumRadius + NodeConfiguration.Record.physicsBodyRadius * 4

                    let scale = newBoundingNodeRadius / currentBoundingNodeRadius
                    boundingNode.setScale(scale)
//                    let scaleAction = SKAction.scale(by: scale, duration: 0.001)
//                    boundingNode.run(scaleAction)
                }

            }

            elapsedTime = 0.0
        }
    }

    func createSeekNode() {
        let seekNode = SKShapeNode(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        seekNode.name = Constants.boundingNodeName
        seekNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)
//        seekNode.isHidden = true

        seekNode.physicsBody = SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        seekNode.physicsBody?.isDynamic = false

        seekNode.physicsBody?.collisionBitMask = 0x1 << 0
        seekNode.physicsBody?.contactTestBitMask = 0x1 << 0
        seekNode.physicsBody?.categoryBitMask = 0x1 << 0

        rootBoundingNode = seekNode
        boundingNodesForLevel[0] = seekNode
        scene.addChild(seekNode)
    }

    func createInitialBoundingNodes(forLevels levels: Int) {
        var level = 1
        var radius: CGFloat = 20 + NodeConfiguration.Record.physicsBodyRadius * 14

        while level < levels {
            let boundingNode = SKShapeNode(circleOfRadius: radius)
            boundingNode.name = Constants.boundingNodeName
            boundingNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)
//            boundingNode.isHidden = true

            boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            boundingNode.physicsBody?.mass = NodeConfiguration.Record.physicsBodyMass
            boundingNode.physicsBody?.isDynamic = false

            let bitMasks = boundingNodeBitMasks(forLevel: level)
            boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
            boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask
            boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask

            boundingNodesForLevel[level] = boundingNode
            scene.addChild(boundingNode)

            radius += NodeConfiguration.Record.physicsBodyRadius * 14
            level += 1
        }
    }


    // MARK: Helpers

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
