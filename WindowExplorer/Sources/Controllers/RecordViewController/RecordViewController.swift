//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MacGestures


class RecordViewController: BaseViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, RecordFilterDelegate {
    static let storyboard = "Record"

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var relatedItemsHeader: NSView!
    @IBOutlet weak var relatedItemsHeaderHighlight: NSView!
    @IBOutlet weak var relatedRecordsLabel: NSTextField!
    @IBOutlet weak var relatedRecordsTypeLabel: NSTextField!
    @IBOutlet weak var mediaView: NSCollectionView!
    @IBOutlet weak var mediaCollectionClipView: NSClipView!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var stackScrollView: FadingScrollView!
    @IBOutlet weak var stackClipView: NSClipView!
    @IBOutlet weak var relatedItemsView: NSCollectionView!
    @IBOutlet weak var relatedRecordCollectionClipView: NSClipView!
    @IBOutlet weak var relatedRecordScrollView: FadingScrollView!
    @IBOutlet weak var relatedRecordsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeWindowTapArea: NSView!
    @IBOutlet weak var showRelatedItemsArea: NSView!
    @IBOutlet weak var hideRelatedItemsArea: NSView!
    @IBOutlet weak var showRelatedItemsImage: NSImageView!
    @IBOutlet weak var placeHolderImage: NSImageView!
    @IBOutlet weak var recordTypeSelectionView: RecordTypeSelectionView!
    @IBOutlet weak var expandImageView: NSImageView!
    @IBOutlet weak var arrowIndicatorContainerView: NSView!

    var record: Record!
    private var displayedRelatedRecords = [Record]()
    private var selectedRecords = Set<Record>()
    private var highlightedRecordForTouch = [Touch: Record]()
    private var pageControl = PageControl()
    private var relatedItemsFilterType = RecordFilterType.all
    private var currentLayout = RelatedItemViewLayout.list
    private var showingRelatedItems = false
    private var toggling = false

    private struct Constants {
        static let allRecordsTitle = "RECORDS"
        static let animationDuration = 0.5
        static let animationDistanceThreshold: CGFloat = 20
        static let showRelatedItemViewRotation: CGFloat = 45
        static let relatedItemsViewMargin: CGFloat = 12
        static let relatedRecordsAnimationDuration = 0.15
        static let relatedItemsViewAnimationDuration = 0.35
        static let pageControlHeight: CGFloat = 20
        static let stackViewTopInset: CGFloat = 15
        static let stackViewBottomInset: CGFloat = 15
        static let expandImageViewCornerRadius: CGFloat = 2.0
        static let relatedImagesAnimationTime = 0.1
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSublayers()
        setupRelationshipHelper()
        setupMediaView()
        setupStackview()
        setupGestures()
        setupRelatedItemsView()
        animateViewIn()
        resetCloseWindowTimer()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        updateArrowIndicatorView()
    }


    // MARK: Setup

    private func setupSublayers() {
        detailView.alphaValue = 0
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = style.darkBackground.cgColor
        relatedItemsHeader.wantsLayer = true
        relatedItemsHeader.layer?.backgroundColor = style.darkBackgroundOpaque.cgColor
        relatedItemsHeaderHighlight.wantsLayer = true
        relatedItemsHeaderHighlight.layer?.backgroundColor = record.type.color.cgColor
        windowDragAreaHighlight.layer?.backgroundColor = record.type.color.cgColor
        expandImageView.wantsLayer = true
        expandImageView.layer?.cornerRadius = Constants.expandImageViewCornerRadius
        expandImageView.layer?.backgroundColor = style.darkBackground.cgColor
        expandImageView.isHidden = record.media.isEmpty
        placeHolderImage.isHidden = !record.media.isEmpty
    }

    private func setupRelationshipHelper() {
        relationshipHelper = RelationshipHelper()
        relationshipHelper?.parent = self
        relationshipHelper?.controllerClosed = { [weak self] controller in
            self?.unselectRelatedRecord(for: controller)
        }
    }

    private func setupMediaView() {
        mediaView.register(MediaItemView.self, forItemWithIdentifier: MediaItemView.identifier)
        mediaView.frame = NSRect(origin: mediaView.frame.origin, size: NSSize(width: CGFloat(record.media.count) * mediaCollectionClipView.frame.size.width, height: mediaView.frame.height))
        placeHolderImage.image = record.type.placeholder.tinted(with: record.type.color)
        pageControl.color = .white
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.wantsLayer = true
        detailView.addSubview(pageControl)

        pageControl.centerXAnchor.constraint(equalTo: detailView.centerXAnchor).isActive = true
        pageControl.widthAnchor.constraint(equalTo: detailView.widthAnchor).isActive = true
        pageControl.topAnchor.constraint(equalTo: mediaView.bottomAnchor).isActive = true
        pageControl.heightAnchor.constraint(equalToConstant: Constants.pageControlHeight).isActive = true
        pageControl.numberOfPages = UInt(record?.media.count ?? 0)
    }

