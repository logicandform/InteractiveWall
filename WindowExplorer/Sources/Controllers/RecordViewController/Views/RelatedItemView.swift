//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Alamofire
import AlamofireImage

class RelatedItemView: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemView")
    static let nibName = NSNib.Name(rawValue: "RelatedItemView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var descriptionLabel: NSTextField!
    @IBOutlet weak var imageView: NSImageView!

    var didTapItem: (() -> Void)?

    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    var highlighted: Bool = false {
        didSet {
            updateStyle()
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = style.darkBackground.cgColor
        titleLabel?.textColor = .white
        descriptionLabel?.textColor = .white
    }

    @IBAction func didTapView(_ sender: Any) {
        didTapItem?()
    }

    func didTapView() {
        highlighted = false
        didTapItem?()
    }


    // MARK: Helpers

    private func load(_ record: RecordDisplayable?) {
        guard let record = record else {
            return
        }

        titleLabel.stringValue = record.title
        descriptionLabel.stringValue = record.description ?? "no description"

        if let url = record.thumbnail {
            Alamofire.request(url).responseImage { [weak self] response in
                if let image = response.value {
                    self?.imageView.image = image
                }
            }
        }
    }

    private func updateStyle() {
        if highlighted {
            layer?.backgroundColor = style.selectedColor.cgColor
        } else {
            layer?.backgroundColor = style.darkBackground.cgColor
        }
    }
}
