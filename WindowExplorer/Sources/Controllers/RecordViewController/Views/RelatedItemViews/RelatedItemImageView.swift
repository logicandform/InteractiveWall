//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RelatedItemImageView: RelatedItemView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItemImageView")

    @IBOutlet weak var videoIconImageView: NSImageView! {
        didSet {
            setupVideoIcon()
        }
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer?.borderWidth = style.windowHighlightWidth
    }


    // MARK: Overrides

    override func set(highlighted: Bool) {
        if highlighted {
            view.layer?.borderColor = tintColor.cgColor
        } else {
            view.layer?.borderColor = style.defaultBorderColor.cgColor
        }
    }

    override func load(_ record: Record) {
        super.load(record)

        videoIconImageView.isHidden = filterType != .video
    }


    // MARK: Setup

    private func setupVideoIcon() {
        videoIconImageView.wantsLayer = true
        videoIconImageView.layer?.cornerRadius = videoIconImageView.frame.width/2
        videoIconImageView.layer?.backgroundColor = style.darkBackground.cgColor
    }
}
