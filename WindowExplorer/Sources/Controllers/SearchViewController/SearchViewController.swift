//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MacGestures


protocol SearchItemDisplayable {
    var title: String { get }
}

protocol SearchChild: class {
    var delegate: MenuDelegate? { get set }
    func setWindow(origin: CGPoint, animate: Bool, completion: (() -> Void)?)
}


class SearchViewController: BaseViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, SearchChild {
    static let storyboard = "Search"

    @IBOutlet weak var primaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryCollectionView: NSCollectionView!
    @IBOutlet weak var tertiaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryTextField: NSTextField!
    @IBOutlet weak var tertiaryTextField: NSTextField!
    @IBOutlet weak var collapseButtonArea: NSView!
    @IBOutlet weak var primaryScrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var secondaryScrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tertiaryScrollViewHeight: NSLayoutConstraint!

    weak var delegate: MenuDelegate?
    private var selectedType: RecordType?
    private var selectedGroup: SearchItemDisplayable?
    private var selectedRecords = Set<Record>()
    private var toggling = false

    private lazy var focusedCollectionView: NSCollectionView = primaryCollectionView
    private lazy var collectionViews: [NSCollectionView] = [primaryCollectionView, secondaryCollectionView, tertiaryCollectionView]
    private lazy var titleViews: [NSTextField] = [titleLabel, secondaryTextField, tertiaryTextField]
    private lazy var heightConstraintForView = [
        primaryCollectionView: primaryScrollViewHeight,
        secondaryCollectionView: secondaryScrollViewHeight,
        tertiaryCollectionView: tertiaryScrollViewHeight
    ]
    private lazy var searchItemsForView: [NSCollectionView: [SearchItemDisplayable]] = [
        primaryCollectionView: RecordType.searchValues,
        secondaryCollectionView: [],
        tertiaryCollectionView: []
    ]

    private struct Constants {
        static let animationDuration = 0.5
        static let searchItemHeight: CGFloat = 70
        static let defaultWindowHighlightColor = NSColor.white
        static let collectionViewMargin: CGFloat = 5
        static let maxCollectionViewHeight: CGFloat = 605
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: style.windowTitleAttributes)

        setupRelationshipHelper()
        setupGestures()
        setupScrollViews()
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

    private func setupRelationshipHelper() {
        relationshipHelper = RelationshipHelper()
        relationshipHelper?.parent = self
        relationshipHelper?.controllerClosed = { [weak self] controller in
            self?.unselectRecordForController(controller)
        }
    }

    private func setupGestures() {
        collectionViews.forEach { collectionView in
            let collectionViewPan = PanGestureRecognizer()
            gestureManager.add(collectionViewPan, to: collectionView)
            collectionViewPan.gestureUpdated = { [weak self] gesture in
                self?.handleCollectionViewPan(gesture)
            }

            let collectionViewTap = TapGestureRecognizer(withDelay: true)
            gestureManager.add(collectionViewTap, to: collectionView)
            collectionViewTap.gestureUpdated = { [weak self] gesture in
                self?.handleCollectionViewTap(gesture)
            }
        }

        let collapseButtonTap = TapGestureRecognizer()
        gestureManager.add(collapseButtonTap, to: collapseButtonArea)
        collapseButtonTap.gestureUpdated = { [weak self] gesture in
            self?.handleCollapseButtonTap(gesture)
        }

        let windowDragAreaTap = TapGestureRecognizer()
        gestureManager.add(windowDragAreaTap, to: windowDragArea)
        windowDragAreaTap.gestureUpdated = { [weak self] gesture in
            self?.handleWindowDragAreaTap(gesture)
        }
    }

