//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKSpriteNode {

    private(set) var record: RecordDisplayable

    private struct Constants {
        static let labelFontSize: CGFloat = 10
        static let forceMultiplier: CGFloat = 0.5
        static let forceActionDuration: TimeInterval = 0.1
    }


    // MARK: Initializers

    init(record: RecordDisplayable, ofSize size: CGFloat = 20) {
        self.record = record
        super.init(texture: nil, color: .clear, size: .zero)
        makeRecordNode(ofSize: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Helpers

    private func makeRecordNode(ofSize s: CGFloat) {
        size = CGSize(width: s, height: s)
        color = record.type.color

        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        addChild(id)

//        let rootNode = makeRootNode(ofSize: size)
//        addIdLabelNode(to: rootNode)
    }

    private func makeRootNode(ofSize size: CGFloat) -> SKSpriteNode {
        let rootNode = SKSpriteNode()
        rootNode.size = CGSize(width: size, height: size)
        rootNode.color = record.type.color
        addChild(rootNode)
        return rootNode
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
