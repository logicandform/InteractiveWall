//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "PDF")

    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!
    @IBOutlet weak var closeButtonView: NSView!

    private struct Constants {
        static let url = URL(fileURLWithPath: "/Users/Jeremy/Desktop/")
    }

    weak var gestureManager: GestureManager!
    var endURL: String!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDF()
        animateViewIn()
        setupGestures()
    }

    override func viewWillAppear() {
        pdfThumbnailView.pdfView = pdfView
    }


    // MARK: Setup

    private func setupPDF() {
        pdfThumbnailView.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.4523822623)
        pdfView.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.82)
        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.layer?.cornerRadius = 5

        let completeURL = Constants.url.appendingPathComponent(endURL)
        let pdfDoc = PDFDocument(url: completeURL)
        pdfView.document = pdfDoc
        pdfThumbnailView.pdfView = pdfView
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: view)
        singleFingerPan.gestureUpdated = handlePan(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gesture Handling

    private func handlePan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window else {
            return
        }

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: Helpers

    private func animateViewIn() {
        view.alphaValue = 0.0
        pdfView.frame.origin.y = pdfView.frame.size.height

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 0.7
            view.animator().alphaValue = 1.0
            pdfView.animator().frame.origin.y = 0
        })
    }

    private func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            view.animator().alphaValue = 0.0
            pdfView.animator().frame.origin.y = pdfView.frame.size.height
        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                WindowManager.instance.closeWindow(for: strongSelf)
            }
        })
    }
}
