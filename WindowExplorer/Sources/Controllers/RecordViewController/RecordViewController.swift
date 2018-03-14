//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: NSViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, NSTableViewDataSource, NSTableViewDelegate, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Record")

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var mediaView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var stackClipView: NSClipView!
    @IBOutlet weak var relatedItemsView: NSTableView!
    @IBOutlet weak var hideRelatedItemsButton: NSButton!
    @IBOutlet weak var closeWindowTapArea: NSView!
    @IBOutlet weak var toggleRelatedItemsArea: NSView!

    var record: RecordDisplayable?
    private(set) var gestureManager: GestureManager!
    private var showingRelatedItems = false
    
    private struct Constants {
        static let tableRowHeight: CGFloat = 60
        static let windowMargins: CGFloat = 20
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)

        setupCollectionView()
        setupRelatedItemsView()
        setupGestures()
        loadRecord()
    }


    // MARK: Setup

    private func setupCollectionView() {
        mediaView.register(MediaItemView.self, forItemWithIdentifier: MediaItemView.identifier)
    }

    private func setupRelatedItemsView() {
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedItemsView.backgroundColor = .clear
        hideRelatedItemsButton.alphaValue = 0
    }

    private func setupGestures() {
        let nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMouseDrag(_:)))
        detailView.addGestureRecognizer(nsPanGesture)

        let collectionViewPanGesture = PanGestureRecognizer()
        gestureManager.add(collectionViewPanGesture, to: mediaView)
        collectionViewPanGesture.gestureUpdated = handleCollectionViewPan(_:)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: detailView)
        panGesture.gestureUpdated = handleWindowPan(_:)

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: stackView)
        stackViewPanGesture.gestureUpdated = handleStackViewPan(_:)

        let tapToClose = TapGestureRecognizer()
        gestureManager.add(tapToClose, to: closeWindowTapArea)
        tapToClose.gestureUpdated = { gesture in
            if gesture.state == .ended {
                WindowManager.instance.closeWindow(for: self)
            }
        }

        let toggleRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(toggleRelatedItemsTap, to: toggleRelatedItemsArea)
        toggleRelatedItemsTap.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended {
                self?.toggleRelatedItems()
            }
        }
    }

    private func loadRecord() {
        guard let record = record else {
            return
        }

        titleLabel.stringValue = record.title
        dateLabel.stringValue = record.date ?? "no date"
        for label in record.textFields {
            stackView.insertView(label, at: stackView.subviews.count, in: .top)
        }
    }


    // MARK: Gesture Handling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = mediaView.visibleRect
            rect.origin.x -= pan.delta.dx
            mediaView.scrollToVisible(rect)
        case .possible:
            let rect = mediaView.visibleRect
            let offset = rect.origin.x / rect.width
            let index = round(offset)
            let margin = offset.truncatingRemainder(dividingBy: 1)
            let duration = margin < 0.5 ? margin : 1 - margin
            let origin = CGPoint(x: rect.width * index, y: 0)
            animateCollectionView(to: origin, duration: duration)
        default:
            return
        }
    }

    private func handleStackViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var point = stackClipView.visibleRect.origin
            point.y -= pan.delta.dy
            stackClipView.scroll(point)
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
        WindowManager.instance.closeWindow(for: self)
    }


    // MARK: Helpers

    private func animateCollectionView(to point: CGPoint, duration: CGFloat) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = TimeInterval(duration)
        collectionClipView.animator().setBoundsOrigin(point)
        NSAnimationContext.endGrouping()
    }

    private func toggleRelatedItems(completion: (() -> Void)? = nil) {
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
                completion?()
        })

        let diff: CGFloat = showingRelatedItems ? -200 : 200
        var frame = window.frame
        frame.size.width += diff

        window.setFrame(frame, display: true, animate: true)
        showingRelatedItems = !showingRelatedItems
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return record?.thumbnails.count ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let mediaItemView = collectionView.makeItem(withIdentifier: MediaItemView.identifier, for: indexPath) as? MediaItemView else {
            return NSCollectionViewItem()
        }

        mediaItemView.imageURL = record?.thumbnails[indexPath.item]
        return mediaItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return collectionClipView.frame.size
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return record?.relatedRecords.count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        relatedItemView.gestureManager = gestureManager
        relatedItemView.record = record?.relatedRecords[row]
        relatedItemView.didTapItem = didSelectRelatedItem(for:)
        return relatedItemView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constants.tableRowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }

    func didSelectRelatedItem(for record: RecordDisplayable?) {
        guard let selectedRecord = record, let window = view.window else {
            return
        }

        toggleRelatedItems(completion: {
            let origin = CGPoint(x: window.frame.maxX + Constants.windowMargins, y: window.frame.minY)
            RecordFactory.record(for: selectedRecord.type, id: selectedRecord.id, completion: { newRecord in
                if let loadedRecord = newRecord {
                    WindowManager.instance.displayWindow(for: .record(loadedRecord), at: origin)
                }
            })
        })
    }
}
