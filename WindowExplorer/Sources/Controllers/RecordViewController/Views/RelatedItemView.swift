//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class RelatedItemView: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemView")
    static let nibName = NSNib.Name(rawValue: "RelatedItemView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionView: NSTextView!
    @IBOutlet weak var imageView: AspectFillImage!

    var tintColor = style.selectedColor
    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    private struct Constants {
        static let fontName = "Soleil"
        static let titleFontName = "Soleil-Bold"
        static let fontColor: NSColor = .white
        static let kern: CGFloat = 1.0
        static let titleFontSize: CGFloat = 11
        static let descriptionFontSize: CGFloat = 10
    }
    
    private var titleLabelAttributes : [NSAttributedStringKey : Any] {
        get {
            let font = NSFont(name: Constants.titleFontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingTail
            return [.paragraphStyle : paragraphStyle,
                    .kern : Constants.kern,
                    .foregroundColor : Constants.fontColor,
                    .font : font]
        }
    }
    
    private var descriptionLabelAttributes : [NSAttributedStringKey : Any] {
        get {
            let font = NSFont(name: Constants.fontName, size: Constants.descriptionFontSize) ?? NSFont.systemFont(ofSize: Constants.descriptionFontSize)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byCharWrapping
            paragraphStyle.paragraphSpacing = 0.0
            paragraphStyle.paragraphSpacingBefore = 0.0
            return [.paragraphStyle : paragraphStyle,
                    .kern : Constants.kern,
                    .foregroundColor : Constants.fontColor,
                    .font : font,
                    .baselineOffset : 0.0]
        }
    }

    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            layer?.backgroundColor = tintColor.cgColor
        } else {
            layer?.backgroundColor = style.darkBackground.cgColor
        }
    }


    // MARK: Helpers

    private func load(_ record: RecordDisplayable?) {
        guard let record = record else {
            return
        }

        descriptionView.drawsBackground = false
        descriptionView.textContainer?.maximumNumberOfLines = 3
        titleLabel.attributedStringValue = NSAttributedString(string: record.title, attributes: titleLabelAttributes)
        descriptionView.textStorage?.setAttributedString(NSAttributedString(string: record.description ?? "", attributes: descriptionLabelAttributes))
        imageView.set(record.type.placeholder.tinted(with: record.type.color), scaling: .resize)

        if let media = record.media.first {
            Alamofire.request(media.thumbnail).responseImage { [weak self] response in
                if let image = response.value {
                    self?.imageView.set(image)
                }
            }
        }
    }
}
