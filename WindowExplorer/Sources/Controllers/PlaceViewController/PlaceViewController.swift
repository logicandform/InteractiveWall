//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class PlaceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Place")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var relatedView: NSTableView!
    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var closeButtonView: NSView!
    @IBOutlet weak var playerButtonView: NSView!

    private(set) var gestureManager: GestureManager!
    private var nsPanGesture: NSPanGestureRecognizer!
    private var initialPanningOrigin: CGPoint?

    var place: Place! {
        didSet {
            setup(for: place)
        }
    }

    private var finishedAnimation = false

    private struct Constants {
        static let tableRowHeight: CGFloat = 50
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        relatedView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedView.backgroundColor = NSColor.clear
        gestureManager = GestureManager(responder: self)

        animateViewIn()
        setupGestures()
    }


    // MARK: Setup

    private func setup(for place: Place) {
        titleLabel.stringValue = place.subtitle ?? "unknown"
    }

    private func setupGestures() {
        nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMouseDrag(_:)))
        detailView.addGestureRecognizer(nsPanGesture)

        let singleFingerDetailViewPan = PanGestureRecognizer()
        gestureManager.add(singleFingerDetailViewPan, to: detailView)
        singleFingerDetailViewPan.gestureUpdated = handleDetailViewPan(_:)

        let singleFingerRelatedViewPan = PanGestureRecognizer()
        gestureManager.add(singleFingerRelatedViewPan, to: relatedView)
        singleFingerRelatedViewPan.gestureUpdated = handleTableViewPan(_:)

        let singleFingerTap = TapGestureRecognizer()
        gestureManager.add(singleFingerTap, to: closeButtonView)
        singleFingerTap.gestureUpdated = didTapCloseButton(_:)

        let singleFingerRelatedViewTap = TapGestureRecognizer()
        gestureManager.add(singleFingerRelatedViewTap, to: relatedView)
        singleFingerRelatedViewTap.gestureUpdated = didTapRelatedView(_:)

        let singleFingerVideoButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerVideoButtonTap, to: playerButtonView)
        singleFingerVideoButtonTap.gestureUpdated = didTapPlayerButton(_:)
    }


    // MARK: Gesture Handling

    private func handleDetailViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta
            window.setFrameOrigin(origin)
        default:
            return
        }
    }

    private func handleTableViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var position = relatedView.visibleRect.origin
            position.y += pan.delta.dy
            relatedView.scroll(position)
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }

    private func didTapPlayerButton(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer, let window = view.window else {
            return
        }

        let position = window.frame.origin + CGVector(dx: window.frame.size.width + 20, dy: 0)
        WindowManager.instance.displayWindow(for: .player, at: position)
    }

    private func didTapRelatedView(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let location = tap.position else {
            return
        }

        // Invert coordinate system for a tableview, using detailView for its static height.
        var invertedLocation = location.inverted(in: detailView)
        invertedLocation.y += relatedView.visibleRect.origin.y
        let row = relatedView.row(at: invertedLocation)
        if let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: false) as? RelatedItemView {
            relatedItemView.didTapView()
        }
    }

    @objc
    private func handleMouseDrag(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }

    @IBAction func videoButtonTapped(_ sender: Any) {
        if let window = view.window {
            let position = window.frame.origin + CGVector(dx: window.frame.maxX + 20, dy: 0)
            WindowManager.instance.displayWindow(for: .player, at: position)
        }
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 12
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        relatedItemView.alphaValue = finishedAnimation ? 1.0 : 0.0
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
        if let window = view.window  {
            let position = window.frame.origin + CGPoint(x: window.frame.width + 20, y: -20)
            WindowManager.instance.displayWindow(for: .place, at: position)
        }
    }

    private func animateViewIn() {
        detailView.alphaValue = 0.0
        detailView.frame.origin.y = view.frame.size.height

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 0.7
            self?.detailView.animator().alphaValue = 1.0
            self?.detailView.animator().frame.origin.y = 0
        })

        animateTableViewIn(for: 0)
    }

    private func animateTableViewIn(for row: Int) {
        guard relatedView.rows(in: relatedView.frame).contains(row), let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: true) as? RelatedItemView else {
            return
        }

        // Checks if the current relatedItemView can be visibly displayed on the relatedView. If it can't, skip the animation.
        if relatedView.convert(relatedView.frame.origin, to: relatedItemView).y - relatedItemView.frame.height > detailView.frame.height {
            relatedItemView.alphaValue = 1.0
            animateTableViewIn(for: row + 1)
            return
        }

        relatedItemView.frame.origin.x = -200
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) { [weak self] in
            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = 0.4
                relatedItemView.animator().alphaValue = 1.0
                relatedItemView.animator().frame.origin.x = 20
            }, completionHandler: { [weak self] in
                self?.finishedAnimation = true
            })

            self?.animateTableViewIn(for: row + 1)
        }
    }

    private func animateTableViewOut(for row: Int) {
        guard relatedView.rows(in: relatedView.frame).contains(row), let relatedItemView = relatedView.view(atColumn: 0, row: row, makeIfNecessary: true) as? RelatedItemView else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.04) { [weak self] in
            NSAnimationContext.runAnimationGroup({ [weak self] _ in
                if let strongSelf = self {
                    NSAnimationContext.current.duration = 0.2
                    relatedItemView.animator().alphaValue = 0.0
                    relatedItemView.animator().frame.origin.x = -strongSelf.relatedView.frame.width
                }
            })

            self?.animateTableViewOut(for: row - 1)
        }
    }

    private func animateViewOut() {
        let range = relatedView.rows(in: relatedView.visibleRect)
        animateTableViewOut(for: range.location + range.length - 1)

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            if let strongSelf = self {
                NSAnimationContext.current.duration = 1.3
                strongSelf.detailView.animator().alphaValue = 0.0
                strongSelf.detailView.animator().frame.origin.y = strongSelf.detailView.frame.height
            }

        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                WindowManager.instance.closeWindow(for: strongSelf)
            }
        })
    }
}
