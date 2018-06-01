//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit


class MainScene: SKScene {

    var records: [RecordDisplayable]!

    private enum StartingPositionType: UInt32 {
        case top = 0
        case bottom = 1
        case left = 2
        case right = 3
    }


    // MARK: Lifecycle
    
    override func didMove(to view: SKView) {

        addRecordNodesToScene()

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = .zero
    }

    override func update(_ currentTime: TimeInterval) {

    }


    // MARK: Helpers

    private func addRecordNodesToScene() {
        records.prefix(10).enumerated().forEach { index, record in
            let node = RecordNode(record: record)
            node.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
            node.zPosition = 1
            node.alpha = 0
            addChild(node)

            let destinationPosition = getRandomPosition()
            let forceVector = CGVector(dx: destinationPosition.x - node.position.x, dy: destinationPosition.y - node.position.y)
            let action = node.createInitialAnimation(with: forceVector)
            node.run(action)
        }

//        let record = records[0]
//        let node = RecordNode(record: record)
////        node.position = getRandomPosition()
//        node.position.x = randomX()
//        node.position.y = randomY()
//        addChild(node)
    }

    private func getRandomPosition() -> CGPoint {
        var point = CGPoint.zero

        guard let position = StartingPositionType(rawValue: arc4random_uniform(4)) else {
            return point
        }

        switch position {
        case .top:
            point = CGPoint(x: randomX(), y: frame.height)
            return point
        case .bottom:
            point = CGPoint(x: randomX(), y: 0)
            return point
        case .left:
            point = CGPoint(x: 0, y: randomY())
            return point
        case .right:
            point = CGPoint(x: frame.width, y: randomY())
            return point
        }
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
