//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class RelatedItemView: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemView")
    static let nibName = NSNib.Name(rawValue: "RelatedItemView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var imageView: AspectFillImageView!

    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    private struct Constants {
        static let fontName = "Soleil"
        static let fontColor: NSColor = .white
        static let kern: CGFloat = 0.5
        static let titleFontSize: CGFloat = 11
        static let descriptionFontSize: CGFloat = 9
    }
    
    private var titleLabelAttributes : [NSAttributedStringKey : Any] {
        get {
            let font = NSFont(name: Constants.fontName, size: Constants.titleFontSize) ?? NSFont.systemFont(ofSize: Constants.titleFontSize)
            return [.kern : Constants.kern,
                    .foregroundColor : Constants.fontColor,
                    .font : font]
        }
    }
    
    private var descriptionLabelAttributes : [NSAttributedStringKey : Any] {
        get {
            let font = NSFont(name: Constants.fontName, size: Constants.descriptionFontSize) ?? NSFont.systemFont(ofSize: Constants.descriptionFontSize)
            return [.kern : Constants.kern,
                    .foregroundColor : Constants.fontColor,
                    .font : font]
        }
    }

    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        set(highlighted: false)

        titleLabel?.textColor = .white
        descriptionLabel?.textColor = .white
    }

    // MARK: API
    func set(highlighted: Bool) {
        if highlighted {
            layer?.backgroundColor = style.selectedColor.cgColor
        } else {
            layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    // MARK: Helpers

    private func load(_ record: RecordDisplayable?) {
        guard let record = record else {
            return
        }

        titleLabel.attributedStringValue = NSAttributedString(string: record.title, attributes: titleLabelAttributes)
        descriptionLabel.attributedStringValue = NSAttributedString(string: record.description ?? "", attributes: descriptionLabelAttributes)
        imageView.image = record.type.placeholder.tinted(with: style.relatedItemColor)

        if let media = record.media.first {
            Alamofire.request(media.thumbnail).responseImage { [weak self] response in
                if let image = response.value {
                    self?.imageView.image = image
                }
            }
        }
    }
}
