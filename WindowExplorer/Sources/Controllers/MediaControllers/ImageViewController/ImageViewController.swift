//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import Alamofire
import AlamofireImage

class ImageViewController: MediaViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Image")

    @IBOutlet weak var imageScrollView: RegularScrollView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var rotateButton: NSView!
    var imageView: NSImageView!

    private var thumbnailRequest: DataRequest?
    private var urlRequest: DataRequest?
    private var contentViewFrame: NSRect!
    private var frameSize: NSSize!
    
    // This is needed here to work until Tim fixes the gestures so only 1 will fire
    private var singleFingerPan: PanGestureRecognizer!


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        super.gestureManager = GestureManager(responder: self)
        titleTextField.stringValue = super.media.title ?? ""
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
        guard super.media.type == .image else {
            return
        }
        imageView = NSImageView()

        // Load thumbnail first
        thumbnailRequest = Alamofire.request(super.media.thumbnail).responseImage { [weak self] response in
            if let image = response.value {
                self?.addImage(image)
            }
        }

        // Load large media object in background
        urlRequest = Alamofire.request(super.media.url).responseImage { [weak self] response in
            if let image = response.value {
                self?.imageView.image = image
            }
        }
    }

    private func addImage(_ image: NSImage) {
        imageView.image = image
        imageView.imageScaling = NSImageScaling.scaleAxesIndependently
        let scaleRatio =  min(imageScrollView.frame.width / image.size.width, imageScrollView.frame.height / image.size.height)
        frameSize = NSSize(width: round(image.size.width * scaleRatio), height: round(image.size.height * scaleRatio))
        imageView.setFrameSize(frameSize)
        scrollViewHeightConstraint.constant = frameSize.height
        scrollViewWidthConstraint.constant = frameSize.width
        imageScrollView.documentView = imageView
    }

    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        view.addGestureRecognizer(panGesture)

        singleFingerPan = PanGestureRecognizer()
        super.gestureManager.add(singleFingerPan, to: imageScrollView)
        singleFingerPan.gestureUpdated = didPanDetailView(_:)

        let pinchGesture = PinchGestureRecognizer()
        super.gestureManager.add(pinchGesture, to: imageScrollView)
        pinchGesture.gestureUpdated = didPinchDetailView(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        super.gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)

        let singleFingerRotateButtonTap = TapGestureRecognizer()
        super.gestureManager.add(singleFingerRotateButtonTap, to: rotateButton)
        singleFingerRotateButtonTap.gestureUpdated = didTapRotateButton(_:)
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

        switch pinch.state {
        case .began:
            singleFingerPan.reset()
            contentViewFrame = imageScrollView.contentView.frame
        case .recognized:
            let newMagnification = imageScrollView.magnification + (pinch.scale - 1)
            imageScrollView.setMagnification(newMagnification, centeredAt: pinch.center)
            let currentRect = imageScrollView.contentView.bounds
            let newOriginX = min(contentViewFrame.origin.x + contentViewFrame.width - currentRect.width, max(contentViewFrame.origin.x, currentRect.origin.x - pinch.delta.dx / newMagnification))
            let newOriginY = min(contentViewFrame.origin.y + contentViewFrame.height - currentRect.height, max(contentViewFrame.origin.y, currentRect.origin.y - pinch.delta.dy / newMagnification))
            imageScrollView.contentView.scroll(to: NSPoint(x: newOriginX, y: newOriginY))
        default:
            return
        }
    }

    private func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        super.close()
    }

    private func didTapRotateButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended else {
            return
        }

        let tempWidth = frameSize.width
        frameSize.width = frameSize.height
        frameSize.height = tempWidth
        scrollViewHeightConstraint.constant = frameSize.height
        scrollViewWidthConstraint.constant = frameSize.width
        imageView.setFrameSize(frameSize)
        imageView.rotate(byDegrees: -90)
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
        super.close()
    }
}
