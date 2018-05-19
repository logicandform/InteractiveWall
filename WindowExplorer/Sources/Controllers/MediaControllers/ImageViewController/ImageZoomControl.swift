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

    var zoomScaleUpdated: ((Double) -> Void)?


    // MARK: Init

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        Bundle.main.loadNibNamed(ImageZoomControl.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }


    // MARK: Setup

    private func setupGestures() {
        let slideGesture = PanGestureRecognizer()
        gestureManager.add(slideGesture, to: seekBar)
        slideGesture.gestureUpdated = handleSlideGesture(_:)
    }


    // MARK: API

    func updateSeekBarPosition(value: Double) {
        seekBar.doubleValue = value
    }


    // MARK: Gesture Handlers

    private func handleSlideGesture(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let position = pan.lastLocation else {
            return
        }

        switch pan.state {
        case .recognized:
            let positionInSeekBar = Double((position.x / seekBar.frame.size.width) + 0.2)
            let zoomScale = clamp(positionInSeekBar, min: 0.2, max: 1)
            
            seekBar.doubleValue = zoomScale
            zoomScaleUpdated?(zoomScale)
        default:
            return
        }
    }
}
