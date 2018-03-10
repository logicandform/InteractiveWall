//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: NSViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, NSTableViewDataSource, NSTableViewDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Record")

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var relatedItemsView: NSTableView!

    private(set) var gestureManager: GestureManager!
    private var showingRelatedItems = false
    
    private struct Constants {
        static let tableRowHeight: CGFloat = 60
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = #colorLiteral(red: 0.1433445513, green: 0.1544109583, blue: 0.1703726053, alpha: 0.75)
        gestureManager = GestureManager(responder: self)

        setupCollectionView()
        setupStackView()
        setupRelatedItemsView()
        setupGestures()
    }


    // MARK: Setup

    private func setupCollectionView() {
        collectionView.register(RecordItemView.self, forItemWithIdentifier: RecordItemView.identifier)

    }

    private func setupStackView() {
        
        for _ in (1...15) {
            let label = NSTextField(string: "Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label. Hello this is a testing label.")
            stackView.insertView(label, at: stackView.subviews.count, in: .top)
        }
    }

    private func setupRelatedItemsView() {
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedItemsView.backgroundColor = .clear
    }

    private func setupGestures() {
        let nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMouseDrag(_:)))
        view.addGestureRecognizer(nsPanGesture)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: view)
        panGesture.gestureUpdated = handleWindowPan(_:)

        let collectionViewPanGesture = PanGestureRecognizer()
        gestureManager.add(collectionViewPanGesture, to: collectionView)
        collectionViewPanGesture.gestureUpdated = handleCollectionViewPan(_:)

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: scrollView)
        stackViewPanGesture.gestureUpdated = handleStackViewPan(_:)
    }


    // MARK: Gesture Handling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = collectionView.visibleRect
            rect.origin.x -= pan.delta.dx
            collectionView.scrollToVisible(rect)
        case .possible:
            let rect = collectionView.visibleRect
            let xPos = rect.origin.x / rect.width
            let item = round(xPos)
            let point = CGPoint(x: item * rect.width, y: 0)
            collectionView.scroll(point)
        default:
            return
        }
    }

    @IBOutlet weak var clipView: NSClipView!

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
            WindowManager.instance.dealocateWindowIfOutOfBounds(for: self)
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
        WindowManager.instance.dealocateWindowIfOutOfBounds(for: self)
    }


    // MARK: IB-Actions

    @IBAction func toggleRelatedItems(_ sender: Any) {
        toggleRelatedItems()
    }

    @IBAction func closeWindowTapped(_ sender: Any) {
        WindowManager.instance.closeWindow(for: self)
    }


    // MARK: Helpers

    private func toggleRelatedItems() {
        guard let window = view.window else {
            return
        }

        let alpha: CGFloat = showingRelatedItems ? 0 : 1
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 0.5
            self?.relatedItemsView.animator().alphaValue = alpha
        })

        let diff: CGFloat = showingRelatedItems ? -200 : 200
        var frame = window.frame
        frame.size.width += diff

        window.setFrame(frame, display: true, animate: true)
        showingRelatedItems = !showingRelatedItems
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    let colors: [NSColor] = [.red, .blue, .green, .orange]

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let recordItemView = collectionView.makeItem(withIdentifier: RecordItemView.identifier, for: indexPath) as? RecordItemView else {
            return NSCollectionViewItem()
        }

        recordItemView.color = colors[indexPath.item]
        return recordItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return collectionView.frame.size
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
