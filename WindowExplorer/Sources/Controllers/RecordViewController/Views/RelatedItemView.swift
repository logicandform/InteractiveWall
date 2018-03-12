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

    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    var didTapItem: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = style.darkBackground.cgColor
        titleLabel?.textColor = .white
        descriptionLabel?.textColor = .white
    }

    @IBAction func didTapView(_ sender: Any) {
        indicateTap()
        didTapItem?()
    }

    func didTapView() {
        indicateTap()
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

    private func indicateTap() {
        layer?.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        }
    }
}