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
    @IBOutlet weak var collapseButtonArea: NSView!
    
    private var selectedType: RecordType?
    private var selectedIndexForView = [NSCollectionView: IndexPath]()

    private lazy var titleViews: [NSTextField] = [titleLabel, secondaryTextField, tertiaryTextField]
    private lazy var collectionViews: [NSCollectionView] = [primaryCollectionView, secondaryCollectionView, tertiaryCollectionView]
    private lazy var focusedCollectionView: NSCollectionView = primaryCollectionView
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

            let collectionViewTap = TapGestureRecognizer(withDelay: true)
            gestureManager.add(collectionViewTap, to: collectionView)
            collectionViewTap.gestureUpdated = handleCollectionViewTap(_:)
        }

        let collapseButtonTap = TapGestureRecognizer()
        gestureManager.add(collapseButtonTap, to: collapseButtonArea)
        collapseButtonTap.gestureUpdated = handleCollapseButtonTap(_:)
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
            tap.state == .ended,
            let collectionView = gestureManager.view(for: tap) as? NSCollectionView,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let searchItem = collectionView.item(at: indexPath) as? SearchItemView,
            indexPath != selectedIndexForView[collectionView] else {
            return
        }

        select(searchItem)
        toggle(to: collectionView) { [weak self] in
            self?.showResults(for: searchItem)
        }
    }

    private func handleCollapseButtonTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        if let index = collectionViews.index(of: focusedCollectionView), let previous = collectionViews.at(index: index - 1) {
            unselectItem(for: previous)
            toggle(to: previous)
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

        // Check if index path is selected
        if let selectedIndex = selectedIndexForView[collectionView] {
            searchItemView.set(highlighted: selectedIndex == indexPath)
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
        collapseButtonArea.alphaValue = 0
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

    private func select(_ item: SearchItemView) {
        guard let collectionView = item.collectionView, let indexPath = collectionView.indexPath(for: item) else {
            return
        }

        unselectItem(for: collectionView)
        selectedIndexForView[collectionView] = indexPath
        item.set(highlighted: true)
    }

    // Removes all state from the currently selected view of the given collectionview
    private func unselectItem(for collectionView: NSCollectionView) {
        guard let indexPath = selectedIndexForView[collectionView] else {
            return
        }

        selectedIndexForView.removeValue(forKey: collectionView)
        if let item = collectionView.item(at: indexPath) as? SearchItemView {
            item.set(highlighted: false)
            item.set(loading: false)
        }
    }

    private func showResults(for view: SearchItemView) {
        guard let collectionView = view.collectionView, let indexPath = collectionView.indexPath(for: view), indexPath == selectedIndexForView[collectionView] else {
            return
        }

        switch collectionView {
        case primaryCollectionView:
            if let recordType = view.item as? RecordType {
                selectedType = recordType
                searchItemsForView[secondaryCollectionView] = searchItems(for: recordType)
                secondaryTextField.attributedStringValue = title(for: recordType)
                secondaryCollectionView.reloadData()
                secondaryCollectionView.scroll(.zero)
                toggle(to: secondaryCollectionView)
            }
        case secondaryCollectionView:
            if let group = view.item as? LetterGroup, let type = selectedType {
                view.set(loading: true)
                RecordFactory.records(for: type, in: group) { [weak self] records in
                    view.set(loading: false)
                    if let records = records {
                        self?.load(records)
                    }
                }
            } else if let province = view.item as? Province {
                let schools = GeocodeHelper.instance.schools(for: province)
                load(schools)
            }
        case tertiaryCollectionView:
            if let record = view.item as? RecordDisplayable {
                display(record)
            }
        default:
            break
        }
    }

    /// Toggles to the given collection view, unselects items for hidden collection views
    private func toggle(to view: NSCollectionView, completion: (() -> Void)? = nil) {
        guard let window = view.window, let index = collectionViews.index(of: view) else {
            return
        }

        // Unselect nested search items
        collectionViews.enumerated().forEach { indexOfView, collectionView in
            if indexOfView > index {
                unselectItem(for: collectionView)
            }
        }

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            for indexOfView in 0 ..< collectionViews.count {
                collectionViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
                titleViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
            }
            collapseButtonArea.animator().alphaValue = index.isZero ? 0 : 1
        }, completionHandler: completion)

        var frame = window.frame
        frame.size.width = style.searchWindowSize.width * CGFloat(index + 1)
        window.setFrame(frame, display: true, animate: true)
        focusedCollectionView = view
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
    private func load(_ records: [RecordDisplayable]) {
        searchItemsForView[tertiaryCollectionView] = records
        tertiaryCollectionView.reloadData()
        tertiaryCollectionView.scroll(.zero)
        tertiaryTextField.attributedStringValue = NSAttributedString(string: selectedType?.title ?? "", attributes: style.windowTitleAttributes)
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