    private func setupScrollViews() {
        let scrollViews = collectionViews.compactMap { $0.superview?.superview as? FadingScrollView }

        scrollViews.forEach { view in
            view.verticalScroller?.alphaValue = 0
            view.updateGradient()
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

        selectItem(for: searchItemView, in: collectionView)
    }

    private func handleWindowDragAreaTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer,
            tap.state == .ended,
            let positionOfTouch = tap.position else {
            return
        }

        let xPos = positionOfTouch.x
        let index = Int(xPos / style.searchWindowFrame.width)
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
                self?.unselectItems(for: previousCollectionView)
            })
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

        // Set the highlighted state of view
        if searchItemView.collectionView != tertiaryCollectionView, let selectedGroup = selectedGroup {
            searchItemView.set(highlighted: searchItemView.item.title == selectedGroup.title)
        } else if let record = searchItems.at(index: indexPath.item) as? Record {
            searchItemView.set(highlighted: selectedRecords.contains(record))
        }

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
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            self?.view.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }

    override func close() {
        delegate?.searchChildClosed()
        super.close()
    }


    // MARK: Selection Flow

    private func selectItem(for view: SearchItemView, in collectionView: NSCollectionView) {
        if toggling || isSelected(item: view.item) {
            return
        }

        // Select and highlight the item
        updateSelectionForItem(of: view, in: collectionView)

        // If item is a record, display it
        if let record = view.item as? Record {
            display(record)
            return
        }

        if let recordType = selectedType, let nextCollectionView = nextCollectionView(from: collectionView) {
            view.set(loading: true)
            toggle(to: collectionView) { [weak self] in
                SearchHelper.results(for: recordType, group: self?.selectedGroup) { results in
                    view.set(loading: false)
                    self?.display(results, in: nextCollectionView)
                }
            }
        }
    }

    private func isSelected(item: SearchItemDisplayable) -> Bool {
        switch item {
        case let recordType as RecordType:
            return recordType == selectedType
        case let letterGroup as LetterGroup:
            if let selectedGroup = selectedGroup as? LetterGroup {
                return letterGroup == selectedGroup
            }
        case let province as Province:
            if let selectedGroup = selectedGroup as? Province {
                return province == selectedGroup
            }
        case is Record:
            return false
        default:
            return false
        }

        return false
    }

    private func updateSelectionForItem(of view: SearchItemView, in collectionView: NSCollectionView) {
        switch collectionView {
        case primaryCollectionView:
            if let recordType = view.item as? RecordType {
                unselectItem(for: collectionView)
                selectedType = recordType
                updateWindowDragAreaHighlight(for: recordType)
            }
        case secondaryCollectionView:
            if let record = view.item as? Record {
                selectedRecords.insert(record)
            } else {
                unselectItem(for: collectionView)
                selectedGroup = view.item
            }
        case tertiaryCollectionView:
            if let record = view.item as? Record {
                selectedRecords.insert(record)
            }
        default:
            break
        }

        view.set(highlighted: true)
    }

    // Removes all state from the currently selected view of the given collectionview
    private func unselectItem(for collectionView: NSCollectionView) {
        let indexPaths = collectionView.indexPathsForVisibleItems()

        if collectionView == primaryCollectionView {
            selectedType = nil
            updateWindowDragAreaHighlight(for: nil)
        } else if collectionView == secondaryCollectionView {
            selectedGroup = nil
        }

        for index in indexPaths {
            if let item = collectionView.item(at: index) as? SearchItemView {
                item.set(highlighted: false)
                item.set(loading: false)
            }
        }
    }

    /// Toggles to the given collection view, unselects items for hidden collection views
    private func toggle(to view: NSCollectionView, completion: (() -> Void)? = nil) {
        guard let window = view.window, let index = collectionViews.index(of: view), view != focusedCollectionView else {
            completion?()
            return
        }

        toggling = true

        // Unselect nested search items
        collectionViews.enumerated().forEach { indexOfView, collectionView in
            if indexOfView > index {
                unselectItem(for: collectionView)
            }
        }

        // Fade titles of collapsing collection views
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            for indexOfView in 0 ..< collectionViews.count {
                self?.collectionViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
                self?.titleViews.at(index: indexOfView)?.animator().alphaValue = indexOfView <= index ? 1 : 0
            }
            self?.collapseButtonArea.animator().alphaValue = index.isZero ? 0 : 1
        })

        // Update position and size of window and child controllers
        var frame = window.frame
        frame.size.width = style.searchWindowFrame.width * CGFloat(index + 1) + Constants.collectionViewMargin * CGFloat(index)
        setWindow(frame: frame, animate: true, completion: { [weak self] in
            self?.toggling = false
            completion?()
        })
        focusedCollectionView = view
    }

    private func display(_ record: Record) {
        if let record = RecordManager.instance.record(for: record.type, id: record.id), let windowType = WindowType(for: record) {
            relationshipHelper?.display(windowType)
        }
    }

    private func display(_ items: [SearchItemDisplayable], in collectionView: NSCollectionView) {
        searchItemsForView[collectionView] = items
        collectionView.reloadData()
        collectionView.scroll(.zero)
        updateTitle(for: collectionView)
        toggle(to: collectionView)
        updateHeight(for: collectionView)
        updateGradient(for: collectionView, forced: true)
    }


    // MARK: Helpers

    private func nextCollectionView(from collectionView: NSCollectionView) -> NSCollectionView? {
        switch collectionView {
        case primaryCollectionView:
            return secondaryCollectionView
        case secondaryCollectionView:
            return tertiaryCollectionView
        default:
            return nil
        }
    }

    private func unselectItems(for collectionView: NSCollectionView?) {
        if let collectionView = collectionView {
            searchItemsForView[collectionView] = []
            collectionView.reloadData()
            updateHeight(for: collectionView)
        }
    }

    /// Returns the attributed string to present as a tile in the window drag area
    private func title(for type: RecordType) -> NSAttributedString {
        switch type {
        case .event, .artifact, .organization, .theme, .individual:
            return NSAttributedString(string: "Range", attributes: style.windowTitleAttributes)
        case .school:
            return NSAttributedString(string: "Province", attributes: style.windowTitleAttributes)
        case .collection:
            return NSAttributedString(string: "Topics", attributes: style.windowTitleAttributes)
        }
    }

    private func updateTitle(for collectionView: NSCollectionView) {
        guard let type = selectedType else {
            return
        }

        switch collectionView {
        case secondaryCollectionView:
            secondaryTextField.attributedStringValue = title(for: type)
        case tertiaryCollectionView:
            let title = "\(type.title) (\(selectedGroup?.title ?? ""))"
            tertiaryTextField.attributedStringValue = NSAttributedString(string: title, attributes: style.windowTitleAttributes)
        default:
            break
        }
    }

    private func updateWindowDragAreaHighlight(for recordType: RecordType?) {
        guard let recordType = recordType else {
            windowDragAreaHighlight.layer?.backgroundColor = Constants.defaultWindowHighlightColor.cgColor
            return
        }

        windowDragAreaHighlight.layer?.backgroundColor = recordType.color.cgColor
    }

    private func unselectRecordForController(_ controller: BaseViewController) {
        guard let record = record(from: controller) else {
            return
        }

        selectedRecords.remove(record)
        let secondaryItems = secondaryCollectionView.visibleItems().compactMap({ $0 as? SearchItemView })
        let tertiaryItems = tertiaryCollectionView.visibleItems().compactMap({ $0 as? SearchItemView })

        for view in secondaryItems + tertiaryItems {
            if let record = view.item as? Record {
                view.set(highlighted: selectedRecords.contains(record))
            }
        }
    }

    private func record(from controller: BaseViewController) -> Record? {
        switch controller {
        case let recordViewController as RecordViewController:
            return recordViewController.record
        case let recordCollectionViewController as RecordCollectionViewController:
            return recordCollectionViewController.record
        default:
            return nil
        }
    }

    private func updateHeight(for collectionView: NSCollectionView) {
        if let contentHeight = collectionView.collectionViewLayout?.collectionViewContentSize.height {
            let height = ceil(min(contentHeight, Constants.maxCollectionViewHeight))
            heightConstraintForView[collectionView]??.constant = height
            updateGradient(for: collectionView, forced: true, height: height)
            view.layoutSubtreeIfNeeded()
        }
    }

    private func updateGradient(for collectionView: NSCollectionView, forced: Bool = false, height: CGFloat? = nil) {
        if let scrollView = collectionView.superview?.superview as? FadingScrollView {
            scrollView.updateGradient(forced: forced, height: height)
        }
    }
}
