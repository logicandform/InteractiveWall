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

    var gestureManager: GestureManager? {
        didSet {
            setupGestures()
        }
    }

    var record: RecordDisplayable? {
        didSet {
            load(record)
        }
    }

    private var highlighted: Bool = false {
        didSet {
            updateStyle()
        }
    }


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = style.darkBackground.cgColor
        titleLabel?.textColor = .white
        descriptionLabel?.textColor = .white
    }


    // MARK: API

    @IBAction func didTapView(_ sender: Any) {
        didTapItem?()
    }

    func didTapView() {
        highlighted = false
        didTapItem?()
    }


    // MARK: Setup

    private func setupGestures() {
        guard let gestureManager = gestureManager else {
            return
        }

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: self)
        tapGesture.gestureUpdated = handleTapGesture(_:)
    }


    // MARK: Gesture Handling

    private func handleTapGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .began:
            highlighted = true
        case .failed:
            highlighted = false
        case .ended:
            didTapItem?()
            highlighted = false
        default:
            return
        }
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
