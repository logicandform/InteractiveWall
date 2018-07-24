//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class ZoomControl: NSView {
    static let nib = NSNib.Name(rawValue: "ZoomControl")

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var seekBar: NSSlider!
    @IBOutlet weak var zoomOutButton: NSButton!
    @IBOutlet weak var zoomInButton: NSButton!

    var zoomSliderUpdated: ((CGFloat) -> Void)?

    var gestureManager: GestureManager! {
        didSet {
            setupGestures()
        }
    }

    var tintColor: NSColor? {
        didSet {
            if let color = tintColor, let cell = seekBar.cell as? ColoredSliderCell {
                cell.leadingColor = color
            }
        }
    }

    private struct Constants {
        static let cornerRadius: CGFloat = 5
        static let magnificationButtonZoom = 0.2
    }


    // MARK: Init

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        Bundle.main.loadNibNamed(ZoomControl.nib, owner: self, topLevelObjects: nil)
        setupView()
    }


    // MARK: Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = style.zoomControlColor.cgColor
        layer?.cornerRadius = Constants.cornerRadius
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = .width
    }

    private func setupGestures() {
        let scrubGesture = PanGestureRecognizer()
        gestureManager.add(scrubGesture, to: seekBar)
        scrubGesture.gestureUpdated = { [weak self] gesture in
            self?.handleScrubGesture(gesture)
        }

        let zoomInGesture = TapGestureRecognizer()
        gestureManager.add(zoomInGesture, to: zoomInButton)
        zoomInGesture.gestureUpdated = { [weak self] gesture in
            self?.handleZoomInGesture(gesture)
        }

        let zoomOutGesture = TapGestureRecognizer()
        gestureManager.add(zoomOutGesture, to: zoomOutButton)
        zoomOutGesture.gestureUpdated = { [weak self] gesture in
            self?.handleZoomOutGesture(gesture)
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

    private func handleZoomInGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .ended:
            let scale = seekBar.doubleValue + Constants.magnificationButtonZoom > seekBar.maxValue ? seekBar.maxValue : seekBar.doubleValue + Constants.magnificationButtonZoom
            updateSeekBarPosition(to: CGFloat(scale))
            zoomSliderUpdated?(CGFloat(scale))
        default:
            return
        }
    }

    private func handleZoomOutGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .ended:
            let scale = seekBar.doubleValue - Constants.magnificationButtonZoom < seekBar.minValue ? seekBar.minValue : seekBar.doubleValue - Constants.magnificationButtonZoom
            updateSeekBarPosition(to: CGFloat(scale))
            zoomSliderUpdated?(CGFloat(scale))
        default:
            return
        }
    }
}
