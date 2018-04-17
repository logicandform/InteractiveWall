//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFViewController: MediaViewController, NSTableViewDelegate, NSTableViewDataSource {
    static let storyboard = NSStoryboard.Name(rawValue: "PDF")

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfScrollView: NSScrollView!
    @IBOutlet weak var thumbnailView: NSTableView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var closeButtonView: NSView!
    @IBOutlet weak var backTapArea: NSView!
    @IBOutlet weak var forwardTapArea: NSView!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!

    var document: PDFDocument!
    private let leftArrow = ArrowControl()
    private let rightArrow = ArrowControl()
    private var contentViewFrame: NSRect!

    private var selectedThumbnailItem: PDFTableViewItem? {
        didSet {
            oldValue?.set(highlighted: false)
            selectedThumbnailItem?.set(highlighted: true)
        }
    }

    private struct Constants {
        static let arrowInsetMargin: CGFloat = 10
        static let arrowWidth: CGFloat = 20
        static let arrowHeight: CGFloat = 40
        static let tableRowHeight: CGFloat = 100
        static let initialMagnification: CGFloat = 1
        static let maximumMagnification: CGFloat = 5
        static let percentToDeallocateWindow: CGFloat = 40
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: media.title ?? "", attributes: titleAttributes)

        setupPDF()
        setupArrows()
        setupThumbnailView()
        setupGestures()
        setupWindowDragArea()
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        updateViewsForCurrentPage()
    }


    // MARK: Setup

    private func setupPDF() {
        guard media.type == .pdf else {
            return
        }

        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        document = PDFDocument(url: media.url)
        pdfView.document = document
        pdfScrollView.minMagnification = Constants.initialMagnification
        pdfScrollView.maxMagnification = Constants.maximumMagnification
        resizeToFirstPage()
    }
    
    private func setupThumbnailView() {
        thumbnailView.register(NSNib(nibNamed: PDFTableViewItem.nibName, bundle: nil), forIdentifier: PDFTableViewItem.interfaceIdentifier)
    }

    private func setupArrows() {
        leftArrow.direction = .left
        leftArrow.color = media.tintColor
        leftArrow.translatesAutoresizingMaskIntoConstraints = false
        leftArrow.wantsLayer = true
        view.addSubview(leftArrow)
        leftArrow.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor, constant: Constants.arrowInsetMargin).isActive = true
        leftArrow.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor).isActive = true
        leftArrow.widthAnchor.constraint(equalToConstant: Constants.arrowWidth).isActive = true
        leftArrow.heightAnchor.constraint(equalToConstant: Constants.arrowHeight).isActive = true

        rightArrow.direction = .right
        rightArrow.color = media.tintColor
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.wantsLayer = true
        view.addSubview(rightArrow)
        rightArrow.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor, constant: -Constants.arrowInsetMargin).isActive = true
        rightArrow.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor).isActive = true
        rightArrow.widthAnchor.constraint(equalToConstant: Constants.arrowWidth).isActive = true
        rightArrow.heightAnchor.constraint(equalToConstant: Constants.arrowHeight).isActive = true
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let windowPan = PanGestureRecognizer()
        gestureManager.add(windowPan, to: windowDragArea)
        windowPan.gestureUpdated = handleWindowPan(_:)

        let thumbnailViewPan = PanGestureRecognizer()
        gestureManager.add(thumbnailViewPan, to: thumbnailView)
        thumbnailViewPan.gestureUpdated = handleThumbnailPan(_:)

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: pdfView)
        pinchGesture.gestureUpdated = handlePinch(_:)

        let thumbnailViewTap = TapGestureRecognizer()
        gestureManager.add(thumbnailViewTap, to: thumbnailView)
        thumbnailViewTap.gestureUpdated = handleThumbnailItemTap(_:)

        let previousPageTap = TapGestureRecognizer()
        gestureManager.add(previousPageTap, to: backTapArea)
        previousPageTap.gestureUpdated = handleLeftArrowTap(_:)

        let nextPageTap = TapGestureRecognizer()
        gestureManager.add(nextPageTap, to: forwardTapArea)
        nextPageTap.gestureUpdated = handleRightArrowTap(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }

    private func setupWindowDragArea() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = media.tintColor.cgColor
    }


    // MARK: Gesture Handling

    private func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }


        switch pan.state {
        case .began:
            delegate?.controllerDidMove(self)
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

    private func handleThumbnailPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }
        
        switch pan.state {
        case .recognized, .momentum:
            var rect = thumbnailView.visibleRect
            rect.origin.y += pan.delta.dy
            thumbnailView.scrollToVisible(rect)
        default:
            return
        }
    }

    private func handlePinch(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer, !animating else {
            return
        }

        switch pinch.state {
        case .began:
            contentViewFrame = pdfScrollView.contentView.frame
        case .recognized, .momentum:
            let magnification = clamp(pdfScrollView.magnification + (pinch.scale - 1), min: Constants.initialMagnification, max: Constants.maximumMagnification)
            pdfScrollView.setMagnification(magnification, centeredAt: pinch.center)
            leftArrow.isHidden = magnification != Constants.initialMagnification
            rightArrow.isHidden = magnification != Constants.initialMagnification
            let currentRect = pdfScrollView.contentView.bounds
            let newOriginX = min(contentViewFrame.origin.x + contentViewFrame.width - currentRect.width, max(contentViewFrame.origin.x, currentRect.origin.x - pinch.delta.dx / magnification))
            let newOriginY = min(contentViewFrame.origin.y + contentViewFrame.height - currentRect.height, max(contentViewFrame.origin.y, currentRect.origin.y - pinch.delta.dy / magnification))
            pdfScrollView.contentView.scroll(to: NSPoint(x: newOriginX, y: newOriginY))
        default:
            return
        }
    }

    private func handleLeftArrowTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !leftArrow.isHidden, !animating else {
            return
        }

        pdfView.goToPreviousPage(self)
        updateViewsForCurrentPage()
    }

    private func handleRightArrowTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !rightArrow.isHidden, !animating else {
            return
        }

        pdfView.goToNextPage(self)
        updateViewsForCurrentPage()
    }

    private func handleThumbnailItemTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let location = tap.position, tap.state == .ended, !animating else {
            return
        }
        
        let locationInTable = location + thumbnailView.visibleRect.origin
        let row = thumbnailView.row(at: locationInTable)
        if row >= 0, let thumbnailItem = thumbnailView.view(atColumn: 0, row: row, makeIfNecessary: false) as? PDFTableViewItem, let selectedPage = thumbnailItem.page {
            pdfView.go(to: selectedPage)
            updateViewsForCurrentPage()
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !animating else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window, !animating else {
            return
        }

        resetCloseWindowTimer()
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }


    // MARK: NSTableViewDelegate & NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        return document?.pageCount ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let pdfItemView = tableView.makeView(withIdentifier: PDFTableViewItem.interfaceIdentifier, owner: self) as? PDFTableViewItem else {
            return nil
        }

        pdfItemView.page = document.page(at: row)
        pdfItemView.tintColor = media.tintColor
        return pdfItemView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constants.tableRowHeight
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    override func draggableInside(bounds: CGRect) -> Bool {
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

    private func updateViewsForCurrentPage() {
        leftArrow.isHidden = !pdfView.canGoToPreviousPage
        rightArrow.isHidden = !pdfView.canGoToNextPage
        pdfScrollView.magnification = Constants.initialMagnification
        
        if let page = pdfView.currentPage, let pageNumber = page.pageRef?.pageNumber, let thumbnailItem = thumbnailView.view(atColumn: 0, row: pageNumber - 1, makeIfNecessary: false) as? PDFTableViewItem {
            selectedThumbnailItem = thumbnailItem
            thumbnailView.scrollRowToVisible(pageNumber - 1)
        }
    }

    private func resizeToFirstPage() {
        guard let page = pdfView.currentPage else {
            return
        }

        let mediaBox = page.bounds(for: .artBox)
        let scale = mediaBox.height / mediaBox.width
        let width = clamp(mediaBox.size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWdith)
        let height = width * scale
        scrollViewWidthConstraint.constant = width
        scrollViewHeightConstraint.constant = height
        view.needsLayout = true
        view.layout()
    }
}