    private func setupRelatedItemsView() {
        displayedRelatedRecords = record.relatedRecords
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(RelatedItemListView.self, forItemWithIdentifier: RelatedItemListView.identifier)
        relatedItemsView.register(RelatedItemImageView.self, forItemWithIdentifier: RelatedItemImageView.identifier)
        relatedRecordScrollView.verticalScroller?.alphaValue = 0
        relatedRecordsLabel.alphaValue = 0
        relatedRecordsLabel.attributedStringValue = NSAttributedString(string: relatedRecordsLabel.stringValue, attributes: style.relatedItemsTitleAttributes)
        relatedRecordsTypeLabel.alphaValue = 0
        relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: Constants.allRecordsTitle.uppercased(), attributes: style.relatedItemsTitleAttributes)
        showRelatedItemsImage.isHidden = record.relatedRecords.isEmpty
        recordTypeSelectionView.alphaValue = 0
        recordTypeSelectionView.wantsLayer = true
        recordTypeSelectionView.layer?.backgroundColor = style.darkBackground.cgColor
        recordTypeSelectionView.initialize(with: record, manager: gestureManager)
        recordTypeSelectionView.delegate = self
        updateRelatedRecordsHeight()
    }

    private func setupGestures() {
        let nsToggleRelatedItemClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleRelatedItemToggleClick(_:)))
        showRelatedItemsArea.addGestureRecognizer(nsToggleRelatedItemClickGesture)

        let nsMediaItemClick = NSClickGestureRecognizer(target: self, action: #selector(handleCollectionViewClick(_:)))
        mediaView.addGestureRecognizer(nsMediaItemClick)

        let collectionViewPanGesture = PanGestureRecognizer()
        gestureManager.add(collectionViewPanGesture, to: mediaView)
        collectionViewPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewPan(gesture)
        }

        let collectionViewTapGesture = TapGestureRecognizer(withDelay: true)
        gestureManager.add(collectionViewTapGesture, to: mediaView)
        collectionViewTapGesture.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewTap(gesture)
        }

        gestureManager.add(windowPanGesture, to: relatedItemsHeader)

        let relatedViewPan = PanGestureRecognizer()
        gestureManager.add(relatedViewPan, to: relatedItemsView)
        relatedViewPan.gestureUpdated = { [weak self] gesture in
            self?.handleRelatedViewPan(gesture)
        }

        let relatedItemTap = MultiTapGestureRecognizer(withDelay: true)
        gestureManager.add(relatedItemTap, to: relatedItemsView)
        relatedItemTap.touchUpdated = { [weak self] touch, state in
            self?.handleRelatedItemMultiTap(touch, state: state)
        }

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: stackView)
        stackViewPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleStackViewPan(gesture)
        }

        let showRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(showRelatedItemsTap, to: showRelatedItemsArea)
        gestureManager.add(showRelatedItemsTap, to: hideRelatedItemsArea)
        showRelatedItemsTap.gestureUpdated = { [weak self] gesture in
            self?.handleToggleRelatedItemsTap(gesture)
        }

        let arrowIndicatorTap = TapGestureRecognizer()
        gestureManager.add(arrowIndicatorTap, to: arrowIndicatorContainerView)
        arrowIndicatorTap.gestureUpdated = { [weak self] gesture in
            self?.handleArrowIndicatorTap(gesture)
        }
    }

    private func setupStackview() {
        let stackViewEdgeInsets = NSEdgeInsets(top: Constants.stackViewTopInset, left: 0, bottom: Constants.stackViewBottomInset, right: 0)
        stackView.edgeInsets = stackViewEdgeInsets
        stackScrollView.updateGradient()

        let titleAttributedString = NSAttributedString(string: record.shortestTitle(), attributes: style.recordLargeTitleAttributes)
        let titleTextField = textField(for: titleAttributedString)
        stackView.addView(titleTextField, in: .top)
        stackView.setCustomSpacing(style.largeTitleTrailingSpace, after: titleTextField)

        if let dates = record.dates {
            var dateAttributes = style.recordDateAttributes
            dateAttributes[.foregroundColor] = record.type.color
            let dateAttributedString = NSAttributedString(string: dates.description(small: false), attributes: dateAttributes)
            let dateTextField = textField(for: dateAttributedString)
            stackView.addView(dateTextField, in: .top)
            stackView.setCustomSpacing(style.dateTrailingSpace, after: dateTextField)
        } else {
            stackView.setCustomSpacing(style.missingDateTitleTrailingSpace, after: titleTextField)
        }

        if let description = record.description, !description.isEmpty {
            let descriptionHeaderAttributedString = NSAttributedString(string: "Description", attributes: style.recordSmallHeaderAttributes)
            let descriptionHeaderTextField = textField(for: descriptionHeaderAttributedString)
            stackView.addView(descriptionHeaderTextField, in: .top)
            stackView.setCustomSpacing(style.smallHeaderTrailingSpace, after: descriptionHeaderTextField)
            let descriptionAttributedString = NSAttributedString(string: description, attributes: style.recordDescriptionAttributes)
            let descriptionTextField = textField(for: descriptionAttributedString)
            stackView.addView(descriptionTextField, in: .top)
            stackView.setCustomSpacing(style.descriptionTrailingSpace, after: descriptionTextField)
        }

        if let comments = record.comments, !comments.isEmpty {
            let commentsHeaderAttributedString = NSAttributedString(string: "Curatorial Comments", attributes: style.recordSmallHeaderAttributes)
            let commentsHeaderTextField = textField(for: commentsHeaderAttributedString)
            stackView.addView(commentsHeaderTextField, in: .top)
            stackView.setCustomSpacing(style.smallHeaderTrailingSpace, after: commentsHeaderTextField)
            let commentsAttributedString = NSAttributedString(string: comments, attributes: style.recordDescriptionAttributes)
            let commentsTextField = textField(for: commentsAttributedString)
            stackView.addView(commentsTextField, in: .top)
            stackView.setCustomSpacing(style.descriptionTrailingSpace, after: commentsTextField)
        }
    }


    // MARK: Gesture Handling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
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
            animateCollectionView(to: origin, duration: Double(duration), for: Int(index))
        default:
            return
        }
    }

    private var selectedMediaItem: MediaItemView? {
        didSet {
            oldValue?.set(highlighted: false)
            selectedMediaItem?.set(highlighted: true)
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, !animating else {
            return
        }

        let rect = mediaView.visibleRect
        let offset = rect.origin.x / rect.width
        let index = Int(round(offset))
        let indexPath = IndexPath(item: index, section: 0)

        if let mediaItem = mediaView.item(at: indexPath) as? MediaItemView {
            switch tap.state {
            case .began:
                selectedMediaItem = mediaItem
            case .failed:
                selectedMediaItem = nil
            case .ended:
                selectedMediaItem = mediaItem
                if let selectedMedia = selectedMediaItem?.media, let windowType = WindowType(for: selectedMedia) {
                    relationshipHelper?.display(windowType)
                }
                selectedMediaItem = nil
            default:
                return
            }
        }
    }

    private func handleRelatedViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = relatedItemsView.visibleRect
            rect.origin.y += pan.delta.dy
            relatedItemsView.scrollToVisible(rect)
            relatedRecordScrollView.updateGradient()
        default:
            return
        }
    }

    private func handleToggleRelatedItemsTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !record.relatedRecords.isEmpty, !animating, !toggling else {
            return
        }

        toggleRelatedItems()
        relatedRecordScrollView.updateGradient()
    }

    private func handleRelatedItemMultiTap(_ touch: Touch, state: GestureState) {
        switch state {
        case .began:
            if let indexPath = relatedItemsView.indexPathForItem(at: touch.position + relatedItemsView.visibleRect.origin),
                let relatedItem = relatedItemsView.item(at: indexPath) as? RelatedItemView,
                let record = relatedItem.record {
                relatedItem.set(highlighted: true)
                highlightedRecordForTouch[touch] = record
            }
        case .failed:
            if highlightedRecordForTouch[touch] != nil {
                highlightedRecordForTouch.removeValue(forKey: touch)
                updateRelatedItemHighlights()
            }
        case .ended:
            if let record = highlightedRecordForTouch[touch] {
                selectRelatedRecord(record)
                highlightedRecordForTouch.removeValue(forKey: touch)
            }
        default:
            break
        }
    }

    private func handleStackViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var point = stackClipView.visibleRect.origin
            point.y += pan.delta.dy
            stackClipView.scroll(point)
            stackScrollView.updateGradient()
            updateArrowIndicatorView()
        default:
            return
        }
    }

    private func handleArrowIndicatorTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .ended:
            let delta = stackScrollView.frame.height - 20
            var point = stackClipView.visibleRect.origin
            point.y += delta
            stackScrollView.updateGradient(with: delta)
            updateArrowIndicatorView(with: delta)

            NSAnimationContext.runAnimationGroup({ _ in
                NSAnimationContext.current.duration = Constants.animationDuration
                stackClipView.animator().setBoundsOrigin(point)
            })
        default:
            return
        }
    }

    @objc
    private func handleRelatedItemToggleClick(_ gesture: NSClickGestureRecognizer) {
        toggleRelatedItems()
    }

    @objc
    private func handleCollectionViewClick(_ gesture: NSClickGestureRecognizer) {
        if animating {
            return
        }

        let rect = mediaView.visibleRect
        let offset = rect.origin.x / rect.width
        let index = Int(round(offset))
        let indexPath = IndexPath(item: index, section: 0)
        guard let mediaItem = mediaView.item(at: indexPath) as? MediaItemView else {
            return
        }

        switch gesture.state {
        case .began:
            selectedMediaItem = mediaItem
        case .failed:
            selectedMediaItem = nil
        case .ended:
            selectedMediaItem = mediaItem
            if let selectedMedia = selectedMediaItem?.media, let windowType = WindowType(for: selectedMedia) {
                relationshipHelper?.display(windowType)
            }
            selectedMediaItem = nil
        default:
            return
        }
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case mediaView:
            return record.media.count
        case relatedItemsView:
            return displayedRelatedRecords.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch collectionView {
        case mediaView:
            if let mediaItemView = collectionView.makeItem(withIdentifier: MediaItemView.identifier, for: indexPath) as? MediaItemView {
                mediaItemView.media = record.media.at(index: indexPath.item)
                mediaItemView.tintColor = record.type.color
                return mediaItemView
            }
        case relatedItemsView:
            if let relatedItem = collectionView.makeItem(withIdentifier: relatedItemsFilterType.layout.identifier, for: indexPath) as? RelatedItemView {
                relatedItem.filterType = relatedItemsFilterType
                relatedItem.tintColor = record.type.color
                let relatedRecord = displayedRelatedRecords[indexPath.item]
                relatedItem.record = relatedRecord
                let highlightedRecords = Set(highlightedRecordForTouch.values)
                let highlighted = highlightedRecords.contains(relatedRecord) || selectedRecords.contains(relatedRecord)
                relatedItem.set(highlighted: highlighted)
                return relatedItem
            }
        default:
            break
        }

        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        switch collectionView {
        case mediaView:
            return mediaCollectionClipView.frame.size
        case relatedItemsView:
            return relatedItemsFilterType.layout.itemSize
        default:
            return .zero
        }
    }


    // MARK: Overrides

    override func animateViewIn() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            detailView.animator().alphaValue = 1
        })
    }

    override func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            relatedItemsHeader.animator().alphaValue = 0
            detailView.animator().alphaValue = 0
            relatedItemsView.animator().alphaValue = 0
            windowDragArea.animator().alphaValue = 0
            recordTypeSelectionView.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }


    // MARK: RecordFilterDelegate

    func canSelectFilterType(_ type: RecordFilterType) -> Bool {
        return showingRelatedItems && !toggling
    }

    func didSelectFilterType(_ type: RecordFilterType) {
        toggling = true
        relatedItemsFilterType = type

        // Transitions the related records and their title by fading out & in
        fadeRelatedRecordsAndTitle(out: true, completion: { [weak self] in
            self?.updateRelatedRecordsHeight()
            self?.didToggleFilterType(type: type) { [weak self] in
                self?.updateRelatedRecordsHeight()
                self?.toggling = false
                if let strongSelf = self {
                    strongSelf.relatedItemsView.scroll(.zero)
                    strongSelf.fadeRelatedRecordsAndTitle(out: false, completion: {})
                    strongSelf.updateRelatedRecordsHeight()
                }
            }
        })
    }

    private func didToggleFilterType(type: RecordFilterType, completion: @escaping () -> Void) {
        let titleForType = type.title?.uppercased() ?? Constants.allRecordsTitle
        relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: titleForType, attributes: style.relatedItemsTitleAttributes)
        displayedRelatedRecords = record.relatedRecords(filterType: type)
        relatedItemsView.reloadData()
        updateRelatedItemsLayout(completion: completion)
    }


    // MARK: Helpers

    private func animateCollectionView(to point: CGPoint, duration: TimeInterval, for index: Int) {
        mediaView.animate(to: point, duration: duration, completion: { [weak self] in
            self?.pageControl.selectedPage = UInt(index)
        })
    }

    private func toggleRelatedItems(completion: (() -> Void)? = nil) {
        guard let window = view.window else {
            return
        }

        toggling = true
        relatedItemsView.isHidden = false
        let alpha: CGFloat = showingRelatedItems ? 0 : 1

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            self?.relatedItemsView.animator().alphaValue = 0
            self?.relatedRecordsLabel.animator().alphaValue = alpha
            self?.relatedRecordsTypeLabel.animator().alphaValue = alpha
            self?.recordTypeSelectionView.animator().alphaValue = alpha
            self?.showRelatedItemsImage.animator().alphaValue = 1 - alpha
            }, completionHandler: { [weak self] in
                self?.didToggleRelatedItems { [weak self] in
                    self?.toggling = false
                    completion?()
                }
        })

        let relatedItemsWidthWithMargins = relatedItemsFilterType.layout.rowWidth + Constants.relatedItemsViewMargin
        let offset = showingRelatedItems ? -relatedItemsWidthWithMargins : relatedItemsWidthWithMargins
        var frame = window.frame
        frame.size.width += offset
        setWindow(frame: frame, animate: true)
        showingRelatedItems = !showingRelatedItems
    }

    private func didToggleRelatedItems(completion: (() -> Void)?) {
        relatedItemsView.isHidden = !showingRelatedItems

        if showingRelatedItems {
            relatedRecordScrollView.updateGradient(forced: true)
            fadeRelatedRecordsAndTitle(out: false, completion: completion)
        } else {
            completion?()
        }
    }

    private func selectRelatedRecord(_ record: Record) {
        if !showingRelatedItems {
            return
        }

        if let windowType = WindowType(for: record) {
            selectedRecords.insert(record)
            relationshipHelper?.display(windowType)
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

    private func unselectRelatedRecord(for controller: BaseViewController) {
        guard let record = record(from: controller) else {
            return
        }

        selectedRecords.remove(record)
        updateRelatedItemHighlights()
    }

    /// Updates all the visible related item views and updates their highlighted status
    private func updateRelatedItemHighlights() {
        let highlightedRecords = Set(highlightedRecordForTouch.values)

        for view in relatedItemsView.visibleItems().compactMap({ $0 as? RelatedItemView }) {
            if let record = view.record {
                let highlighted = highlightedRecords.contains(record) || selectedRecords.contains(record)
                view.set(highlighted: highlighted)
            }
        }
    }

    // Adjusts the size of the window if necessary, which changes the relatedRecordView through autolayout
    private func updateRelatedItemsLayout(completion: @escaping () -> Void) {
        guard let window = view.window, relatedItemsFilterType.layout != currentLayout else {
            completion()
            return
        }

        currentLayout = relatedItemsFilterType.layout
        let offset = relatedItemsFilterType.layout.rowWidth - relatedItemsView.frame.width
        var frame = window.frame
        frame.size.width += offset
        setWindow(frame: frame, animate: true, completion: completion)
    }

    private func fadeRelatedRecordsAndTitle(out: Bool, completion: (() -> Void)?) {
        let alpha: CGFloat = out ? 0 : 1

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.relatedRecordsAnimationDuration
            self?.relatedItemsView.animator().alphaValue = alpha
            self?.relatedRecordsTypeLabel.animator().alphaValue = alpha
        }, completionHandler: {
            completion?()
        })
    }

    private func updateArrowIndicatorView(with delta: CGFloat = 0) {
        if let scrollView = stackView.enclosingScrollView {
            arrowIndicatorContainerView.isHidden = scrollView.hasReachedBottom(with: delta)
        }
    }

    private func updateRelatedRecordsHeight() {
        let numberOfRecords = displayedRelatedRecords.count
        let numberOfRows = ceil(CGFloat(numberOfRecords) / relatedItemsFilterType.layout.itemsPerRow)
        let numberOfSpaces = max(0, numberOfRows - 1)
        let height = ceil(numberOfRows * relatedItemsFilterType.layout.itemSize.height + numberOfSpaces * style.relatedRecordsItemSpacing)

        relatedRecordsHeightConstraint.constant = min(height, style.relatedRecordsMaxSize.height)
        relatedRecordScrollView.updateGradient(forced: true, height: height)
        relatedRecordScrollView.layoutSubtreeIfNeeded()
    }

    private func textField(for attributedString: NSAttributedString) -> NSTextField {
        let label = NSTextField(labelWithAttributedString: attributedString)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        return label
    }
}
