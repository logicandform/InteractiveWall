//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz
import MacGestures


class PDFViewController: MediaViewController, NSTableViewDelegate, NSTableViewDataSource {
    static let storyboard = "PDF"

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfScrollView: NSScrollView!
    @IBOutlet weak var thumbnailView: NSTableView!
    @IBOutlet weak var backTapArea: NSView!
    @IBOutlet weak var forwardTapArea: NSView!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var zoomControl: ZoomControl!

    private var document: PDFDocument!
    private let leftArrow = ArrowControl()
    private let rightArrow = ArrowControl()
    private lazy var contentViewFrame = pdfScrollView.contentView.frame

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
        static let doubleTapScale: CGFloat = 0.45
        static let doubleTapAnimationDuration = 0.3
        static let minimumZoomScale: CGFloat = 0.2
        static let defaultMultipageSize = CGSize(width: 650, height: 650)
        static let rg10Size = CGSize(width: 700, height: 1000)
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPDF()
        setupArrows()
        setupThumbnailView()
        setupZoomControl()
        setupGestures()
        animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        updateViewsForCurrentPage()
    }


    // MARK: Setup

    private func setupPDF() {
        guard [.pdf, .rg10].contains(media.type) else {
            return
        }

        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        let url = Configuration.localMediaURLs ? media.localURL : media.url
        document = PDFDocument(url: url)
        pdfView.document = document
        pdfScrollView.minMagnification = Constants.initialMagnification
        pdfScrollView.maxMagnification = Constants.maximumMagnification
        resize(for: media.type)
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

    private func setupZoomControl() {
        zoomControl.gestureManager = gestureManager
        zoomControl.zoomSliderUpdated = { [weak self] scale in
            self?.didScrubZoomSlider(scale)
        }
        zoomControl.tintColor = media.tintColor
    }

    private func setupGestures() {
        let thumbnailViewPan = PanGestureRecognizer()
        gestureManager.add(thumbnailViewPan, to: thumbnailView)
        thumbnailViewPan.gestureUpdated = { [weak self] gesture in
            self?.handleThumbnailPan(gesture)
        }

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: pdfView)
        pinchGesture.gestureUpdated = { [weak self] gesture in
            self?.handlePinch(gesture)
        }

        let thumbnailViewTap = TapGestureRecognizer()
        gestureManager.add(thumbnailViewTap, to: thumbnailView)
        thumbnailViewTap.gestureUpdated = { [weak self] gesture in
            self?.handleThumbnailItemTap(gesture)
        }

        let previousPageTap = TapGestureRecognizer()
        gestureManager.add(previousPageTap, to: backTapArea)
        previousPageTap.gestureUpdated = { [weak self] gesture in
            self?.handleLeftArrowTap(gesture)
        }

        let nextPageTap = TapGestureRecognizer()
        gestureManager.add(nextPageTap, to: forwardTapArea)
        nextPageTap.gestureUpdated = { [weak self] gesture in
            self?.handleRightArrowTap(gesture)
        }
    }


    // MARK: Gesture Handling

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
        case .recognized, .momentum:
            var pdfRect = pdfScrollView.contentView.bounds
            let scaledWidth = (2.0 - pinch.scale) * pdfRect.size.width
            let scaledHeight = (2.0 - pinch.scale) * pdfRect.size.height
            if scaledWidth <= contentViewFrame.width {
                var translationX = pinch.delta.dx * pdfRect.size.width / contentViewFrame.width
                var translationY = pinch.delta.dy * pdfRect.size.height / contentViewFrame.height
                if scaledWidth >= contentViewFrame.width / Constants.maximumMagnification {
                    translationX -= (pdfRect.size.width - scaledWidth) * (pinch.center.x / contentViewFrame.width)
                    translationY -= (pdfRect.size.height - scaledHeight) * (pinch.center.y / contentViewFrame.height)
                    pdfRect.size = CGSize(width: scaledWidth, height: scaledHeight)

                    let scale = (contentViewFrame.width / Constants.maximumMagnification) / scaledWidth
                    zoomControl.updateSeekBarPosition(to: scale)
                }
                pdfRect.origin = CGPoint(x: pdfRect.origin.x - translationX, y: pdfRect.origin.y - translationY)
            }
            leftArrow.isHidden = !pdfView.canGoToPreviousPage || contentViewFrame.width / pdfRect.width >= Constants.initialMagnification + 0.1
            rightArrow.isHidden = !pdfView.canGoToNextPage || contentViewFrame.width / pdfRect.width >= Constants.initialMagnification + 0.1
            pdfScrollView.contentView.bounds = pdfRect
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


    // MARK: Helpers

    private func updateViewsForCurrentPage() {
        leftArrow.isHidden = !pdfView.canGoToPreviousPage
        rightArrow.isHidden = !pdfView.canGoToNextPage
        pdfScrollView.magnification = Constants.initialMagnification
        zoomControl.updateSeekBarPosition(to: 0)

        if let page = pdfView.currentPage, let pageNumber = page.pageRef?.pageNumber, let thumbnailItem = thumbnailView.view(atColumn: 0, row: pageNumber - 1, makeIfNecessary: false) as? PDFTableViewItem {
            selectedThumbnailItem = thumbnailItem
            thumbnailView.scrollRowToVisible(pageNumber - 1)
        }
    }

    private func didScrubZoomSlider(_ scale: CGFloat) {
        pdfScrollView.magnification = scale * Constants.maximumMagnification
        leftArrow.isHidden = !pdfView.canGoToPreviousPage || scale >= Constants.minimumZoomScale
        rightArrow.isHidden = !pdfView.canGoToNextPage || scale >= Constants.minimumZoomScale
    }

    private func resize(for type: MediaType) {
        let mediaSize = size(for: type)
        scrollViewWidthConstraint.constant = mediaSize.width
        scrollViewHeightConstraint.constant = mediaSize.height
        view.needsLayout = true
        view.layout()
    }

    private func size(for type: MediaType) -> CGSize {
        let pageCount = document?.pageCount ?? 0

        switch media.type {
        case .pdf where pageCount == 1:
            return firstPageSize()
        case .pdf:
            return Constants.defaultMultipageSize
        case .rg10:
            return Constants.rg10Size
        default:
            return .zero
        }
    }

    private func firstPageSize() -> CGSize {
        guard let page = pdfView.currentPage else {
            return .zero
        }

        let pageBounds = page.bounds(for: .artBox)
        if isRotated(page: page) {
            let size = CGSize(width: pageBounds.height, height: pageBounds.width)
            return constrainWindow(size: size)
        } else {
            return constrainWindow(size: pageBounds.size)
        }
    }

    private func isRotated(page: PDFPage) -> Bool {
        return page.rotation == 270 || page.rotation == 90
    }
}
