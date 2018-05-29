//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit


class RecordNode: SKSpriteNode {

    private let record: RecordDisplayable


    // MARK: Initializers

    init(record: RecordDisplayable) {
        self.record = record
        super.init(texture: nil, color: .blue, size: .zero)
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Helpers

    private func makeRecordNode() {
        let width: CGFloat = 10
        let height: CGFloat = 10

        size = CGSize(width: width, height: height)

        let border = SKShapeNode(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: frame.width * 0.3)
        border.lineWidth = 1.5
        border.strokeColor = record.type.color
        addChild(border)

        let title = SKLabelNode(text: record.title)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: frame.width / 2, y: 0)
        addChild(title)

        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.position = CGPoint(x: frame.width, y: frame.height)
        addChild(id)
    }







}






