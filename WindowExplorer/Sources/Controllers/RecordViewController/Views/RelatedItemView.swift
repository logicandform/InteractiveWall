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

    var didTapItem: ((RecordDisplayable) -> Void)?

    var record: RecordDisplayable? {
        didSet {
            load(record)
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


    // MARK: IB-Actions

    @IBAction func didTapView(_ sender: Any) {
        if let record = record {
            didTapItem?(record)
        }
    }


    // MARK: Helpers

    private func load(_ record: RecordDisplayable?) {
        guard let record = record else {
            return
        }

        titleLabel.stringValue = record.title
        descriptionLabel.stringValue = record.description ?? ""
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
