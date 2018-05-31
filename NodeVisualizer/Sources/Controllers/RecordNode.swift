//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKNode {

    private let record: RecordDisplayable


    private struct Constants {
        static let borderCornerRadius: CGFloat = 0.3
        static let centerOffset: CGFloat = 0.2
        static let labelFontSize: CGFloat = 13
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

    func createInitialAnimation(with forceVector: CGVector) -> SKAction {
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        let applyImpulseAction = SKAction.applyForce(forceVector, duration: 0.1)
        let groupAction = SKAction.group([fadeInAction, applyImpulseAction])
        return groupAction
    }




    // MARK: Helpers

    private func makeRecordNode() {
        let rootNode = makeRootNode()

        addTitleLabelNode(to: rootNode)
        addIdLabelNode(to: rootNode)

        physicsBody = SKPhysicsBody(rectangleOf: calculateAccumulatedFrame().size)
        physicsBody?.friction = 0.5
        physicsBody?.restitution = 0.8
        physicsBody?.linearDamping = 0
    }

    private func makeRootNode() -> SKNode {
        let rootNode = SKSpriteNode()
        rootNode.size = CGSize(width: 50, height: 50)
        rootNode.color = record.type.color
        addChild(rootNode)
        return rootNode
    }

    private func addTitleLabelNode(to root: SKNode) {
        let title = SKLabelNode(text: record.title)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position.y = root.frame.height / 2 * Constants.centerOffset
        title.fontSize = Constants.labelFontSize
        title.xScale = root.frame.width / title.frame.width
        title.yScale = title.xScale
        title.fontColor = .black
        root.addChild(title)
    }

    private func addIdLabelNode(to root: SKNode) {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.position.y = -(root.frame.height / 2 * Constants.centerOffset)
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        root.addChild(id)
    }




}









