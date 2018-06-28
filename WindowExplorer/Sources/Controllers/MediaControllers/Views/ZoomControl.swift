//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class ZoomControl: NSView {

    static let nib = NSNib.Name(rawValue: "ZoomControl")

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

        Bundle.main.loadNibNamed(ZoomControl.nib, owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }


    // MARK: Setup

    private func setupGestures() {
        let scrubGesture = PanGestureRecognizer()
        gestureManager.add(scrubGesture, to: seekBar)
        scrubGesture.gestureUpdated = { [weak self] gesture in
            self?.handleScrubGesture(gesture)
        }
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
            let positionInSeekBar = (position.x) / (seekBar.frame.width)
            let delta = Double(positionInSeekBar) * (seekBar.maxValue - seekBar.minValue)
            let scale = CGFloat(delta + seekBar.minValue)

            updateSeekBarPosition(to: scale)
            zoomSliderUpdated?(scale)
        default:
            return
        }
    }
}
