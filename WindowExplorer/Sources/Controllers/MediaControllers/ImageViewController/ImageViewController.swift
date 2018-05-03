//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import Alamofire
import AlamofireImage

class ImageViewController: MediaViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Image")

    @IBOutlet weak var imageScrollView: RegularScrollView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewWidthConstraint: NSLayoutConstraint!

    private var imageView: NSImageView!
    private var imageRequest: DataRequest?
    private var contentViewFrame: NSRect!
    private var frameSize: NSSize!

    private struct Constants {
        static let initialMagnifition: CGFloat = 1
        static let maximumMagnification: CGFloat = 5
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupImageView()
        setupGestures()
        animateViewIn()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        imageRequest?.cancel()
    }


    // MARK: Setup

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

    private func addImage(_ image: NSImage) {
        let imageRatio = image.size.height / image.size.width
        let width = clamp(image.size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWidth)
        let height = clamp(width * imageRatio, min: style.minMediaWindowHeight, max: style.maxMediaWindowHeight)

        imageView.image = image
        imageView.imageScaling = .scaleAxesIndependently
        frameSize = NSSize(width: width, height: height)
        imageView.setFrameSize(frameSize)
        scrollViewHeightConstraint.constant = frameSize.height
        scrollViewWidthConstraint.constant = frameSize.width
        view.window?.setFrame(NSRect(origin: view.window!.frame.origin, size: frameSize), display: true)
        imageScrollView.documentView = imageView

        updatePosition(animating: false)
    }

    private func setupGestures() {
        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: imageScrollView)
        pinchGesture.gestureUpdated = didPinchImageView(_:)
    }

    
    // MARK: Gesture Handling

    private func didPinchImageView(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer, !animating else {
            return
        }

        switch pinch.state {
        case .began:
            contentViewFrame = imageScrollView.contentView.frame
        case .recognized, .momentum:
            var imageRect = imageScrollView.contentView.bounds
            let scaledWidth = (2.0 - pinch.scale) * imageRect.size.width
            let scaledHeight = (2.0 - pinch.scale) * imageRect.size.height
            if scaledWidth <= contentViewFrame.width{
                var translationX = pinch.delta.dx * imageRect.size.width / contentViewFrame.width
                var translationY = pinch.delta.dy * imageRect.size.height / contentViewFrame.height
                if scaledWidth >= contentViewFrame.width / Constants.maximumMagnification {
                    translationX -= (imageRect.size.width - scaledWidth) * (pinch.center.x / contentViewFrame.width)
                    translationY -= (imageRect.size.height - scaledHeight) * (pinch.center.y / contentViewFrame.height)
                    imageRect.size = CGSize(width: scaledWidth, height: scaledHeight)
                }
                imageRect.origin = CGPoint(x: imageRect.origin.x - translationX, y: imageRect.origin.y - translationY)
            }
            imageScrollView.contentView.bounds = imageRect
        default:
            return
        }
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }
}
