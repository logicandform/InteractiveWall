//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKSpriteNode {

    private(set) var record: RecordDisplayable

    private struct Constants {
        static let labelFontSize: CGFloat = 10
    }


    // MARK: Initializers

    init(record: RecordDisplayable) {
        self.record = record
        super.init(texture: nil, color: .clear, size: .zero)
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Helpers

    private func makeRecordNode() {
        size = CGSize(width: 20, height: 20)
        color = record.type.color
        addIdLabelNode()
    }

    private func addIdLabelNode() {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        addChild(id)
    }
}
