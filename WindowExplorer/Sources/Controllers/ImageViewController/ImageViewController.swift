//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import Alamofire
import AlamofireImage

class ImageViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Image")

    @IBOutlet weak var imageScrollView: NSScrollView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var dismissButton: NSView!
    var imageView: NSImageView!

    private(set) var gestureManager: GestureManager!
    private var thumbnailRequest: DataRequest?
    private var urlRequest: DataRequest?
    var media: Media!

    var singleFingerPan: PanGestureRecognizer!



    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        gestureManager = GestureManager(responder: self)
        titleTextField.stringValue = media.title ?? ""

        setupImageView()
        setupGestures()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        thumbnailRequest?.cancel()
        urlRequest?.cancel()
    }


    // MARK: Setup

    private func setupImageView() {
        guard media.type == .image else {
            return
        }

        imageView = NSImageView(image: NSImage())

        // Load thumbnail first
        thumbnailRequest = Alamofire.request(media.thumbnail).responseImage { [weak self] response in
            if let strongSelf = self, let image = response.value, strongSelf.imageView.image == nil {
                self?.imageView.image = image
            }
        }

        // Load large media object in background
        urlRequest = Alamofire.request(media.url).responseImage { [weak self] response in
            if let image = response.value {
                self?.imageView.image = image
            }
        }

        imageView.layer?.backgroundColor = #colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1)

        imageScrollView.documentView = imageView

        print("test")
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

//        singleFingerPan = PanGestureRecognizer()
//        gestureManager.add(singleFingerPan, to: imageView)
//        singleFingerPan.gestureUpdated = didPanDetailView(_:)

//        let pinchGesture = PinchGestureRecognizer()
//        gestureManager.add(pinchGesture, to: imageView)
//        pinchGesture.gestureUpdated = didPinchDetailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }


    // MARK: Gesture Handling

    private func didPanDetailView(_ gesture: GestureRecognizer) {
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

    private func didPinchDetailView(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        singleFingerPan.reset()

//        translationX += (mapRect.size.width - scaledWidth) * Double(pinch.lastPosition.x / mapView.frame.width)
//        translationY += (mapRect.size.height - scaledHeight) * (1 - Double(pinch.lastPosition.y / mapView.frame.height))

        switch pinch.state {
        case .recognized:
//
//            let scaledWidth = (2 - pinch.scale) * imageView.bounds.width
//            let scaledHeight = (2 - pinch.scale) * imageView.bounds.height
//////            var translationX = -pinch.delta.dx * imageView.frame.width / initialRect.width
//////            var translationY = pinch.delta.dy * imageView.frame.height / initialRect.height
//            if scaledWidth <= initialRect.width {
//                let translationX =  (imageView.bounds.width - scaledWidth) * pinch.lastPosition.x / initialRect.width
//                let translationY =  (imageView.bounds.height - scaledHeight) * pinch.lastPosition.y / initialRect.height
//
//                imageView.setBoundsSize(CGSize(width: scaledWidth, height: scaledHeight))
//                imageView.setBoundsOrigin(CGPoint(x: translationX + imageView.bounds.origin.x, y: translationY + imageView.bounds.origin.y))
//            }
            return
        case .possible:
            imageView.sizeToFit()
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard gesture is TapGestureRecognizer else {
            return
        }

        WindowManager.instance.closeWindow(for: self)
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

