//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class ImageZoomControl: NSView {

    static let nib = NSNib.Name(rawValue: "ImageZoomControl")

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var seekBar: NSSlider!

    var gestureManager: GestureManager! {
        didSet {
            setupGestures()
        }
    }

    var zoomSliderUpdated: ((CGFloat) -> Void)?


    // MARK: Init

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        Bundle.main.loadNibNamed(ImageZoomControl.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = NSRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }


    // MARK: Setup

    private func setupGestures() {
        let scrubGesture = PanGestureRecognizer()
        gestureManager.add(scrubGesture, to: seekBar)
        scrubGesture.gestureUpdated = handleScrubGesture(_:)
    }


    // MARK: API

    func updateSeekBarPosition(to value: CGFloat) {
        seekBar.doubleValue = Double(value)
    }


    // MARK: Gesture Handlers

    private func handleScrubGesture(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let position = pan.lastLocation else {
            return
        }

        switch pan.state {
        case .recognized:
            let positionInSeekBar = position.x < 0.2 ? (position.x / seekBar.frame.size.width) + 0.2 : position.x / seekBar.frame.size.width
            let zoomScale = clamp(positionInSeekBar, min: 0.2, max: 1)

            updateSeekBarPosition(to: zoomScale)
            zoomSliderUpdated?(zoomScale)
        default:
            return
        }
    }
}
