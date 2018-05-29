//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit


class RecordNode: SKNode {

    private let record: RecordDisplayable


    // MARK: Initializers

    init(record: RecordDisplayable) {
        self.record = record
        super.init()
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Helpers

    private func makeRecordNode() {
        let root = SKSpriteNode()
        root.size = CGSize(width: 50, height: 50)
        addChild(root)

        let border = SKShapeNode(rectOf: root.size, cornerRadius: root.frame.width * 0.3)
        border.strokeColor = record.type.color
        root.addChild(border)

        let title = SKLabelNode(text: record.title)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: (root.frame.height / 2 * 0.2))
        title.fontSize = 13
        title.xScale = root.frame.width / title.frame.width
        title.yScale = title.xScale
        root.addChild(title)

        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.position = CGPoint(x: 0, y: -(root.frame.height / 2 * 0.2))
        id.fontSize = 13
        root.addChild(id)
    }







}






