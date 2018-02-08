//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class PlaceViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Place")

    var place: Place! {
        didSet {
            setup(with: place)
        }
    }

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var leftView: NSView!
    var panGesture: NSPanGestureRecognizer!
    var initialPanningOrigin: CGPoint?


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        leftView.wantsLayer = true
        leftView.layer?.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)

        panGesture = NSPanGestureRecognizer(target: leftView, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(panGesture)

        tableView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        tableView.backgroundColor = NSColor.clear
    }


    // MARK: Setup

    private func setup(with place: Place) {
        titleLabel.stringValue = place.subtitle ?? "unknown"
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


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 4
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        return relatedItemView
    }

    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {

    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50.0
    }
}
