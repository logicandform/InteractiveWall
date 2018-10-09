//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit
import MacGestures


class RecordCollectionViewController: BaseViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource {
    static let storyboard = "Collection"

    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var collectionScrollView: FadingScrollView!
    @IBOutlet weak var arrowIndicatorContainer: NSView!

    var record: Record!
    private var selectedRecords = Set<Record>()

    private struct Constants {
        static let textCellHeight: CGFloat = 200
        static let mediaCellHeight: CGFloat = 160
        static let animationDuration = 0.5
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupRelationshipHelper()
        setupCollectionView()
        setupGestures()
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        updateArrowIndicatorView()
    }


    // MARK: Setup

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        view.alphaValue = 0
        windowDragArea.alphaValue = 0
        collectionView.alphaValue = 0
        titleLabel.attributedStringValue = NSAttributedString(string: record.shortestTitle(), attributes: style.windowTitleAttributes)
        windowDragAreaHighlight.layer?.backgroundColor = style.collectionColor.cgColor
    }

    private func setupRelationshipHelper() {
        relationshipHelper = RelationshipHelper()
        relationshipHelper?.parent = self
        relationshipHelper?.controllerClosed = { [weak self] controller in
            self?.unselectRecord(for: controller)
        }
    }

    private func setupCollectionView() {
        collectionView.register(InfoCollectionItemView.self, forItemWithIdentifier: InfoCollectionItemView.identifier)
        collectionView.register(RecordCollectionItemView.self, forItemWithIdentifier: RecordCollectionItemView.identifier)
        collectionScrollView.verticalScroller?.alphaValue = 0
        load(record.relatedRecords)
    }

    private func setupGestures() {
        let relatedViewPan = PanGestureRecognizer()
        gestureManager.add(relatedViewPan, to: collectionView)
        relatedViewPan.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewPan(gesture)
        }

        let relatedItemTap = TapGestureRecognizer(withDelay: true)
        gestureManager.add(relatedItemTap, to: collectionView)
        relatedItemTap.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewTap(gesture)
        }

        let arrowIndicatorTap = TapGestureRecognizer()
        gestureManager.add(arrowIndicatorTap, to: arrowIndicatorContainer)
        arrowIndicatorTap.gestureUpdated = { [weak self] gesture in
            self?.handleArrowIndicatorTap(gesture)
        }
    }


    // MARK: Overrides

    override func animateViewIn() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            windowDragArea.animator().alphaValue = 1
            collectionView.animator().alphaValue = 1
            view.animator().alphaValue = 1
        })
    }

    override func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            windowDragArea.animator().alphaValue = 0
            collectionView.animator().alphaValue = 0
            view.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }


    // MARK: Gesture Handling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = collectionView.visibleRect
            rect.origin.y += pan.delta.dy
            collectionView.scrollToVisible(rect)
            collectionScrollView.updateGradient()
            updateArrowIndicatorView()
        default:
            return
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let collectionItemView = collectionView.item(at: indexPath) as? RecordCollectionItemView,
            let record = collectionItemView.record else {
                return
        }

        collectionItemView.set(highlighted: true)
        select(record)
    }

    private func handleArrowIndicatorTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .ended:
            let delta = collectionScrollView.frame.height - 20
            var point = collectionClipView.visibleRect.origin
            point.y += delta
            collectionScrollView.updateGradient(with: delta)
            updateArrowIndicatorView(with: delta)
            collectionView.animate(to: point, duration: Constants.animationDuration)
        default:
            return
        }
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return record.relatedRecords.count + 1
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch indexPath.item {
        case 0:
            if let infoItemView = collectionView.makeItem(withIdentifier: InfoCollectionItemView.identifier, for: indexPath) as? InfoCollectionItemView {
                infoItemView.record = record
                return infoItemView
            }
        default:
            if let collectionItemView = collectionView.makeItem(withIdentifier: RecordCollectionItemView.identifier, for: indexPath) as? RecordCollectionItemView {
                let relatedRecord = record.relatedRecords[indexPath.item - 1]
                collectionItemView.record = relatedRecord
                collectionItemView.set(highlighted: selectedRecords.contains(relatedRecord))
                return collectionItemView
            }
        }

        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let collectionWidth = collectionClipView.frame.size.width
        switch indexPath.item {
        case 0:
            let height = InfoCollectionItemView.height(for: record, width: collectionWidth)
            return CGSize(width: collectionWidth, height: height)
        default:
            let spacing = (collectionView.collectionViewLayout as? NSCollectionViewFlowLayout)?.minimumInteritemSpacing ?? 0
            let cellWidth = (collectionWidth - spacing) / 2
            return CGSize(width: cellWidth, height: Constants.mediaCellHeight)
        }
    }


    // MARK: Helpers

    private func load(_ records: [Record]) {
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { [weak self] finished in
            if let strongSelf = self, finished {
                strongSelf.collectionScrollView.updateGradient()
                strongSelf.animateViewIn()
            }
        }
    }

    private func select(_ record: Record) {
        if let windowType = WindowType(for: record) {
            selectedRecords.insert(record)
            relationshipHelper?.display(windowType)
        }
    }

    private func unselectRecord(for controller: BaseViewController) {
        guard let recordViewController = controller as? RecordViewController, let record = recordViewController.record else {
            return
        }

        selectedRecords.remove(record)

        for view in collectionView.visibleItems().compactMap({ $0 as? RecordCollectionItemView }) {
            if let record = view.record {
                view.set(highlighted: selectedRecords.contains(record))
            }
        }
    }

    private func updateArrowIndicatorView(with delta: CGFloat = 0) {
        arrowIndicatorContainer.isHidden = collectionScrollView.hasReachedBottom(with: delta)
    }
}
