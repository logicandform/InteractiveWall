//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


// Class that manages the bounding diameter level nodes for the scene
final class NodeBoundingManager {

    static let instance = NodeBoundingManager()

    var scene: MainScene!

    private var boundingNodes = Set<SKNode>()
    private var boundingNodesForLevel = [Int: SKNode]()

    private struct BoundingNodeBitMasks {
        let categoryBitMask: UInt32
        let contactTestBitMask: UInt32
        let collisionBitMask: UInt32
    }


    // Use singleton instance
    private init() { }


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {

    }

    func createSeekNode() {
        let seekNode = SKShapeNode(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        seekNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)
//        seekNode.isHidden = true

        seekNode.physicsBody = SKPhysicsBody(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius + 5.0)
        seekNode.physicsBody?.isDynamic = false

        seekNode.physicsBody?.collisionBitMask = 0x1 << 0
        seekNode.physicsBody?.contactTestBitMask = 0x1 << 0
        seekNode.physicsBody?.categoryBitMask = 0x1 << 0

        boundingNodes.insert(seekNode)
        scene.addChild(seekNode)
    }

    func createInitialBoundingNodes(forLevels levels: Int) {
        var level = 1
        var radius: CGFloat = 20 + NodeConfiguration.Record.physicsBodyRadius * 4

        while level < levels {
            let boundingNode = SKShapeNode(circleOfRadius: radius)
            boundingNode.position = CGPoint(x: scene.frame.width / 2, y: scene.frame.height / 2)
//            boundingNode.isHidden = true

            boundingNode.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            boundingNode.physicsBody?.isDynamic = false

            let bitMasks = boundingNodeBitMasks(forLevel: level)
            boundingNode.physicsBody?.categoryBitMask = bitMasks.categoryBitMask
            boundingNode.physicsBody?.collisionBitMask = bitMasks.collisionBitMask
            boundingNode.physicsBody?.contactTestBitMask = bitMasks.contactTestBitMask

            boundingNodesForLevel[level] = boundingNode
            scene.addChild(boundingNode)

            radius += NodeConfiguration.Record.physicsBodyRadius * 4
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


}
