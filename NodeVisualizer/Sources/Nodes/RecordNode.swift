//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import Alamofire
import AlamofireImage

class RecordNode: SKSpriteNode {

    private(set) var record: Record
    private(set) var titleNode: SKLabelNode!

    private struct Constants {
        static let textureImageName = "node_circle"
        static let labelFontSize: CGFloat = 30
        static let labelSystemFontSize: CGFloat = 10
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


    // MARK: Helpers

    private func makeNodes(for record: Record) {
        texture = SKTexture(imageNamed: Constants.textureImageName)
        color = record.type.color
        colorBlendFactor = 1
        size = style.defaultNodeSize
        zPosition = 1
        addTitleNode(for: record)
        addImageNode(for: record)
    }

    private func addImageNode(for record: Record) {
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
        titleNode.fontName = NSFont.boldSystemFont(ofSize: Constants.labelSystemFontSize).fontName
        titleNode.zPosition = 2
        addChild(titleNode)
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
