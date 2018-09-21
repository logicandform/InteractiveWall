//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import Alamofire
import AlamofireImage

class ImageViewController: MediaViewController {
    static let storyboard = "Image"

    @IBOutlet weak var imageScrollView: RegularScrollView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageZoomControl: ZoomControl!

    private var imageView: NSImageView!
    private var imageRequest: DataRequest?
    private var frameSize: NSSize!
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

        setupScrollView()
        setupImageView()
        setupZoomControl()
        setupGestures()
        animateViewIn()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        imageRequest?.cancel()
    }


    // MARK: Setup

    private func setupScrollView() {
        imageScrollView.minMagnification = Constants.initialMagnification
        imageScrollView.maxMagnification = Constants.maximumMagnification
    }

    private func setupImageView() {
        guard media.type == .image else {
            return
        }

        imageView = NSImageView()
        imageRequest = Alamofire.request(media.url).responseImage { [weak self] response in
            if let image = response.value {
                self?.addImage(image)
            }
        }
    }

    private func setupZoomControl() {
        imageZoomControl.gestureManager = gestureManager
        imageZoomControl.zoomSliderUpdated = { [weak self] scale in
            self?.didScrubZoomSlider(scale)
        }
        imageZoomControl.tintColor = media.tintColor
    }

    private func addImage(_ image: NSImage) {
        guard let window = view.window else {
            return
        }

        let imageRatio = image.size.height / image.size.width
        let width = clamp(image.size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWidth)
        let height = clamp(width * imageRatio, min: style.minMediaWindowHeight, max: style.maxMediaWindowHeight)

        imageView.image = image
        imageView.imageScaling = .scaleAxesIndependently
        frameSize = NSSize(width: width, height: height)
        imageView.setFrameSize(frameSize)
        scrollViewHeightConstraint.constant = frameSize.height
        scrollViewWidthConstraint.constant = frameSize.width
        view.window?.setFrame(NSRect(origin: window.frame.origin, size: frameSize), display: true)
        imageScrollView.documentView = imageView

        updatePosition(animating: false)
    }

    private func setupGestures() {
        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: imageScrollView)
        pinchGesture.gestureUpdated = { [weak self] gesture in
            self?.didPinchImageView(gesture)
        }
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
