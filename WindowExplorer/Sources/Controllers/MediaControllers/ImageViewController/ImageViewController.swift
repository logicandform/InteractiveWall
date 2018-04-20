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

    private var urlRequest: DataRequest?
    private var imageView: NSImageView!
    private var contentViewFrame: NSRect!
    private var frameSize: NSSize!

    private struct Constants {
        static let initialMagnification: CGFloat = 1
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
        urlRequest?.cancel()
    }


    // MARK: Setup

    private func setupImageView() {
        guard media.type == .image else {
            return
        }

        imageScrollView.minMagnification = Constants.initialMagnification
        imageScrollView.maxMagnification = Constants.maximumMagnification
        imageView = NSImageView()

        urlRequest = Alamofire.request(media.url).responseImage { [weak self] response in
            if let image = response.value {
                self?.addImage(image)
            }
        }
    }

    private func addImage(_ image: NSImage) {
        imageView.image = image
        imageView.imageScaling = NSImageScaling.scaleAxesIndependently
        
        let imageRatio = image.size.height / image.size.width
        let width = clamp(image.size.width, min: style.minMediaWindowWidth, max: style.maxMediaWindowWidth)
        let height = width * imageRatio
        frameSize = NSSize(width: width, height: height)
        imageView.setFrameSize(frameSize)
        scrollViewHeightConstraint.constant = frameSize.height
        scrollViewWidthConstraint.constant = frameSize.width
        imageScrollView.documentView = imageView
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
            let newMagnification = clamp(imageScrollView.magnification + (pinch.scale - 1), min: Constants.initialMagnification, max: Constants.maximumMagnification)
            imageScrollView.setMagnification(newMagnification, centeredAt: pinch.center)
            let currentRect = imageScrollView.contentView.bounds
            let newOriginX = min(contentViewFrame.origin.x + contentViewFrame.width - currentRect.width, max(contentViewFrame.origin.x, currentRect.origin.x - pinch.delta.dx / newMagnification))
            let newOriginY = min(contentViewFrame.origin.y + contentViewFrame.height - currentRect.height, max(contentViewFrame.origin.y, currentRect.origin.y - pinch.delta.dy / newMagnification))
            imageScrollView.contentView.scroll(to: NSPoint(x: newOriginX, y: newOriginY))
        default:
            return
        }
    }


    // MARK: IB-Actions

    @IBAction func closeButtonTapped(_ sender: Any) {
        animateViewOut()
    }
}
