//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: BaseViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, NSTableViewDataSource, NSTableViewDelegate, ControllerDelegate {

    static let storyboard = NSStoryboard.Name(rawValue: "Record")

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var relatedRecordsLabel: NSTextField!
    @IBOutlet weak var relatedRecordsTypeLabel: NSTextField!
    @IBOutlet weak var mediaView: NSCollectionView!
    @IBOutlet weak var mediaCollectionClipView: NSClipView!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var stackClipView: NSClipView!
    @IBOutlet weak var relatedItemsView: NSCollectionView!
    @IBOutlet weak var relatedRecordCollectionClipView: NSClipView!
    @IBOutlet weak var closeWindowTapArea: NSView!
    @IBOutlet weak var toggleRelatedItemsArea: NSView!
    @IBOutlet weak var toggleRelatedItemsImage: NSImageView!
    @IBOutlet weak var placeHolderImage: NSImageView!
    @IBOutlet weak var recordTypeSelectionView: RecordTypeSelectionView!

    var record: RecordDisplayable!
    private var pageControl = PageControl()
    private var positionForMediaController = [MediaViewController: Int?]()
    private var showingRelatedItems = false
    private var relatedItemsFilterType: RecordFilterType?

    private struct Constants {
        static let allRecordsTitle = "RECORDS"
        static let animationDuration = 0.5
        static let relatedItemCollectionViewItemHeight: CGFloat = 80
        static let mediaControllerOffset = 50
        static let closeWindowTimeoutPeriod: TimeInterval = 300
        static let animationDistanceThreshold: CGFloat = 20
        static let showRelatedItemViewRotation: CGFloat = 45
        static let relatedItemsViewMargin: CGFloat = 8
        static let relatedRecordsTitleAnimationDuration = 0.15
        static let relatedItemsViewAnimationDuration = 0.35
        static let pageControlHeight: CGFloat = 20
        static let stackViewTopInset: CGFloat = 15
        static let stackViewBottomInset: CGFloat = 15
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.alphaValue = 0
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = style.darkBackground.cgColor
        placeHolderImage.isHidden = !record.media.isEmpty

        setupMediaView()
        setupWindowDragArea()
        setupStackview()
        setupGestures()
        setupRelatedItemsView()
        animateViewIn()
        resetCloseWindowTimer()
    }


    // MARK: Setup

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
        relatedItemsView.register(RelatedItemView.self, forItemWithIdentifier: RelatedItemView.identifier)
        relatedRecordsLabel.alphaValue = 0
        relatedRecordsLabel.attributedStringValue = NSAttributedString(string: relatedRecordsLabel.stringValue, attributes: style.relatedItemsTitleAttributes)
        relatedRecordsTypeLabel.alphaValue = 0
        relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: Constants.allRecordsTitle.uppercased(), attributes: style.relatedItemsTitleAttributes)
        toggleRelatedItemsImage.isHidden = record.relatedRecords.isEmpty
        toggleRelatedItemsImage.frameCenterRotation = Constants.showRelatedItemViewRotation
        recordTypeSelectionView.stackview.alphaValue = 0
        recordTypeSelectionView.initialize(with: record, manager: gestureManager)
        recordTypeSelectionView.selectionCallback = didSelectRelatedItemsFilterType(_:)
    }

    private func setupGestures() {
        let nsToggleRelatedItemClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleRelatedItemToggleClick(_:)))
        toggleRelatedItemsArea.addGestureRecognizer(nsToggleRelatedItemClickGesture)

        let nsMediaItemClick = NSClickGestureRecognizer(target: self, action: #selector(handleCollectionViewClick(_:)))
        mediaView.addGestureRecognizer(nsMediaItemClick)

        let collectionViewPanGesture = PanGestureRecognizer()
        gestureManager.add(collectionViewPanGesture, to: mediaView)
        collectionViewPanGesture.gestureUpdated = handleCollectionViewPan(_:)

        let collectionViewTapGesture = TapGestureRecognizer(withDelay: true)
        gestureManager.add(collectionViewTapGesture, to: mediaView)
        collectionViewTapGesture.gestureUpdated = handleCollectionViewTap(_:)

        let relatedViewPan = PanGestureRecognizer()
        gestureManager.add(relatedViewPan, to: relatedItemsView)
        relatedViewPan.gestureUpdated = handleRelatedViewPan(_:)

        let relatedItemTap = TapGestureRecognizer(withDelay: true)
        gestureManager.add(relatedItemTap, to: relatedItemsView)
        relatedItemTap.gestureUpdated = handleRelatedItemTap(_:)

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: stackView)
        stackViewPanGesture.gestureUpdated = handleStackViewPan(_:)

        let toggleRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(toggleRelatedItemsTap, to: toggleRelatedItemsArea)
        toggleRelatedItemsTap.gestureUpdated = handleRelatedItemsToggle(_:)
    }

    private func setupWindowDragArea() {
        windowDragAreaHighlight.layer?.backgroundColor = record.type.color.cgColor
    }

    private func setupStackview() {
        let stackViewEdgeInsets = NSEdgeInsets(top: Constants.stackViewTopInset, left: 0, bottom: Constants.stackViewBottomInset, right: 0)
        stackView.edgeInsets = stackViewEdgeInsets

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
            if let selectedMedia = selectedMediaItem?.media {
                selectMediaItem(selectedMedia)
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
        default:
            return
        }
    }

    private func handleRelatedItemsToggle(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !record.relatedRecords.isEmpty else {
            return
        }

        toggleRelatedItems()
    }

    private var selectedRelatedItem: RelatedItemView? {
        didSet {
            oldValue?.set(highlighted: false)
            selectedRelatedItem?.set(highlighted: true)
        }
    }

    private func handleRelatedItemTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let location = tap.position, !animating else {
            return
        }

        let locationInTable = location + relatedItemsView.visibleRect.origin
        guard let indexPath = relatedItemsView.indexPathForItem(at: locationInTable), let relatedItemView = relatedItemsView.item(at: indexPath) as? RelatedItemView else {
            return
        }

        switch tap.state {
        case .began:
            selectedRelatedItem = relatedItemView
        case .failed:
            selectedRelatedItem = nil
        case .ended:
            selectedRelatedItem = relatedItemView
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
            resetMediaControllerPositions()
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
            if let selectedMedia = selectedMediaItem?.media {
                selectMediaItem(selectedMedia)
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
            if let type = relatedItemsFilterType {
                return record.relatedRecords(of: type).count
            } else {
                return record.relatedRecords.count
            }
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
            if let relatedItemView = collectionView.makeItem(withIdentifier: RelatedItemView.identifier, for: indexPath) as? RelatedItemView {
                if let type = relatedItemsFilterType {
                    relatedItemView.record = record.relatedRecords(of: type).at(index: indexPath.item)
                } else {
                    relatedItemView.record = record.relatedRecords.at(index: indexPath.item)
                }
                relatedItemView.tintColor = record.type.color
                return relatedItemView
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
            return CGSize(width: collectionView.frame.width, height: Constants.relatedItemCollectionViewItemHeight)
        default:
            return .zero
        }
    }


    // MARK: MediaControllerDelegate

    func controllerDidClose(_ controller: MediaViewController) {
        positionForMediaController.removeValue(forKey: controller)
        resetCloseWindowTimer()
    }

    func controllerDidMove(_ controller: MediaViewController) {
        positionForMediaController[controller] = nil as Int?
    }

    func recordFrameAndPosition(for controller: MediaViewController) -> (frame: CGRect, position: Int)? {
        guard let window = view.window else {
            return nil
        }

        if let position = positionForMediaController[controller], position != nil {
            return (window.frame, position!)
        } else {
            return (window.frame, getMediaControllerPosition())
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
        }, completionHandler: {
            WindowManager.instance.closeWindow(for: self)
        })
    }

    override func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.closeTimerFired()
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
            self?.relatedItemsView.animator().alphaValue = alpha
            self?.relatedRecordsLabel.animator().alphaValue = alpha
            self?.relatedRecordsTypeLabel.animator().alphaValue = alpha
            self?.recordTypeSelectionView.stackview.animator().alphaValue = alpha
            self?.toggleRelatedItemsImage.animator().frameCenterRotation = showingRelatedItems ? Constants.showRelatedItemViewRotation : 0
            }, completionHandler: { [weak self] in
                if let strongSelf = self {
                    strongSelf.relatedItemsView.isHidden = !strongSelf.showingRelatedItems
                }
                completion?()
        })

        let relatedItemsWidth = relatedItemsView.frame.width + Constants.relatedItemsViewMargin * 2
        let offset = showingRelatedItems ? -relatedItemsWidth : relatedItemsWidth
        var frame = window.frame
        frame.size.width += offset
        window.setFrame(frame, display: true, animate: true)
        showingRelatedItems = !showingRelatedItems
    }

    private func selectRelatedRecord(_ record: RecordDisplayable) {
        guard let window = view.window else {
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

    private func selectMediaItem(_ media: Media) {
        guard let windowType = WindowType(for: media) else {
            return
        }

        let controller = positionForMediaController.keys.first(where: { $0.media == media })
        let position = getMediaControllerPosition()

        if let controller = controller {
            // If the controller is in the correct position, bring it to the front, else animate to origin
            if let position = positionForMediaController[controller], position != nil {
                controller.view.window?.makeKeyAndOrderFront(self)
            } else {
                controller.updatePosition(animating: true)
                positionForMediaController[controller] = position
            }
        } else if let controller = WindowManager.instance.display(windowType) as? MediaViewController {
            controller.delegate = self
            // Image view controller takes care of setting its own position after its image has loaded in
            if controller is PlayerViewController || controller is PDFViewController {
                controller.updatePosition(animating: false)
            }
            positionForMediaController[controller] = position
        }
    }

    /// Gets the first available media controller position
    private func getMediaControllerPosition() -> Int {
        let currentPositions = positionForMediaController.values

        for position in 0 ..< record.media.count {
            if !currentPositions.contains(position) {
                return position
            }
        }

        return record.media.count
    }

    private func closeTimerFired() {
        // Reset timer gets recalled once a child MediaViewContoller gets closed
        if positionForMediaController.keys.isEmpty {
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

    private func resetMediaControllerPositions() {
        positionForMediaController.keys.forEach { positionForMediaController[$0] = nil as Int? }
    }

    /// Handle a change of record type from the RelatedItemsHeaderView
    private func didSelectRelatedItemsFilterType(_ type: RecordFilterType?) {
        let titleForType = type?.title?.uppercased() ?? Constants.allRecordsTitle
        transitionRelatedRecordsTitle(to: titleForType)

        relatedItemsFilterType = type
        fadeRelatedItemsView(out: true, completion: { [weak self] in
            self?.relatedItemsView.reloadData()
            self?.fadeRelatedItemsView(out: false, completion: {})
        })
    }

    /// Transitions the related records title by fading out & in
    private func transitionRelatedRecordsTitle(to title: String) {
        fadeRelatedRecordsTitle(out: true) { [weak self] in
            if let strongSelf = self {
                strongSelf.relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: title, attributes: style.relatedItemsTitleAttributes)
                strongSelf.fadeRelatedRecordsTitle(out: false, completion: {})
            }
        }
    }

    private func fadeRelatedRecordsTitle(out: Bool, completion: @escaping () -> Void) {
        let alpha: CGFloat = out ? 0 : 1

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.relatedRecordsTitleAnimationDuration
            self?.relatedRecordsTypeLabel.animator().alphaValue = alpha
        }, completionHandler: {
            completion()
        })
    }

    private func fadeRelatedItemsView(out: Bool, completion: @escaping () -> Void) {
        let alpha: CGFloat = out ? 0 : 1

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.relatedItemsViewAnimationDuration
            self?.relatedItemsView.animator().alphaValue = alpha
        }, completionHandler: {
            completion()
        })
    }
}
