//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class MenuButton: NSView {
    static let nib = NSNib.Name(rawValue: "MenuButton")

    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var lockView: NSView!
    @IBOutlet weak var lockIcon: NSImageView!

    var buttonType: MenuButtonType! {
        didSet {
            setupButton()
        }
    }

    private var toggleStatus: ButtonState = .off


    private struct Constants {
        static let imageTransitionDuration = 0.5
    }



    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        Bundle.main.loadNibNamed(MenuButton.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = bounds

        wantsLayer = true
    }


    // MARK: Setup

    private func setupButton() {
        guard let imageIcon = buttonType.image else {
            return
        }

        layer?.contents = imageIcon
        lockIcon.isHidden = true
    }


    // MARK: API

    func toggle(to status: ButtonState) {
        toggleStatus = status
        let image = status == .on ? buttonType.selectedImage : buttonType.image
        transition(to: image, duration: Constants.imageTransitionDuration)
    }

    func toggleLockIcon(on: Bool) -> Bool {
        guard buttonType.detailImage != nil else {
            return false
        }

        lockIcon.isHidden = !on
        return on
    }
}
