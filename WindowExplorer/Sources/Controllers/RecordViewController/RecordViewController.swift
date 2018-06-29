//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: BaseViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, NSTableViewDataSource, NSTableViewDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Record")

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

    var record: RecordDisplayable!
    private let relationshipHelper = RelationshipHelper()
    private var relatedRecords: [RecordDisplayable]!
    private var pageControl = PageControl()
    private var showingRelatedItems = false
    private var relatedItemsFilterType = RecordFilterType.all
    private var currentLayout = RelatedItemViewLayout.list

    private struct Constants {
        static let allRecordsTitle = "RECORDS"
        static let animationDuration = 0.5
        static let closeWindowTimeoutPeriod = 300.0
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
        relationshipHelper.parent = self
        placeHolderImage.isHidden = !record.media.isEmpty

        setupSublayers()
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
        relatedItemsHeader.layer?.backgroundColor = style.darkBackground.cgColor
        relatedItemsHeaderHighlight.wantsLayer = true
        relatedItemsHeaderHighlight.layer?.backgroundColor = record.type.color.cgColor
        windowDragAreaHighlight.layer?.backgroundColor = record.type.color.cgColor
        expandImageView.wantsLayer = true
        expandImageView.layer?.cornerRadius = Constants.expandImageViewCornerRadius
        expandImageView.layer?.backgroundColor = style.darkBackground.cgColor
        expandImageView.isHidden = record.media.isEmpty
        arrowIndicatorContainerView.wantsLayer = true
        arrowIndicatorContainerView.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func setupMediaView() {
        mediaView.register(MediaItemView.self, forItemWithIdentifier: MediaItemView.identifier)
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
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(RelatedItemListView.self, forItemWithIdentifier: RelatedItemListView.identifier)
        relatedItemsView.register(RelatedItemImageView.self, forItemWithIdentifier: RelatedItemImageView.identifier)
        relatedRecordScrollView.verticalScroller?.alphaValue = 0
        relatedRecordsLabel.alphaValue = 0
        relatedRecordsLabel.attributedStringValue = NSAttributedString(string: relatedRecordsLabel.stringValue, attributes: style.relatedItemsTitleAttributes)
        relatedRecordsTypeLabel.alphaValue = 0
        relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: Constants.allRecordsTitle.uppercased(), attributes: style.relatedItemsTitleAttributes)
        showRelatedItemsImage.isHidden = record.relatedRecords.isEmpty
        recordTypeSelectionView.stackview.alphaValue = 0
        recordTypeSelectionView.initialize(with: record, manager: gestureManager)
        recordTypeSelectionView.selectionCallback = didSelectRelatedItemsFilterType(_:)
        relatedRecords = record.relatedRecords.sorted(by: { $0.priority > $1.priority })
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

        let relatedItemTap = TapGestureRecognizer(withDelay: true)
        gestureManager.add(relatedItemTap, to: relatedItemsView)
        relatedItemTap.gestureUpdated = { [weak self] gesture in
            self?.handleRelatedItemTap(gesture)
        }

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: stackView)
        stackViewPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleStackViewPan(gesture)
        }

        let showRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(showRelatedItemsTap, to: showRelatedItemsArea)
        showRelatedItemsTap.gestureUpdated = { [weak self] gesture in
            self?.handleShowRelatedItemsTap(gesture)
        }

        let hideRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(hideRelatedItemsTap, to: hideRelatedItemsArea)
        hideRelatedItemsTap.gestureUpdated = { [weak self] gesture in
            self?.handleHideRelatedItemsTap(gesture)
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

        for label in record.textFields {
            stackView.insertView(label, at: stackView.subviews.count, in: .top)
        }
    }


    // MARK: API

    override func animate(to origin: NSPoint) {
        guard let window = self.view.window, let screen = window.screen, shouldAnimate(to: origin), !gestureManager.isActive() else {
            return
        }

        gestureManager.invalidateAllGestures()
        resetCloseWindowTimer()
        animating = true
        window.makeKeyAndOrderFront(self)

        let frame = CGRect(origin: origin, size: window.frame.size)
        let offset = abs(window.frame.minX - origin.x) / screen.frame.width
        let duration = max(Double(offset), Constants.animationDuration)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = duration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            window.animator().setFrame(frame, display: true, animate: true)
        }, completionHandler: { [weak self] in
            self?.animating = false
        })
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
            animateCollectionView(to: origin, duration: duration, for: Int(index))
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
        guard let mediaItem = mediaView.item(at: indexPath) as? MediaItemView else {
            return
        }

        switch tap.state {
        case .began:
            selectedMediaItem = mediaItem
        case .failed:
            selectedMediaItem = nil
        case .ended:
            selectedMediaItem = mediaItem
            if let selectedMedia = selectedMediaItem?.media, let windowType = WindowType(for: selectedMedia) {
                relationshipHelper.display(windowType)
            }
            selectedMediaItem = nil
        default:
            return
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

    private func handleShowRelatedItemsTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !record.relatedRecords.isEmpty, !showRelatedItemsImage.alphaValue.isZero else {
            return
        }

        toggleRelatedItems()
        relatedRecordScrollView.updateGradient()
    }

    private func handleHideRelatedItemsTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        toggleRelatedItems()
        relatedRecordScrollView.updateGradient()
    }

    private var selectedRelatedItem: RelatedItemView? {
        didSet {
            oldValue?.set(highlighted: false)
            selectedRelatedItem?.set(highlighted: true)
        }
    }

    private func handleRelatedItemTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer,
            let location = tap.position,
            let indexPath = relatedItemsView.indexPathForItem(at: location + relatedItemsView.visibleRect.origin),
            let relatedItem = relatedItemsView.item(at: indexPath) as? RelatedItemView else {
                selectedRelatedItem = nil
                return
        }

        switch tap.state {
        case .began:
            selectedRelatedItem = relatedItem
        case .failed:
            selectedRelatedItem = nil
        case .ended:
            selectedRelatedItem = relatedItem
            if let selectedRecord = selectedRelatedItem?.record {
                selectRelatedRecord(selectedRecord)
            }
            selectedRelatedItem = nil
        default:
            return
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
            parentDelegate?.controllerDidMove(self)
            relationshipHelper.reset()
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
                relationshipHelper.display(windowType)
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
            return record.relatedRecords(of: relatedItemsFilterType).count
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
                relatedItem.record = record.relatedRecords(of: relatedItemsFilterType).at(index: indexPath.item)
                relatedItem.tintColor = record.type.color
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
            detailView.animator().alphaValue = 0
            relatedItemsView.animator().alphaValue = 0
            windowDragArea.animator().alphaValue = 0
            recordTypeSelectionView.stackview.animator().alphaValue = 0
            relatedItemsHeader.animator().alphaValue = 0
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
        parentDelegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    override func updatePosition(animating: Bool) {
        if let frameAndPosition = parentDelegate?.frameAndPosition(for: self) {
            updateOrigin(from: frameAndPosition.frame, at: frameAndPosition.position, animating: animating)
        }
    }


    // MARK: Helpers

    private func animateCollectionView(to point: CGPoint, duration: CGFloat, for index: Int) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = TimeInterval(duration)
            mediaCollectionClipView.animator().setBoundsOrigin(point)
            }, completionHandler: { [weak self] in
                self?.pageControl.selectedPage = UInt(index)
        })
    }

    private func toggleRelatedItems(completion: (() -> Void)? = nil) {
        guard let window = view.window else {
            return
        }

        relatedItemsView.isHidden = false
        let alpha: CGFloat = showingRelatedItems ? 0 : 1

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            self?.relatedItemsView.animator().alphaValue = 0
            self?.relatedRecordsLabel.animator().alphaValue = alpha
            self?.relatedRecordsTypeLabel.animator().alphaValue = alpha
            self?.recordTypeSelectionView.stackview.animator().alphaValue = alpha
            self?.showRelatedItemsImage.animator().alphaValue = 1 - alpha
            }, completionHandler: { [weak self] in
                self?.didToggleRelatedItems(completion: completion)
        })

        let relatedItemsWidthWithMargins = relatedItemsFilterType.layout.rowWidth + Constants.relatedItemsViewMargin
        let offset = showingRelatedItems ? -relatedItemsWidthWithMargins : relatedItemsWidthWithMargins
        var frame = window.frame
        frame.size.width += offset
        window.setFrame(frame, display: true, animate: true)
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

    private func selectRelatedRecord(_ record: RecordDisplayable) {
        guard let window = view.window, showingRelatedItems else {
            return
        }

        toggleRelatedItems(completion: {
            let origin = CGPoint(x: window.frame.maxX + style.windowMargins, y: window.frame.minY)
            RecordFactory.record(for: record.type, id: record.id, completion: { newRecord in
                if let loadedRecord = newRecord {
                    WindowManager.instance.display(.record(loadedRecord), at: origin)
                }
            })
        })
    }

    private func closeTimerFired() {
        if relationshipHelper.isEmpty() {
            animateViewOut()
        }
    }

    /// If the position of the controller is close enough to the origin of animation returns false
    private func shouldAnimate(to origin: NSPoint) -> Bool {
        guard let currentOrigin = view.window?.frame.origin else {
            return false
        }

        let diff = currentOrigin - origin
        return abs(diff.x) > Constants.animationDistanceThreshold || abs(diff.y) > Constants.animationDistanceThreshold ? true : false
    }

    /// Handle a change of record type from the RelatedItemsHeaderView
    private func didSelectRelatedItemsFilterType(_ type: RecordFilterType) {
        guard showingRelatedItems else {
            return
        }

        relatedItemsFilterType = type
        let titleForType = type.title?.uppercased() ?? Constants.allRecordsTitle

        // Transitions the related records and their title by fading out & in
        fadeRelatedRecordsAndTitle(out: true, completion: { [weak self] in
            if let strongSelf = self {
                strongSelf.relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: titleForType, attributes: style.relatedItemsTitleAttributes)
                strongSelf.relatedItemsView.reloadData()
                strongSelf.updateRelatedItemsLayout { [weak self] in
                    if let strongSelf = self {
                        strongSelf.relatedItemsView.scroll(.zero)
                        strongSelf.fadeRelatedRecordsAndTitle(out: false, completion: {})
                    }
                }
            }
        })
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
        view.window?.setFrame(frame, display: true, animate: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.relatedImagesAnimationTime) {
            completion()
        }
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

        updateRelatedRecordsHeight()
    }

    private func updateOrigin(from recordFrame: CGRect, at position: Int, animating: Bool) {
        let offsetX = CGFloat(position * style.controllerOffset)
        let offsetY = CGFloat(position * -style.controllerOffset)
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)
        var origin = CGPoint(x: recordFrame.maxX + style.windowMargins + offsetX, y: recordFrame.maxY + offsetY - view.frame.height)
        // Need to change logic here such that it can also spawn to the left (need to calculate # per column, then use that as an index to multiple it to the left) (may need to store columns in parentDelegate?)
        if origin.x > lastScreen.frame.maxX - view.frame.width / 2 {
            if lastScreen.frame.height - recordFrame.maxY < view.frame.height + style.windowMargins - 2 * offsetY {
                // Below
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y - recordFrame.height - style.windowMargins)
            } else {
                // Above
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y + view.frame.height + style.windowMargins - 2 * offsetY)
            }
        }

        if origin.y + view.frame.height + style.windowMargins < lastScreen.frame.minY {
            close()
        }

        if animating {
            animate(to: origin)
        } else {
            view.window?.setFrameOrigin(origin)
        }

        // Need to set to 1 if on a new column, else
    }

    private func updateArrowIndicatorView(with delta: CGFloat = 0) {
        if let scrollView = stackView.enclosingScrollView {
            arrowIndicatorContainerView.isHidden = scrollView.hasReachedBottom(with: delta)
        }
    }

    private func updateRelatedRecordsHeight() {
        let maxHeight = style.relatedRecordsMaxSize.height
        let numberOfRecords = record.relatedRecords(of: relatedItemsFilterType).count
        let numberOfSpaces = numberOfRecords > 1 ? numberOfRecords - 1 : 0
        let height = CGFloat(numberOfRecords) * style.listItemHeight + CGFloat(numberOfSpaces) * style.itemSpacing
        relatedRecordsHeightConstraint.constant = height > maxHeight ? maxHeight : height
        relatedRecordScrollView.updateGradient(forced: true, height: height)
    }
}
