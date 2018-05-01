//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit

class RecordViewController: NSViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource, NSTableViewDataSource, NSTableViewDelegate, GestureResponder, MediaControllerDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Record")

    @IBOutlet weak var detailView: NSView!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var relatedRecordsLabel: NSTextField!
    @IBOutlet weak var relatedRecordsTypeLabel: NSTextField!
    @IBOutlet weak var mediaView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var stackClipView: NSClipView!
    @IBOutlet weak var relatedItemsView: NSTableView!
    @IBOutlet weak var closeWindowTapArea: NSView!
    @IBOutlet weak var toggleRelatedItemsArea: NSView!
    @IBOutlet weak var toggleRelatedItemsImage: NSImageView!
    @IBOutlet weak var placeHolderImage: NSImageView!
    @IBOutlet weak var recordTypeSelectionView: RecordTypeSelectionView!

    var record: RecordDisplayable!
    private(set) var gestureManager: GestureManager!
    private var pageControl = PageControl()
    private var positionForMediaController = [MediaViewController: Int?]()
    private var animating = false
    private var showingRelatedItems = false
    private weak var closeWindowTimer: Foundation.Timer?
    private var relatedItemsType: RecordType?
    private var hiddenRelatedItems = IndexSet()
    private var windowPanGesture: PanGestureRecognizer!

    private struct Constants {
        static let relatedRecordsTitle = "RELATED"
        static let allRecordsTitle = "RECORDS"
        static let animationDuration = 0.5
        static let tableRowHeight: CGFloat = 80
        static let mediaControllerOffset = 50
        static let closeWindowTimeoutPeriod: TimeInterval = 300
        static let animationDistanceThreshold: CGFloat = 20
        static let fontName = "Soleil"
        static let fontSize: CGFloat = 13
        static let fontColor: NSColor = .white
        static let kern: CGFloat = 0.5
        static let screenEdgeBuffer: CGFloat = 80
        static let showRelatedItemViewRotation: CGFloat = 45
        static let relatedItemsViewMargin: CGFloat = 8
        static let relatedRecordsTitleAnimationDuration = 0.15
        static let pageControlHeight: CGFloat = 20
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView.alphaValue = 0
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = style.darkBackground.cgColor
        placeHolderImage.isHidden = !record.media.isEmpty
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = recievedTouch(touch:)

        setupMediaView()
        setupRelatedItemsView()
        setupWindowDragArea()
        setupStackview()
        setupGestures()
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
    
    private var titleBarAttributes : [NSAttributedStringKey : Any] {
        let font = NSFont(name: Constants.fontName, size: Constants.fontSize) ?? NSFont.systemFont(ofSize: Constants.fontSize)
        
        return [.font: font,
                .foregroundColor: Constants.fontColor,
                .kern: Constants.kern,
                .baselineOffset: font.fontName == Constants.fontName ? 1 : 0]
    }

    private func setupRelatedItemsView() {
        relatedItemsView.alphaValue = 0
        relatedItemsView.register(NSNib(nibNamed: RelatedItemView.nibName, bundle: nil), forIdentifier: RelatedItemView.interfaceIdentifier)
        relatedItemsView.backgroundColor = .clear
        relatedRecordsLabel.alphaValue = 0
        relatedRecordsLabel.attributedStringValue = NSAttributedString(string: Constants.relatedRecordsTitle, attributes: titleBarAttributes)
        relatedRecordsTypeLabel.alphaValue = 0
        relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: Constants.allRecordsTitle, attributes: titleBarAttributes)
        toggleRelatedItemsImage.isHidden = record.relatedRecords.isEmpty
        toggleRelatedItemsImage.frameCenterRotation = Constants.showRelatedItemViewRotation
        recordTypeSelectionView.stackview.alphaValue = 0
        recordTypeSelectionView.initialize(with: record, manager: gestureManager)
        recordTypeSelectionView.selectionCallback = didSelectRelatedItemsType(_:)
    }

    private func setupGestures() {
        let mousePan = NSPanGestureRecognizer(target: self, action: #selector(handleMouseDrag(_:)))
        windowDragArea.addGestureRecognizer(mousePan)

        let nsToggleRelatedItemClickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleRelatedItemToggleClick(_:)))
        toggleRelatedItemsArea.addGestureRecognizer(nsToggleRelatedItemClickGesture)

        let collectionViewPanGesture = PanGestureRecognizer()
        gestureManager.add(collectionViewPanGesture, to: mediaView)
        collectionViewPanGesture.gestureUpdated = handleCollectionViewPan(_:)

        let collectionViewTapGesture = TapGestureRecognizer()
        gestureManager.add(collectionViewTapGesture, to: mediaView)
        collectionViewTapGesture.gestureUpdated = handleCollectionViewTap(_:)

        let relatedViewPan = PanGestureRecognizer()
        gestureManager.add(relatedViewPan, to: relatedItemsView)
        relatedViewPan.gestureUpdated = handleRelatedViewPan(_:)

        let relatedItemTap = TapGestureRecognizer()
        gestureManager.add(relatedItemTap, to: relatedItemsView)
        relatedItemTap.gestureUpdated = handleRelatedItemTap(_:)

        windowPanGesture = PanGestureRecognizer()
        gestureManager.add(windowPanGesture, to: windowDragArea)
        windowPanGesture.gestureUpdated = handleWindowPan(_:)

        let stackViewPanGesture = PanGestureRecognizer()
        gestureManager.add(stackViewPanGesture, to: stackView)
        stackViewPanGesture.gestureUpdated = handleStackViewPan(_:)

        let toggleRelatedItemsTap = TapGestureRecognizer()
        gestureManager.add(toggleRelatedItemsTap, to: toggleRelatedItemsArea)
        toggleRelatedItemsTap.gestureUpdated = handleRelatedItemsToggle(_:)

        let tapToClose = TapGestureRecognizer()
        gestureManager.add(tapToClose, to: closeWindowTapArea)
        tapToClose.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended {
                self?.animateViewOut()
            }
        }
    }

    private func setupWindowDragArea() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = record.type.color.cgColor
    }

    private func setupStackview() {
        for label in record.textFields {
            stackView.insertView(label, at: stackView.subviews.count, in: .top)
        }
    }


    // MARK: API

    func animate(to origin: NSPoint) {
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
        let row = relatedItemsView.row(at: locationInTable)
        guard row >= 0, let relatedItemView = relatedItemsView.view(atColumn: 0, row: row, makeIfNecessary: false) as? RelatedItemView else {
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

    private func handleWindowPan(_ gesture: GestureRecognizer) {
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
    private func handleMouseDrag(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window, !animating else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }

    @objc
    private func handleRelatedItemToggleClick(_ gesture: NSClickGestureRecognizer) {
        toggleRelatedItems()
    }


    // MARK: IB-Actions

    @IBAction func toggleRelatedItems(_ sender: Any) {
        toggleRelatedItems()
    }

    @IBAction func closeWindowTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return record.media.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let mediaItemView = collectionView.makeItem(withIdentifier: MediaItemView.identifier, for: indexPath) as? MediaItemView else {
            return NSCollectionViewItem()
        }

        mediaItemView.media = record.media[indexPath.item]
        mediaItemView.tintColor = record.type.color
        return mediaItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return collectionClipView.frame.size
    }


    // MARK: NSTableViewDataSource & NSTableViewDelegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let type = relatedItemsType else {
            return record.relatedRecords.count
        }

        return record.relatedRecords(of: type).count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let relatedItemView = tableView.makeView(withIdentifier: RelatedItemView.interfaceIdentifier, owner: self) as? RelatedItemView else {
            return nil
        }

        if let type = relatedItemsType {
            let relatedRecords = record.relatedRecords(of: type)
            relatedItemView.record = relatedRecords[row]
        } else {
            relatedItemView.record = record.relatedRecords[row]
        }

        relatedItemView.tintColor = record.type.color
        return relatedItemView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constants.tableRowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }


    // MARK: MediaControllerDelegate

    func controllerDidClose(_ controller: MediaViewController) {
        positionForMediaController.removeValue(forKey: controller)
        resetCloseWindowTimer()
    }

    func controllerDidMove(_ controller: MediaViewController) {
        positionForMediaController[controller] = nil as Int?
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        // Calculate the center box of the drag area in the window's coordinate system
        let dragAreaInWindow = windowDragArea.frame.transformed(from: view.frame).transformed(from: window.frame)
        let adjustedWidth = dragAreaInWindow.width / 2
        let smallDragArea = CGRect(x: dragAreaInWindow.minX + adjustedWidth / 2, y: dragAreaInWindow.minY, width: adjustedWidth, height: dragAreaInWindow.height)
        return bounds.contains(smallDragArea)
    }


    // MARK: Helpers

    private func animateViewIn() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            detailView.animator().alphaValue = 1
        })
    }

    private func animateViewOut() {
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

    private func animateCollectionView(to point: CGPoint, duration: CGFloat, for index: Int) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = TimeInterval(duration)
            collectionClipView.animator().setBoundsOrigin(point)
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
        guard let window = view.window, let windowType = WindowType(for: media) else {
            return
        }

        let controller = positionForMediaController.keys.first(where: { $0.media == media })
        let position = getMediaControllerPosition()
        let offset = CGVector(dx: position * Constants.mediaControllerOffset, dy: position * -Constants.mediaControllerOffset)
        var origin = CGPoint(x: window.frame.maxX + style.windowMargins + offset.dx, y: window.frame.maxY + offset.dy)
        origin.y -= controller?.view.frame.height ?? windowType.size.height
        if windowType.canAdjustOrigin {
            origin = constrainedToApplication(origin, for: window, type: windowType)
        }

        if let controller = controller {
            // If the controller is in the correct position, bring it to the front, else animate to point
            if let position = positionForMediaController[controller], position != nil {
                controller.view.window?.makeKeyAndOrderFront(self)
            } else {
                controller.animate(to: origin)
                positionForMediaController[controller] = position
            }
        } else if let controller = WindowManager.instance.display(windowType, at: origin) as? MediaViewController {
            positionForMediaController[controller] = position
            controller.delegate = self
        }
    }

    /// Returns the given origin translated to the application frame if necessary
    private func constrainedToApplication(_ origin: CGPoint, for window: NSWindow, type: WindowType) -> CGPoint {
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)

        if origin.x > lastScreen.frame.maxX - Constants.screenEdgeBuffer {
            if lastScreen.frame.height - window.frame.maxY < type.size.height {
                return CGPoint(x: lastScreen.frame.maxX - type.size.width - style.windowMargins, y: origin.y - view.frame.height - style.windowMargins)
            } else {
                return CGPoint(x: lastScreen.frame.maxX - type.size.width - style.windowMargins, y: origin.y + type.size.height + style.windowMargins)
            }
        }

        return origin
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

    private func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.closeTimerFired()
        }
    }

    private func closeTimerFired() {
        // Reset timer gets recalled once a child MediaViewContoller gets closed
        if positionForMediaController.keys.isEmpty {
            animateViewOut()
        }
    }

    private func recievedTouch(touch: Touch) {
        switch touch.state {
        case .down, .up:
            resetCloseWindowTimer()
            if windowPanGesture.state == .momentum {
                windowPanGesture.invalidate()
            }
        case .moved, .indicator:
            return
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
    private func didSelectRelatedItemsType(_ type: RecordType?) {
        let titleForType = type?.title ?? Constants.allRecordsTitle
        transitionRelatedRecordsTitle(to: titleForType)

        var itemsToRemove = IndexSet()
        if let type = type {
            for (index, record) in record.relatedRecords.enumerated() {
                if record.type != type {
                    itemsToRemove.insert(index)
                }
            }
        }

        relatedItemsType = type
        relatedItemsView.beginUpdates()
        relatedItemsView.insertRows(at: hiddenRelatedItems, withAnimation: .effectFade)
        relatedItemsView.removeRows(at: itemsToRemove, withAnimation: .effectFade)
        relatedItemsView.endUpdates()
        hiddenRelatedItems = itemsToRemove
    }

    /// Transitions the related records title by fading out & in
    private func transitionRelatedRecordsTitle(to title: String) {
        fadeRelatedRecordsTitle(out: true) { [weak self] in
            if let strongSelf = self {
                strongSelf.relatedRecordsTypeLabel.attributedStringValue = NSAttributedString(string: title, attributes: strongSelf.titleBarAttributes)
                strongSelf.fadeRelatedRecordsTitle(out: false, completion: {})
            }
        }
    }

    private func fadeRelatedRecordsTitle(out: Bool, completion: @escaping () -> Void) {
        let alpha: CGFloat = out ? 0 : 1

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.relatedRecordsTitleAnimationDuration
            relatedRecordsTypeLabel.animator().alphaValue = alpha
        }, completionHandler: {
            completion()
        })
    }
}
