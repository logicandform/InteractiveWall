//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKSpriteNode {

    private(set) var record: RecordDisplayable

    private struct Constants {
        static let textureImageName = "node_circle"
        static let labelFontSize: CGFloat = 30
        static let labelSystemFontSize: CGFloat = 10
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
        size = style.defaultNodeSize
        texture = SKTexture(imageNamed: Constants.textureImageName)
        color = record.type.color
        colorBlendFactor = 1
        zPosition = 1
        addIdLabelNode()
    }

    private func addIdLabelNode() {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.fontSize = Constants.labelFontSize
        id.fontColor = .black
        id.fontName = NSFont.boldSystemFont(ofSize: Constants.labelSystemFontSize).fontName
        id.zPosition = 2
        addChild(id)
    }
}
