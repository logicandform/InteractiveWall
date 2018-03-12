//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Record")

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var relatedItemsView: NSTableView!
    @IBOutlet weak var hideRelatedItemsButton: NSButton!
    
    private(set) var gestureManager: GestureManager!
    private var showingRelatedItems = false
    private var mediaObjects = ["https://images7.alphacoders.com/633/633262.png", "https://images7.alphacoders.com/633/633262.png", "https://images7.alphacoders.com/633/633262.png"]
    
    private struct Constants {
        static let tableRowHeight: CGFloat = 60
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)

        setupCollectionView()
        setupStackView()
        setupRelatedItemsView()
        setupGestures()
    }


    // MARK: Setup

    private func setupCollectionView() {

    }

    private func setupStackView() {
        for _ in (1...15) {
            let label = NSTextField(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            label.drawsBackground = false
            label.isBordered = false
            label.textColor = .white
            label.isSelectable = false
            label.lineBreakMode = .byWordWrapping
            stackView.insertView(label, at: stackView.subviews.count, in: .top)
        }
    }

    private func setupRelatedItemsView() {
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedItemsView.backgroundColor = .clear
        hideRelatedItemsButton.alphaValue = 0
    }

    private func setupGestures() {
        let nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMouseDrag(_:)))
        view.addGestureRecognizer(nsPanGesture)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: view)
        panGesture.gestureUpdated = handleWindowPan(_:)

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: scrollView)
        stackViewPanGesture.gestureUpdated = handleStackViewPan(_:)
    }

    var pageController: RecordPageViewController!
    // MARK: Segue

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let pageController = segue.destinationController as? RecordPageViewController else {
            return
        }

        self.pageController = pageController
        // Might have to be done after record is set
        pageController.pageObjects = mediaObjects
        pageController.gestureManager = gestureManager
    }


    // MARK: Gesture Handling

    private func handleStackViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var point = scrollView.visibleRect.origin
            point.y -= pan.delta.dy
            scrollView.setFrameOrigin(point)
        default:
            return
        }
    }

    private func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        default:
            return
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
        WindowManager.instance.checkBounds(of: self)
    }


    // MARK: IB-Actions

    @IBAction func toggleRelatedItems(_ sender: Any) {
        toggleRelatedItems()
    }

    @IBAction func closeWindowTapped(_ sender: Any) {
//        WindowManager.instance.closeWindow(for: self)
        pageController.scrollMe()
    }


    // MARK: Helpers

    private func toggleRelatedItems() {
        guard let window = view.window else {
            return
        }

        relatedItemsView.isHidden = false
        hideRelatedItemsButton.isHidden = false

        let alpha: CGFloat = showingRelatedItems ? 0 : 1
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 0.5
            self?.relatedItemsView.animator().alphaValue = alpha
            self?.hideRelatedItemsButton.animator().alphaValue = alpha
            }, completionHandler: { [weak self] in
                if let strongSelf = self {
                    strongSelf.relatedItemsView.isHidden = !strongSelf.showingRelatedItems
                    strongSelf.hideRelatedItemsButton.isHidden = !strongSelf.showingRelatedItems
                }
        })

        let diff: CGFloat = showingRelatedItems ? -200 : 200
        var frame = window.frame
        frame.size.width += diff

        window.setFrame(frame, display: true, animate: true)
        showingRelatedItems = !showingRelatedItems
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 12
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        return relatedItemView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constants.tableRowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
