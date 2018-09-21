//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class IndicatorViewController: NSViewController {
    static let storyboard = "Indicator"
    static var instance: IndicatorViewController?

    private struct Constants {
        static let animationDuration = 0.6
        static let indicatorRadius: CGFloat = 4
    }


    // MARK: Init

    static func instantiate() {
        if IndicatorViewController.instance == nil {
            let origin = CGPoint(x: NSScreen.mainScreen.frame.maxX, y: 0)
            IndicatorViewController.instance = WindowManager.instance.display(.indicator, at: origin) as? IndicatorViewController
        }
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }


    // MARK: API

    /// Displays a touch indicator depending on the state of the touch
    func displayIndicator(for touch: Touch) {
        let position = indicatorPosition(for: touch)

        switch touch.state {
        case .down, .moved:
            displayIndicator(at: position)
        case .up:
            return
        }
    }


    // MARK: Setup

    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor.clear
    }


    // MARK: Helpers

    private func indicatorPosition(for touch: Touch) -> CGPoint {
        guard let window = view.window else {
            return touch.position
        }

        return touch.position.transformed(to: window.frame)
    }

    /// Displays a touch indicator at the given position
    private func displayIndicator(at position: CGPoint) {
        let radius = Constants.indicatorRadius
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let indicator = NSView(frame: frame)
        indicator.wantsLayer = true
        indicator.layer?.cornerRadius = radius
        indicator.layer?.masksToBounds = true
        indicator.layer?.backgroundColor = style.selectedColor.cgColor
        view.addSubview(indicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            indicator.animator().alphaValue = 0
            indicator.animator().frame.size = .zero
            indicator.animator().frame.origin = CGPoint(x: indicator.frame.origin.x + radius, y: indicator.frame.origin.y + radius)
        }, completionHandler: {
            indicator.removeFromSuperview()
        })
    }
}
