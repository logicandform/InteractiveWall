//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class RecordPageViewController: NSPageController, NSPageControllerDelegate {

    var pageObjects = [Any]()

    var gestureManager: GestureManager! {
        didSet {
            setupGestures()
        }
    }

    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        arrangedObjects = pageObjects
    }


    // MARK: Setup

    private func setupGestures() {
        guard let gestureManager = gestureManager else {
            return
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: view)
        panGesture.gestureUpdated = didPanView(_:)
    }

    func scrollMe() {
        view.scroll(CGPoint(x: 500, y: 0))
    }

    // MARK: Gesture Handling

    private func didPanView(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized:
            return
        case .ended:
            return
        default:
            return
        }
    }


    // MARK: NSPageControllerDelegate

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return ImagePage.pageIdentifier
    }

    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
        let storyboardIdentifier = NSStoryboard.SceneIdentifier(identifier.rawValue)
        return storyboard?.instantiateController(withIdentifier: storyboardIdentifier) as! NSViewController
    }

    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        if let imagePage = viewController as? ImagePage, let urlString = object as? String, let url = URL(string: urlString) {
            imagePage.imageURL = url
        }
    }

    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        
    }
}
