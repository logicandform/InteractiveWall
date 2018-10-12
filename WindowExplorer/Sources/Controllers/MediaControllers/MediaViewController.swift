//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class MediaViewController: BaseViewController {

    var media: Media!


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }


    // MARK: Setup

    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        view.addBordersUnderHighlight()
        windowDragAreaHighlight.layer?.backgroundColor = media.tintColor.cgColor
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: style.windowTitleAttributes)
    }


    // MARK: Overrides

    override func subview(contains position: CGPoint) -> Bool {
        return true
    }


    // MARK: API

    /// Returns a window size that fits within the min / max media window constraints while maintaining aspect ratio
    func constrainWindow(size: CGSize) -> CGSize {
        if size.height > size.width {
            let scale = size.width / size.height
            let height = clamp(size.height, min: style.minMediaWindowHeight, max: style.maxMediaWindowHeight)
            return CGSize(width: height * scale, height: height)
        } else {
            let scale = size.height / size.width
            let width = clamp(size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWidth)
            return CGSize(width: width, height: width * scale)
        }
    }
}
