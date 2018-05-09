//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


protocol SearchItemDisplayable {
    var title: String { get }
}


class SearchViewController: BaseViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Search")

    @IBOutlet weak var primaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryCollectionView: NSCollectionView!
    @IBOutlet weak var tertiaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryTextField: NSTextField!
    @IBOutlet weak var tertiaryTextField: NSTextField!

    private var selectedType: RecordType?
    private var selectedItemForView = [NSCollectionView: SearchItemView]()

    private lazy var titleViews: [NSTextField] = [titleLabel, secondaryTextField, tertiaryTextField]
    private lazy var collectionViews: [NSCollectionView] = [primaryCollectionView, secondaryCollectionView, tertiaryCollectionView]
    private lazy var searchItemsForView: [NSCollectionView: [SearchItemDisplayable]] = [
        primaryCollectionView: RecordType.allValues,
        secondaryCollectionView: [],
        tertiaryCollectionView: []
    ]

    private struct Constants {
        static let animationDuration = 0.5
        static let searchItemHeight: CGFloat = 70
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: style.windowTitleAttributes)

        setupGestures()
        resetCloseWindowTimer()
        animateViewIn()
    }


    // MARK: Setup

    private func setupGestures() {
        collectionViews.forEach { collectionView in
            let collectionViewPan = PanGestureRecognizer()
            gestureManager.add(collectionViewPan, to: collectionView)
            collectionViewPan.gestureUpdated = handleCollectionViewPan(_:)

            let collectionViewTap = TapGestureRecognizer()
            gestureManager.add(collectionViewTap, to: collectionView)
            collectionViewTap.gestureUpdated = handleCollectionViewTap(_:)
        }
    }


    // MARK: GestureHandling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: pan) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = collectionView.visibleRect
            rect.origin.y += pan.delta.dy
            collectionView.scrollToVisible(rect)
        default:
            return
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer,
            let collectionView = gestureManager.view(for: tap) as? NSCollectionView,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let searchItem = collectionView.item(at: indexPath) as? SearchItemView,
            tap.state == .ended else {
            return
        }

        selectedItemForView[collectionView]?.set(highlighted: false)
        selectedItemForView[collectionView]?.set(loading: false)
        selectedItemForView[collectionView] = searchItem
        selectedItemForView[collectionView]?.set(highlighted: true)
        toggle(to: collectionView) { [weak self] in
            self?.select(searchItem, in: collectionView)
        }
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let searchItems = searchItemsForView[collectionView] else {
            return 0
        }

        return searchItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let searchItemView = collectionView.makeItem(withIdentifier: SearchItemView.identifier, for: indexPath) as? SearchItemView, let searchItems = searchItemsForView[collectionView] else {
            return NSCollectionViewItem()
        }

        searchItemView.type = selectedType
        searchItemView.item = searchItems.at(index: indexPath.item)
        return searchItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.size.width, height: Constants.searchItemHeight)
    }


    // MARK: Overrides

    override func animateViewIn() {
        primaryCollectionView.alphaValue = 0
        windowDragArea.alphaValue = 0
        secondaryCollectionView.alphaValue = 0
        tertiaryCollectionView.alphaValue = 0
        secondaryTextField.alphaValue = 0
        tertiaryTextField.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            primaryCollectionView.animator().alphaValue = 1
            windowDragArea.animator().alphaValue = 1
        })
    }

    override func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                WindowManager.instance.closeWindow(for: strongSelf)
            }
        })
    }


    // MARK: Helpers

    private func select(_ view: SearchItemView, in collectionView: NSCollectionView) {
        guard view == selectedItemForView[collectionView] else {
            return
        }
        
        switch collectionView {
        case primaryCollectionView:
            if let recordType = view.item as? RecordType {
                selectedType = recordType
                searchItemsForView[secondaryCollectionView] = searchItems(for: recordType)
                secondaryTextField.attributedStringValue = title(for: recordType)
                secondaryCollectionView.reloadData()
                toggle(to: secondaryCollectionView)
            }
        case secondaryCollectionView:
            if let selectedType = selectedType, let group = view.item as? LetterGroup {
                RecordFactory.records(for: selectedType, group: group) { [weak self] records in
                    if let records = records {
                        self?.load(records, of: selectedType)
                    }
                }
            }
        case tertiaryCollectionView:
            if let record = view.item as? RecordDisplayable {
                display(record)
            }
        default:
            break
        }
    }

    private func toggle(to view: NSCollectionView, completion: (() -> Void)? = nil) {
        guard let window = view.window, let index = collectionViews.index(of: view) else {
            return
        }

        // Unselect nested search items
        collectionViews.enumerated().forEach { indexOfView, collectionView in
            if indexOfView > index {
                selectedItemForView[collectionView]?.set(highlighted: false)
                selectedItemForView[collectionView]?.set(loading: false)
            }
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            for indexOfView in 0 ..< collectionViews.count {
                collectionViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
                titleViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
            }
        }, completionHandler: completion)

        var frame = window.frame
        frame.size.width = style.searchWindowSize.width * CGFloat(index + 1)
        window.setFrame(frame, display: true, animate: true)
    }

    /// Returns a collection of search items used as the second level of a search query
    private func searchItems(for type: RecordType) -> [SearchItemDisplayable] {
        switch type {
        case .event, .artifact, .organization, .theme:
            return LetterGroup.allValues
        case .school:
            return Province.allValues
        }
    }

    /// Returns the attributed string to present as a tile in the window drag area
    private func title(for type: RecordType) -> NSAttributedString {
        switch type {
        case .event, .artifact, .organization, .theme:
            return NSAttributedString(string: "Range", attributes: style.windowTitleAttributes)
        case .school:
            return NSAttributedString(string: "Province", attributes: style.windowTitleAttributes)
        }
    }

    /// Loads records into and toggles the tertiary collection view
    private func load(_ records: [RecordDisplayable], of type: RecordType) {
        searchItemsForView[tertiaryCollectionView] = records
        tertiaryCollectionView.reloadData()
        tertiaryTextField.attributedStringValue = NSAttributedString(string: type.title, attributes: style.windowTitleAttributes)
        toggle(to: tertiaryCollectionView)
    }

    private func display(_ record: RecordDisplayable) {
        guard let window = view.window else {
            return
        }

        let location = CGPoint(x: window.frame.maxX + style.windowMargins, y: window.frame.minY)
        RecordFactory.record(for: record.type, id: record.id) { record in
            if let record = record {
                WindowManager.instance.display(.record(record), at: location)
            }
        }
    }
}
