//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "PDF")

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet weak var closeButtonView: NSView!

    var gestureManager: GestureManager!
    var media: Media!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)

        setupPDF()
        setupGestures()
    }

    override func viewWillAppear() {
        pdfThumbnailView.pdfView = pdfView
    }


    // MARK: Setup

    private func setupPDF() {
        guard media.type == .pdf else {
            return
        }

        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear

        let pdfDoc = PDFDocument(url: media.url)
        pdfView.document = pdfDoc
        pdfThumbnailView.pdfView = pdfView
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let windowPan = PanGestureRecognizer()
        gestureManager.add(windowPan, to: view)
        windowPan.gestureUpdated = handleWindowPan(_:)

        let thumbnailViewPan = PanGestureRecognizer()
        gestureManager.add(thumbnailViewPan, to: pdfThumbnailView)
        thumbnailViewPan.gestureUpdated = handleThumbnailViewPan(_:)

        let thumbnailViewTap = TapGestureRecognizer()
        gestureManager.add(thumbnailViewTap, to: closeButtonView)
        thumbnailViewTap.gestureUpdated = didTapThumbnailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
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
            if let scrollView = pdfThumbnailView.subviews.last as? NSScrollView, let clipView = scrollView.subviews.first(where: { $0 is NSClipView }) {
                var origin = clipView.visibleRect.origin
                origin += pan.delta.dy
                clipView.scroll(origin)
            }
        default:
            return
        }
    }

    private func didTapThumbnailView(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        if tap.state == .ended {
            // todo
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        if tap.state == .ended {
            WindowManager.instance.closeWindow(for: self)
        }
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
        WindowManager.instance.checkBounds(of: self)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        WindowManager.instance.closeWindow(for: self)
    }
}
