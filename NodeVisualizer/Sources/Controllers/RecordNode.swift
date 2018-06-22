//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKNode {

    private(set) var record: TestingEnvironment.Record

    private struct Constants {
        static let borderCornerRadius: CGFloat = 0.3
        static let centerOffset: CGFloat = 0.2
        static let labelFontSize: CGFloat = 10
    }


    // MARK: Initializers

    init(record: TestingEnvironment.Record) {
        self.record = record
        super.init()
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func runInitialAnimation(with forceVector: CGVector, delay: Int) {
        let dX = forceVector.dx * 0.05
        let dY = forceVector.dy * 0.05
        let force = CGVector(dx: dX, dy: dY)

//        let fadeInAction = SKAction.fadeIn(withDuration: TimeInterval(delay) * 0.01)
        let applyForceAction = SKAction.applyForce(force, duration: 0.1)
//        let groupAction = SKAction.sequence([fadeInAction, applyForceAction])
        run(applyForceAction)
    }


    // MARK: Helpers

    private func makeRecordNode() {
        let rootNode = makeRootNode()
        addIdLabelNode(to: rootNode)
        setupPhysics()
    }

    private func makeRootNode() -> SKShapeNode {
//        let rootNode = SKSpriteNode()
//        rootNode.size = CGSize(width: 20, height: 20)
//        rootNode.color = record.color
//        addChild(rootNode)
//        return rootNode

        let rootNode = SKShapeNode(circleOfRadius: 15)
        rootNode.fillColor = record.color
        addChild(rootNode)
        return rootNode
    }

//    private func addTitleLabelNode(to root: SKNode) {
//        let title = SKLabelNode(text: record.title)
//        title.verticalAlignmentMode = .center
//        title.horizontalAlignmentMode = .center
//        title.position.y = root.frame.height / 2 * Constants.centerOffset
//        title.fontSize = Constants.labelFontSize
//        title.xScale = root.frame.width / title.frame.width
//        title.yScale = title.xScale
//        title.fontColor = .black
//        root.addChild(title)
//    }

    private func addIdLabelNode(to root: SKNode) {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
//        id.position.y = -(root.frame.height / 2 * Constants.centerOffset)
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        root.addChild(id)
    }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 15)
        physicsBody?.friction = 0
        physicsBody?.restitution = 0
        physicsBody?.linearDamping = 0
    }
}
