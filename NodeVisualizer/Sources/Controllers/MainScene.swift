//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var records: [RecordDisplayable]!


    // MARK: Lifecycle
    
    override func didMove(to view: SKView) {

        // scene should manage the different nodes (position, etc) --> all nodes are presented in a scene
        // manages the interaction of the different nodes


        addRecordNodesToScene()

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
//        physicsWorld.gravity = .zero

    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }


    // MARK: Helpers

    private func addRecordNodesToScene() {
        for record in records.prefix(15) {
            let node = RecordNode(record: record)
            node.position.x = randomX()
            node.position.y = randomY()
            addChild(node)
        }

//        let record = records[0]
//        let node = RecordNode(record: record)
//        node.position.x = randomX()
//        node.position.y = randomY()
//
//        addChild(node)
    }

    private func randomX() -> CGFloat {
        let lowestValue = 0
        let highestValue = Int(frame.width)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt())
    }

    private func randomY() -> CGFloat {
        let lowestValue = 0
        let highestValue = Int(frame.height)
        return CGFloat(GKRandomDistribution(lowestValue: lowestValue, highestValue: highestValue).nextInt())
    }

}








