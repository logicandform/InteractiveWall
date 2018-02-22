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

    private var animationHappened = false
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

        animateViewIn()
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

        let singleFingerDetailViewPan = PanGestureRecognizer()
        gestureManager.add(singleFingerDetailViewPan, to: detailView)
        singleFingerDetailViewPan.gestureUpdated = detailViewDidPan(_:)

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: closeButtonView)
        singleFingerTap.gestureUpdated = detailViewDidTap(_:)

        let singleFingerRelatedViewTap = TapGestureRecognizer()
        gestureManager.add(singleFingerRelatedViewTap, to: relatedView)
        singleFingerRelatedViewTap.gestureUpdated = relatedViewDidTap(_:)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 12
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        relatedItemView.alphaValue = animationHappened ? 1.0 : 0.0
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

    private func animateViewIn() {
        detailView.alphaValue = 0.0
        detailView.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.7
            detailView.animator().alphaValue = 1.0
            detailView.animator().frame.origin.y = 0
        })

        animateTableViewIn(for: 0)
    }

    private func animateTableViewIn(for row: Int) {
        guard relatedView.rows(in: relatedView.frame).contains(row), let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: true) as? RelatedItemView else {
            return
        }

        // Checks if the current relatedItemView can be visibly displayed on the relatedView. If it can't, skip the animation.
        if self.relatedView.convert(self.relatedView.frame.origin, to: relatedItemView).y - relatedItemView.frame.height > self.detailView.frame.height {
            relatedItemView.alphaValue = 1.0
            animateTableViewIn(for: row + 1)
            return
        }

        relatedItemView.frame.origin.x = -200
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {

            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.4
                relatedItemView.animator().alphaValue = 1.0
                relatedItemView.animator().frame.origin.x = 20
            }, completionHandler: {
                self.animationHappened = true
            })

            self.animateTableViewIn(for: row + 1)
        }
    }

    private func animateTableViewOut(for row: Int) {
        guard relatedView.rows(in: relatedView.frame).contains(row), let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: true) as? RelatedItemView else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.04) {

            NSAnimationContext.runAnimationGroup({_ in
                NSAnimationContext.current.duration = 0.2
                relatedItemView.animator().alphaValue = 0.0
                relatedItemView.animator().frame.origin.x = -self.relatedView.frame.width
            })

            self.animateTableViewOut(for: row - 1)
        }
    }

    private func animateViewOut() {
        let range = relatedView.rows(in: relatedView.visibleRect)
        animateTableViewOut(for: range.location + range.length - 1)

        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.3
            detailView.animator().alphaValue = 0.0
            detailView.animator().frame.origin.y = detailView.frame.height

        }, completionHandler: {
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
            self.gestureManager.remove(views: [self.relatedView, self.detailView])
        })
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
        guard let pan = gesture as? PanGestureRecognizer, animationHappened else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
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
        case .recognized, .momentum:
            var origin = view.frame.origin
            origin += pan.delta
            view.frame.origin = origin
        default:
            return
        }
    }

    private func detailViewDidTap(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }

    private func relatedViewDidTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let location = tap.position else {
            return
        }

        /// Invert coordinate system for a tableview, using detailView for its static height.
        let invertedLocation = location.inverted(in: detailView)
        let row = relatedView.row(at: invertedLocation)
        if let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: false) as? RelatedItemView {
            relatedItemView.didTapView()
        }
    }
}
