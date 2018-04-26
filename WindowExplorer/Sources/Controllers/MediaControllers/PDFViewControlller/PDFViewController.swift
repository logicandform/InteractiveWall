//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFViewController: MediaViewController, NSTableViewDelegate, NSTableViewDataSource {
    static let storyboard = NSStoryboard.Name(rawValue: "PDF")

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfScrollView: NSScrollView!
    @IBOutlet weak var thumbnailView: NSTableView!
    @IBOutlet weak var backTapArea: NSView!
    @IBOutlet weak var forwardTapArea: NSView!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!

    private var document: PDFDocument!
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

        setupPDF()
        setupArrows()
        setupThumbnailView()
        setupGestures()
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
        case .began:
            contentViewFrame = pdfScrollView.contentView.frame
        case .recognized, .momentum:
            var pdfRect = pdfScrollView.contentView.bounds
            let scaledWidth = (2.0 - pinch.scale) * pdfRect.size.width
            let scaledHeight = (2.0 - pinch.scale) * pdfRect.size.height
            if scaledWidth <= contentViewFrame.width{
                var translationX = pinch.delta.dx * pdfRect.size.width / contentViewFrame.width
                var translationY = pinch.delta.dy * pdfRect.size.height / contentViewFrame.height
                if scaledWidth >= contentViewFrame.width / Constants.maximumMagnification {
                    translationX -= (pdfRect.size.width - scaledWidth) * (pinch.center.x / contentViewFrame.width)
                    translationY -= (pdfRect.size.height - scaledHeight) * (pinch.center.y / contentViewFrame.height)
                    pdfRect.size = CGSize(width: scaledWidth, height: scaledHeight)
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
        let width = clamp(mediaBox.size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWidth)
        let height = width * scale
        scrollViewWidthConstraint.constant = width
        scrollViewHeightConstraint.constant = height
        view.needsLayout = true
        view.layout()
    }
}
