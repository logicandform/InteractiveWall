//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


protocol SearchItemDisplayable {
    var title: String { get }
}


protocol SearchViewDelegate: class {
    func searchDidClose()
}


fileprivate struct RecordProxy: Hashable {
    let id: Int
    let type: RecordType
}


class SearchViewController: BaseViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Search")

    @IBOutlet weak var primaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryCollectionView: NSCollectionView!
    @IBOutlet weak var tertiaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryTextField: NSTextField!
    @IBOutlet weak var tertiaryTextField: NSTextField!
    @IBOutlet weak var collapseButtonArea: NSView!
    @IBOutlet weak var primaryScrollView: FadingScrollView!
    @IBOutlet weak var secondaryScrollView: FadingScrollView!
    @IBOutlet weak var tertiaryScrollView: FadingScrollView!
    @IBOutlet weak var primaryScrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var secondaryScrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tertiaryScrollViewHeight: NSLayoutConstraint!

    weak var searchViewDelegate: SearchViewDelegate?
    private var selectedType: RecordType?
    private var selectedRecords = Set<RecordProxy>()
    private var selectedIndexForView = [NSCollectionView: IndexPath]()
    private let relationshipHelper = RelationshipHelper()

    private lazy var scrollViewForCollectionView = [primaryCollectionView: primaryScrollView, secondaryCollectionView: secondaryScrollView, tertiaryCollectionView: tertiaryScrollView]
    private lazy var heightForCollectionView = [primaryCollectionView: primaryScrollViewHeight, secondaryCollectionView: secondaryScrollViewHeight, tertiaryCollectionView: tertiaryScrollViewHeight]
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
        static let defaultWindowDragAreaColor = NSColor.lightGray
        static let collectionViewMargin: CGFloat = 5
        static let closeWindowTimeoutPeriod: TimeInterval = 300
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: style.windowTitleAttributes)
        relationshipHelper.parent = self
        relationshipHelper.controllerClosed = unselectRecordForController(_:)

        setupGestures()
        setupScrollViews()
        resetCloseWindowTimer()
        updateWindowDragAreaHighlight(for: selectedType)
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        updateHeight(for: primaryCollectionView)
        updateHeight(for: secondaryCollectionView)
        updateHeight(for: tertiaryCollectionView)
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

        let windowDragAreaTap = TapGestureRecognizer()
        gestureManager.add(windowDragAreaTap, to: windowDragArea)
        windowDragAreaTap.gestureUpdated = handleWindowDragAreaTap(_:)
    }

    private func setupScrollViews() {
        let scrollViews = collectionViews.compactMap { $0.superview?.superview as? FadingScrollView }

        scrollViews.forEach { view in
            view.verticalScroller?.alphaValue = 0
            view.updateGradient()
        }
    }


    // MARK: API

    func updateOrigin(to point: CGPoint, animating: Bool) {
        if animating {
            animate(to: point)
        } else {
            view.window?.setFrameOrigin(point)
        }

        relationshipHelper.reset()
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
            updateGradient(for: collectionView)
        default:
            return
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let collectionView = gestureManager.view(for: tap) as? NSCollectionView,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let searchItemView = collectionView.item(at: indexPath) as? SearchItemView else {
            return
        }

        // Only allow reselected of cells in the tertiaryViewController.
        if indexPath == selectedIndexForView[collectionView] && collectionView != tertiaryCollectionView {
            return
        }

        // Set the windowDragHighlight color before waiting to toggle collectionViews
        if let recordType = searchItemView.item as? RecordType {
            updateWindowDragAreaHighlight(for: recordType)
        }

        select(searchItemView)
        toggle(to: collectionView) { [weak self] in
            self?.showResults(for: searchItemView)
        }
    }

    private func handleWindowDragAreaTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer,
            tap.state == .ended,
            let positionOfTouch = tap.position else {
            return
        }

        let xPos = positionOfTouch.x
        let index = Int(xPos / style.searchWindowSize.width)

        if index < collectionViews.count - 1, let correspondingCollectionView = collectionViews.at(index: index), correspondingCollectionView != focusedCollectionView {
            unselectItem(for: correspondingCollectionView)
            toggle(to: correspondingCollectionView)
        }
    }

    private func handleCollapseButtonTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        if let index = collectionViews.index(of: focusedCollectionView), let previous = collectionViews.at(index: index - 1) {
            let previousCollectionView = focusedCollectionView
            unselectItem(for: previous)
            toggle(to: previous, completion: { [weak self] in
                self?.deleteItems(in: previousCollectionView)
            })
        }
    }

    private func deleteItems(in previousCollectionView: NSCollectionView?) {
        if let previousCollectionView = previousCollectionView {
            searchItemsForView[previousCollectionView] = []
            previousCollectionView.reloadData()
            updateHeight(for: previousCollectionView)
        }
    }

    override func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        case .began, .ended:
            relationshipHelper.reset()
        default:
            return
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

        // Set the highlighted state of view
        if let selectedIndex = selectedIndexForView[collectionView], searchItemView.collectionView != tertiaryCollectionView {
            searchItemView.set(highlighted: selectedIndex == indexPath)
        } else if let record = searchItems.at(index: indexPath.item) as? RecordDisplayable {
            searchItemView.set(highlighted: isSelected(record))
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
            self?.close()
        })
    }

    override func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.closeTimerFired()
        }
    }

    override func close() {
        searchViewDelegate?.searchDidClose()
        super.close()
    }


    // MARK: Helpers

    private func select(_ item: SearchItemView) {
        guard let collectionView = item.collectionView, let indexPath = collectionView.indexPath(for: item) else {
            return
        }

        if collectionView == tertiaryCollectionView, let record = item.item as? RecordDisplayable {
            selectedIndexForView.removeValue(forKey: collectionView)
            selectedRecords.insert(RecordProxy(id: record.id, type: record.type))
        } else {
            unselectItem(for: collectionView)
        }

        selectedIndexForView[collectionView] = indexPath
        item.set(highlighted: true)
    }

    private func closeTimerFired() {
        if relationshipHelper.isEmpty() {
            animateViewOut()
        }
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
        guard let collectionView = view.collectionView else {
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
                        self?.load(records, group: group.title)
                    }
                }
            } else if let province = view.item as? Province {
                let schools = GeocodeHelper.instance.schools(for: province).sorted { $0.title < $1.title }
                load(schools, group: province.abbreviation)
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

        updateHeight(for: view)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            for indexOfView in 0 ..< collectionViews.count {
                collectionViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
                titleViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
            }
            collapseButtonArea.animator().alphaValue = index.isZero ? 0 : 1
        }, completionHandler: completion)

        var frame = window.frame
        frame.size.width = style.searchWindowSize.width * CGFloat(index + 1) + Constants.collectionViewMargin * CGFloat(index)
        window.setFrame(frame, display: true, animate: true)
        focusedCollectionView = view
        updateGradient(for: view)
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

    /// Loads records into and toggles the tertiary collection view, from intermediary group
    private func load(_ records: [RecordDisplayable], group: String) {
        guard let selectedType = selectedType else {
            return
        }

        searchItemsForView[tertiaryCollectionView] = records
        tertiaryCollectionView.reloadData()
        tertiaryCollectionView.scroll(.zero)
        let title = "\(selectedType.title) (\(group))"
        tertiaryTextField.attributedStringValue = NSAttributedString(string: title, attributes: style.windowTitleAttributes)
        toggle(to: tertiaryCollectionView)
    }

    private func display(_ record: RecordDisplayable) {
        RecordFactory.record(for: record.type, id: record.id) { [weak self] record in
            if let record = record {
                self?.relationshipHelper.display(WindowType.record(record))
            }
        }
    }

    private func updateWindowDragAreaHighlight(for recordType: RecordType?) {
        guard let recordType = recordType else {
            windowDragAreaHighlight.layer?.backgroundColor = Constants.defaultWindowDragAreaColor.cgColor
            return
        }

        windowDragAreaHighlight.layer?.backgroundColor = recordType.color.cgColor
    }

    private func isSelected(_ record: RecordDisplayable) -> Bool {
        let recordProxy = RecordProxy(id: record.id, type: record.type)
        return selectedRecords.contains(recordProxy)
    }

    private func updateGradient(for view: NSCollectionView) {
        if let scrollView = view.superview?.superview as? FadingScrollView {
            scrollView.updateGradient()
        }
    }

    private func unselectRecordForController(_ controller: BaseViewController) {
        guard let recordViewController = controller as? RecordViewController, let record = recordViewController.record else {
            return
        }

        let recordProxy = RecordProxy(id: record.id, type: record.type)
        selectedRecords.remove(recordProxy)

        for view in tertiaryCollectionView.visibleItems().compactMap({ $0 as? SearchItemView }) {
            if let record = view.item as? RecordDisplayable {
                let recordProxy = RecordProxy(id: record.id, type: record.type)
                view.set(highlighted: selectedRecords.contains(recordProxy))
            }
        }
    }

    private func updateHeight(for collectionView: NSCollectionView) {
        let maxHeight = style.searchScrollViewSize.height

        if let height = collectionView.collectionViewLayout?.collectionViewContentSize.height, let heightConstraint = heightForCollectionView[collectionView], let scrollView = scrollViewForCollectionView[collectionView] {
            if height > maxHeight {
                heightConstraint?.constant = maxHeight
            } else {
                heightConstraint?.constant = height
            }
            scrollView?.updateConstraints()
        }
    }
}
