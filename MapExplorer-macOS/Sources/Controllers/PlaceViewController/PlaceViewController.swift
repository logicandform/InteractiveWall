//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class PlaceViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Place")

    var place: Place! {
        didSet {
            setup(with: place)
        }
    }

    @IBOutlet weak var titleLabel: NSTextField!
    var panGesture: NSPanGestureRecognizer!
    var initialPanningOrigin: CGPoint?


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)

        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(panGesture)
    }


    // MARK: Setup

    private func setup(with place: Place) {
        titleLabel.stringValue = place.title ?? "unknown"
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        view.removeFromSuperview()
        removeFromParentViewController()
    }


    // MARK: Helpers

    @objc
    private func handlePan(gesture: NSPanGestureRecognizer) {
        if gesture.state == .began {
            initialPanningOrigin = view.frame.origin
            return
        }

        if var origin = initialPanningOrigin {
            origin += gesture.translation(in: view.superview)
            view.frame.origin = origin
        }
    }
    
}
