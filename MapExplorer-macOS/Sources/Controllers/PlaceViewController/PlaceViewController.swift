//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class PlaceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Place")

    private struct Constants {
        static let tableRowHeight: CGFloat = 50
    }

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var relatedView: NSTableView!
    @IBOutlet weak var detailView: NSView!

    weak var gestureManager: GestureManager!
    weak var viewDelegate: ViewManagerDelegate?
    var panGesture: NSPanGestureRecognizer!
    var initialPanningOrigin: CGPoint?
    var place: Place! {
        didSet {
            setup(for: place)
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.wantsLayer = true
        //detailView.alphaValue = 0.0
        detailView.setFrameSize(NSSize(width: 1, height: 1))
        detailView.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)

        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        detailView.addGestureRecognizer(panGesture)

        relatedView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        //relatedView.alphaValue = 0.0
        relatedView.backgroundColor = NSColor.clear
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.0
            detailView.animator().alphaValue = 1.0
            relatedView.animator().alphaValue = 1.0
            detailView.animator().setFrameSize(NSSize(width: 100.0, height: 100.0))
        }, completionHandler: {
            print("Animation Completed")
        })

        setupGestures()
    }


    // MARK: Setup

    private func setup(for place: Place) {
        titleLabel.stringValue = place.subtitle ?? "unknown"
    }

     func setupGestures() {
        let singleFingerRelatedViewPan = PanGestureRecognizer()
        gestureManager.add(singleFingerRelatedViewPan, to: relatedView)
        singleFingerRelatedViewPan.gestureUpdated = tableViewDidPan(_:)

        let singleFingerDetialViewPan = PanGestureRecognizer()
        gestureManager.add(singleFingerDetialViewPan, to: detailView)
        singleFingerDetialViewPan.gestureUpdated = detailViewDidPan(_:)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        view.removeFromSuperview()
        removeFromParentViewController()
        gestureManager.remove(views: [relatedView, detailView])
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 12
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        relatedItemView.didTapItem = didSelectRelatedItem
        return relatedItemView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constants.tableRowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }


    // MARK: Helpers

    private func didSelectRelatedItem() {
        /// Display another detail view to the right of the current view.
        viewDelegate?.displayView(for: place, from: view)
    }

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

    private func tableViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized:
            let deltaY = pan.delta.dy
            let orginX = relatedView.visibleRect.origin.x
            let orginY = relatedView.visibleRect.origin.y
            relatedView.scroll(CGPoint(x: orginX, y: orginY + deltaY))
        default:
            return
        }
    }

    private func detailViewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized:
            var origin = view.frame.origin
            origin += pan.delta
            view.frame.origin = origin
        default:
            return
        }
    }
}
