//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKNode {

    private(set) var record: RecordDisplayable

    private struct Constants {
        static let labelFontSize: CGFloat = 10
        static let forceMultiplier: CGFloat = 0.5
        static let forceActionDuration: TimeInterval = 0.1
    }


    // MARK: Initializers

    init(record: RecordDisplayable) {
        self.record = record
        super.init()
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func runInitialAnimation(with forceVector: CGVector, delay: Int) {
        let dX = forceVector.dx * Constants.forceMultiplier
        let dY = forceVector.dy * Constants.forceMultiplier
        let force = CGVector(dx: dX, dy: dY)

        let applyForceAction = SKAction.applyForce(force, duration: Constants.forceActionDuration)
        run(applyForceAction)
    }


    // MARK: Helpers

    private func makeRecordNode() {
        let rootNode = makeRootNode()
        addIdLabelNode(to: rootNode)
    }

    private func makeRootNode() -> SKNode {
        let rootNode = SKSpriteNode()
        rootNode.size = CGSize(width: 20, height: 20)
        rootNode.color = record.type.color
        addChild(rootNode)
        return rootNode

//        let rootNode = SKShapeNode(circleOfRadius: NodeConfiguration.Record.physicsBodyRadius)
//        rootNode.fillColor = record.type.color
//        addChild(rootNode)
//        return rootNode
    }

    private func addIdLabelNode(to root: SKNode) {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        root.addChild(id)
    }
}
