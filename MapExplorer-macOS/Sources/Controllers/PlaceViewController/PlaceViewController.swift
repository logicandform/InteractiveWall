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
    @IBOutlet weak var closeButtonView: NSView!

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
        detailView.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        detailView.addGestureRecognizer(panGesture)

        relatedView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedView.backgroundColor = NSColor.clear

        animateView()
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

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: closeButtonView)
        singleFingerTap.gestureUpdated = detailViewDidTap(_:)
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
        relatedItemView.alphaValue = 0.0
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

    private func animateView() {
        detailView.alphaValue = 0.0
        detailView.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({_ in

            NSAnimationContext.current.duration = 0.7
            detailView.animator().alphaValue = 1.0
            detailView.animator().frame.origin.y = 0
        })
        animateTableView(for: 0)
    }

    private func animateTableView(for row: Int) {
        guard relatedView.rows(in: relatedView.frame).contains(row), let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: true) as? RelatedItemView else {
            return
        }

        relatedItemView.frame.origin.x = 200
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {

            NSAnimationContext.runAnimationGroup({_ in

                NSAnimationContext.current.duration = 0.4
                relatedItemView.animator().alphaValue = 1.0
                relatedItemView.animator().frame.origin.x = 20
            })

            self.animateTableView(for: row + 1)
        }
    }

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

    private func detailViewDidTap(_ gesture: GestureRecognizer) {
        guard let _ = gesture as? TapGestureRecognizer else {
            return
        }

        view.removeFromSuperview()
        removeFromParentViewController()
        gestureManager.remove(views: [relatedView, detailView])
    }
}
