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

    private var panGesture: NSPanGestureRecognizer!
    private var initialPanningOrigin: CGPoint?
    weak var gestureManager: GestureManager!
    weak var viewDelegate: ViewManagerDelegate?
    var endURL: String!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDF()
        animateViewIn()
        setupGestures()
    }


    // MARK: Setup

    private func setupPDF() {
        pdfThumbnailView.backgroundColor = #colorLiteral(red: 0.9961728454, green: 0.9902502894, blue: 1, alpha: 0)
        pdfView.backgroundColor = #colorLiteral(red: 0.7317136762, green: 0.81375, blue: 0.7637042526, alpha: 0.8230652265)
        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true

        let completeURL = Constants.url.appendingPathComponent(endURL)
        let pdfDoc = PDFDocument(url: completeURL)
        pdfView.document = pdfDoc
        pdfThumbnailView.pdfView = pdfView
    }

    private func setupGestures() {
        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(panGesture)

        let singleFingerPan = PanGestureRecognizer()
        gestureManager.add(singleFingerPan, to: view)
        singleFingerPan.gestureUpdated = viewDidPan(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: closeButtonView)
        singleFingerCloseButtonTap.gestureUpdated = closeButtonViewDidTap(_:)
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }


    // MARK: Helpers

    private func animateViewIn() {
        view.alphaValue = 0.0
        pdfView.frame.origin.x = -view.frame.size.width

        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 0.7
            view.animator().alphaValue = 1.0
            pdfView.animator().frame.origin.x = 0
        })
    }

    private func animateViewOut() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = 1.0
            view.animator().alphaValue = 0.0
            pdfView.animator().frame.origin.y = pdfView.frame.size.height
        }, completionHandler: {
            self.view.removeFromSuperview()
        })
    }

    @objc
    private func handlePan(gesture: NSPanGestureRecognizer) {
        if gesture.state == .began {
            initialPanningOrigin = view.frame.origin
            return
        }

        if var origin = initialPanningOrigin {
            origin += gesture.translation(in: view.superview)
            view.frame.origin = origin
        }
    }

    private func viewDidPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = view.frame.origin
            origin += pan.delta
            view.frame.origin = origin
        default:
            return
        }
    }

    private func closeButtonViewDidTap(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        animateViewOut()
    }
}
