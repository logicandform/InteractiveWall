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
    }


    // MARK: Setup

    private func setup(for place: Place) {
        titleLabel.stringValue = place.subtitle ?? "unknown"
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        view.removeFromSuperview()
        removeFromParentViewController()
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 4
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
}
