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

    private struct Constants {
        static let textureImageName = "node_circle"
        static let labelFontSize: CGFloat = 30
        static let labelSystemFontSize: CGFloat = 10
        static let buttonSize = CGSize(width: 8, height: 8)
        static let buttonOffset: CGFloat = 44
    }


    // MARK: Initializers

    init(record: Record) {
        self.record = record
        super.init(texture: nil, color: .clear, size: .zero)
        makeNodes(for: record)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    static func bitMasks(forLevel level: Int) -> ColliderType {
        let categoryBitMask: UInt32 = 1 << level
        let collisionBitMask: UInt32 = 1 << level
        let contactTestBitMask: UInt32 = 1 << level

        return ColliderType(
            categoryBitMask: categoryBitMask,
            collisionBitMask: collisionBitMask,
            contactTestBitMask: contactTestBitMask
        )
    }

    /// Sets the zPosition of `self`
    func setZ(level: Int) {
        // Since titles are 1 level above the node, must multiply level by 2 to avoid undefined ordering
        zPosition = CGFloat(20 - level * 2)
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
        texture = SKTexture(imageNamed: record.type.nodeImageName)
        size = style.defaultNodeSize
        downloadImage(for: record)
        addTitleNode(for: record)
        addOpenNode()
        addCloseNode()
    }

    private func downloadImage(for record: Record) {
        guard let media = record.media.first else {
            return
        }

        Alamofire.request(media.thumbnail).responseImage { [weak self] response in
            if let image = response.value {
                let rounded = image.roundedCorners()
                self?.texture = SKTexture(image: rounded)
                self?.colorBlendFactor = 0
            }
        }
    }

    private func addTitleNode(for record: Record) {
        titleNode = SKLabelNode()
        titleNode.text = record.id.description
        titleNode.verticalAlignmentMode = .center
        titleNode.horizontalAlignmentMode = .center
        titleNode.fontSize = Constants.labelFontSize
        titleNode.fontColor = .black
        titleNode.zPosition = 1
        titleNode.fontName = NSFont.boldSystemFont(ofSize: Constants.labelSystemFontSize).fontName
        addChild(titleNode)
    }

    private func addOpenNode() {
        openNode = SKSpriteNode(imageNamed: "open-button")
        openNode.size = Constants.buttonSize
        openNode.position = CGPoint(x: 0, y: -Constants.buttonOffset)
        openNode.zPosition = 1
        openNode.alpha = 0
        addChild(openNode)
    }

    private func addCloseNode() {
        closeNode = SKSpriteNode(imageNamed: "close-button")
        closeNode.size = Constants.buttonSize
        closeNode.position = CGPoint(x: 0, y: Constants.buttonOffset)
        closeNode.zPosition = 1
        closeNode.alpha = 0
        addChild(closeNode)
    }
}

fileprivate extension NSImage {

    func roundedCorners() -> NSImage {
        let length = min(size.width, size.height)
        let rect = NSRect(origin: .zero, size: CGSize(width: length, height: length))
        if let cgImage = cgImage, let context = CGContext(data: nil, width: Int(length), height: Int(length), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) {
            context.beginPath()
            context.addPath(CGPath(roundedRect: rect, cornerWidth: length/2, cornerHeight: length/2, transform: nil))
            context.closePath()
            context.clip()
            context.draw(cgImage, in: rect)

            if let composedImage = context.makeImage() {
                return NSImage(cgImage: composedImage, size: size)
            }
        }

        return self
    }

    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}
