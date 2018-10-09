//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MacGestures


class ImageViewController: MediaViewController {
    static let storyboard = "Image"

    @IBOutlet weak var imageScrollView: RegularScrollView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageZoomControl: ZoomControl!

    private var adjusted = false
    private lazy var contentViewFrame = imageScrollView.contentView.frame

    private struct Constants {
        static let initialMagnification: CGFloat = 1
        static let maximumMagnification: CGFloat = 5
        static let doubleTapScale: CGFloat = 0.45
        static let doubleTapAnimationDuration = 0.3
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.alphaValue = 0

        setupScrollView()
        setupZoomControl()
        setupGestures()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        loadImage()
    }


    // MARK: Setup

    private func setupScrollView() {
        imageScrollView.minMagnification = Constants.initialMagnification
        imageScrollView.maxMagnification = Constants.maximumMagnification
    }

    private func setupZoomControl() {
        imageZoomControl.gestureManager = gestureManager
        imageZoomControl.tintColor = media.tintColor
        imageZoomControl.zoomSliderUpdated = { [weak self] scale in
            self?.didScrubZoomSlider(scale)
        }
    }

    private func setupGestures() {
        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: imageScrollView)
        pinchGesture.gestureUpdated = { [weak self] gesture in
            self?.didPinchImageView(gesture)
        }
    }

    private func loadImage() {
        guard media.type == .image else {
            return
        }

        CachingNetwork.getImage(for: media) { [weak self] image in
            self?.display(image: image)
        }
    }

    private func display(image: NSImage?) {
        guard let image = image, let window = view.window else {
            return
        }

        let imageView = ImageView()
        imageView.set(image)
        let size = constrainWindow(size: image.size)
        imageView.setFrameSize(size)
        scrollViewHeightConstraint.constant = size.height
        scrollViewWidthConstraint.constant = size.width
        imageScrollView.documentView = imageView
        let frame = CGRect(origin: window.frame.origin, size: size)
        setWindow(frame: frame, animate: false) { [weak self] in
            if let strongSelf = self {
                self?.parentDelegate?.requestUpdate(for: strongSelf, animate: false)
                self?.animateViewIn()
                self?.adjusted = true
            }
        }
    }


    // MARK: Overrides

    override func draggableInside(bounds: CGRect) -> Bool {
        // Don't close window until image has been adjusted and window has been updated
        if !adjusted {
            return true
        }
        return super.draggableInside(bounds: bounds)
    }


    // MARK: Gesture Handling

    private func didPinchImageView(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer, !animating else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            var imageRect = imageScrollView.contentView.bounds
            let scaledWidth = (2.0 - pinch.scale) * imageRect.size.width
            let scaledHeight = (2.0 - pinch.scale) * imageRect.size.height

            if scaledWidth <= contentViewFrame.width {
                var translationX = pinch.delta.dx * imageRect.size.width / contentViewFrame.width
                var translationY = pinch.delta.dy * imageRect.size.height / contentViewFrame.height
                if scaledWidth >= contentViewFrame.width / Constants.maximumMagnification {
                    translationX -= (imageRect.size.width - scaledWidth) * (pinch.center.x / contentViewFrame.width)
                    translationY -= (imageRect.size.height - scaledHeight) * (pinch.center.y / contentViewFrame.height)
                    imageRect.size = CGSize(width: scaledWidth, height: scaledHeight)

                    let scale = (contentViewFrame.width / Constants.maximumMagnification) / scaledWidth
                    imageZoomControl.updateSeekBarPosition(to: scale)
                }
                imageRect.origin = CGPoint(x: imageRect.origin.x - translationX, y: imageRect.origin.y - translationY)
                imageScrollView.contentView.bounds = imageRect
            }
        default:
            return
        }
    }

    private func didScrubZoomSlider(_ scale: CGFloat) {
        imageScrollView.magnification = Constants.maximumMagnification * scale
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }
}
