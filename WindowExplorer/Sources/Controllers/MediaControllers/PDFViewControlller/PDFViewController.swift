//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFViewController: MediaViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "PDF")

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet weak var closeButtonView: NSView!
    @IBOutlet weak var backTapArea: NSView!
    @IBOutlet weak var forwardTapArea: NSView!
    private var thumbnailClipView: NSClipView!

    var document: PDFDocument!
    let leftArrow = ArrowControl()
    let rightArrow = ArrowControl()

    private struct Constants {
        static let arrowInsetMargin: CGFloat = 10
        static let arrowWidth: CGFloat = 20
        static let arrowHeight: CGFloat = 40
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        if let scrollView = pdfThumbnailView.subviews.last as? NSScrollView, let clipView = scrollView.subviews.first(where: { $0 is NSClipView }) as? NSClipView {
            thumbnailClipView = clipView
        }

        setupPDF()
        setupArrows()
        setupGestures()
        super.animateViewIn()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Causes the clipview to layout and eliminates strange subview offsets.
        thumbnailClipView.scroll(CGPoint(x: 0, y: 1))
    }

    // MARK: Setup

    private func setupPDF() {
        guard super.media.type == .pdf else {
            return
        }

        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        pdfThumbnailView.pdfView = pdfView

        document = PDFDocument(url: super.media.url)
        pdfView.document = document
    }

    private func setupArrows() {
        leftArrow.direction = .left
        leftArrow.color = style.selectedColor
        leftArrow.translatesAutoresizingMaskIntoConstraints = false
        leftArrow.wantsLayer = true
        view.addSubview(leftArrow)
        leftArrow.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor, constant: Constants.arrowInsetMargin).isActive = true
        leftArrow.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor).isActive = true
        leftArrow.widthAnchor.constraint(equalToConstant: Constants.arrowWidth).isActive = true
        leftArrow.heightAnchor.constraint(equalToConstant: Constants.arrowHeight).isActive = true

        rightArrow.direction = .right
        rightArrow.color = style.selectedColor
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.wantsLayer = true
        view.addSubview(rightArrow)
        rightArrow.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor, constant: -Constants.arrowInsetMargin).isActive = true
        rightArrow.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor).isActive = true
        rightArrow.widthAnchor.constraint(equalToConstant: Constants.arrowWidth).isActive = true
        rightArrow.heightAnchor.constraint(equalToConstant: Constants.arrowHeight).isActive = true

        updateArrows()
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let windowPan = PanGestureRecognizer()
        super.gestureManager.add(windowPan, to: view)
        windowPan.gestureUpdated = handleWindowPan(_:)

        let thumbnailViewPan = PanGestureRecognizer()
        super.gestureManager.add(thumbnailViewPan, to: thumbnailClipView)
        thumbnailViewPan.gestureUpdated = handleThumbnailViewPan(_:)

        let thumbnailViewTap = TapGestureRecognizer()
        super.gestureManager.add(thumbnailViewTap, to: thumbnailClipView)
        thumbnailViewTap.gestureUpdated = didTapThumbnailView(_:)

        let previousPageTap = TapGestureRecognizer()
        super.gestureManager.add(previousPageTap, to: backTapArea)
        previousPageTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.pdfView.goToPreviousPage(self)
                self?.updateArrows()
            }
        }

        let nextPageTap = TapGestureRecognizer()
        super.gestureManager.add(nextPageTap, to: forwardTapArea)
        nextPageTap.gestureUpdated = { [weak self] tap in
            if tap.state == .ended {
                self?.pdfView.goToNextPage(self)
                self?.updateArrows()
            }
        }

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        super.gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gesture Handling

    private func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
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

    private func handleThumbnailViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = thumbnailClipView.visibleRect.origin
            origin += pan.delta.dy
            thumbnailClipView.scroll(origin)
        default:
            return
        }
    }

    private func didTapThumbnailView(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let position = tap.position else {
            return
        }

        if tap.state == .ended {
            let thumbnailPages = thumbnailClipView.subviews.last?.subviews ?? []
            let location = position + thumbnailClipView.visibleRect.origin
            if let thumbnail = thumbnailPages.first(where: { $0.frame.contains(location) }), let index = thumbnailPages.index(of: thumbnail), let page = document.page(at: index) {
                pdfView.go(to: page)
                updateArrows()
            }
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        super.animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        super.resetCloseWindowTimer()
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
        WindowManager.instance.checkBounds(of: self)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        super.animateViewOut()
    }


    // MARK: Helpers

    private func updateArrows() {
        leftArrow.isHidden = !pdfView.canGoToPreviousPage
        rightArrow.isHidden = !pdfView.canGoToNextPage
    }
}
