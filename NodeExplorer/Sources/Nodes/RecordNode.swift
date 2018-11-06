//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import Alamofire
import AlamofireImage


class RecordNode: SKSpriteNode {

    private(set) var record: Record
    private(set) var titleNode: SKLabelNode!
    private(set) var closeNode: SKSpriteNode!
    private(set) var openNode: SKSpriteNode!
    private(set) var iconNode: SKSpriteNode!

    private struct Constants {
        static let circleTextureImage = "layer-node"
        static let labelSystemFontSize: CGFloat = 4
        static let buttonSize = CGSize(width: 8, height: 8)
        static let buttonOffset: CGFloat = 40
        static let imageColorBlendPercent: CGFloat = 0.75
        static let wordsPerTitle = 6
        static let textInsetMargin: CGFloat = 20
    }


    // MARK: Initializers

    init(record: Record) {
        self.record = record
        super.init(texture: SKTexture(imageNamed: Constants.circleTextureImage), color: record.type.color, size: style.defaultNodeSize)
        makeNodes(for: record)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setZ(level: Int, clusterID: Int) {
        // Account for negative levels (dragging and selected)
        let base = max(0, level + 1)
        let clusterOffset = (clusterID + 1) * 10
        zPosition = CGFloat(clusterOffset - base)
    }

    func closeButton(contains point: CGPoint) -> Bool {
        let pointFromCenter = point.transformed(to: frame) - CGPoint(x: frame.width/2, y: frame.height/2)
        let pointInNode = CGPoint(x: pointFromCenter.x / xScale, y: pointFromCenter.y / yScale)
        return closeNode.frame.contains(pointInNode)
    }

    func openButton(contains point: CGPoint) -> Bool {
        let pointFromCenter = point.transformed(to: frame) - CGPoint(x: frame.width/2, y: frame.height/2)
        let pointInNode = CGPoint(x: pointFromCenter.x / xScale, y: pointFromCenter.y / yScale)
        return openNode.frame.contains(pointInNode)
    }


    // MARK: Overrides

    /// Returns true if a point is within the current radius from the center of `self`
    override func contains(_ p: CGPoint) -> Bool {
        let dX = Float(position.x - p.x)
        let dY = Float(position.y - p.y)
        return CGFloat(hypotf(dX, dY).magnitude) <= size.width/2
    }


    // MARK: Helpers

    private func makeNodes(for record: Record) {
        colorBlendFactor = 1
        addBackgroundNode()
        addTitleNode(for: record)
        addOpenNode()
        addCloseNode()
        addIconNode(for: record)
    }

    private func addBackgroundNode() {
        let texture = SKTexture(imageNamed: Constants.circleTextureImage)
        let node = SKSpriteNode(texture: texture, color: .black, size: CGSize(width: frame.width - 5, height: frame.height - 5))
        node.colorBlendFactor = 1
        addChild(node)
    }

    private func addTitleNode(for record: Record) {
        titleNode = SKLabelNode()
        titleNode.text = title(for: record)
        titleNode.numberOfLines = 3
        titleNode.lineBreakMode = .byClipping
        titleNode.preferredMaxLayoutWidth = frame.width - Constants.textInsetMargin
        titleNode.verticalAlignmentMode = .center
        titleNode.horizontalAlignmentMode = .center
        titleNode.fontColor = .white
        titleNode.fontSize = 10
        titleNode.fontName = "Soleil"
        addChild(titleNode)
    }

    private func addIconNode(for record: Record) {
        let texture = SKTexture(image: record.type.placeholder.tinted(with: record.type.color))
        iconNode = SKSpriteNode(texture: texture)
        iconNode.alpha = 0
        iconNode.size = frame.size
        addChild(iconNode)
    }

    private func addOpenNode() {
        openNode = SKSpriteNode(imageNamed: "open-button")
        openNode.size = Constants.buttonSize
        openNode.position = CGPoint(x: 0, y: -Constants.buttonOffset)
        openNode.alpha = 0
        addChild(openNode)
    }

    private func addCloseNode() {
        closeNode = SKSpriteNode(imageNamed: "close-button")
        closeNode.size = Constants.buttonSize
        closeNode.position = CGPoint(x: 0, y: Constants.buttonOffset)
        closeNode.alpha = 0
        addChild(closeNode)
    }

    private func title(for record: Record) -> String {
        let words = record.shortestTitle().split(separator: " ")
        let firstSix = words.prefix(Constants.wordsPerTitle)
        let title = firstSix.joined(separator: " ")
        if words.count > Constants.wordsPerTitle {
            return title.appending(" ...")
        }
        return title
    }
}
