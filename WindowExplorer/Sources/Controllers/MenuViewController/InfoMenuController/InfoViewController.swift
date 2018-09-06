//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


protocol InfoViewDelegate: class {
    func didToggleVolume(level: VolumeLevel)
}


class InfoViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, GestureResponder, InfoViewDelegate {
    static let storyboard = NSStoryboard.Name(rawValue: "Info")

    @IBOutlet weak var infoScrollView: FadingScrollView!
    @IBOutlet weak var infoClipView: NSClipView!
    @IBOutlet weak var infoCollectionView: NSCollectionView!
    @IBOutlet weak var toggleButtonArea: NSView!
    @IBOutlet weak var volumeButtonArea: NSView!
    @IBOutlet weak var playerControlArea: NSView!

    var gestureManager: GestureManager!
    private var infoItems = [InfoItem]()
    private var pageControl = PageControl()
    private var volume = VolumeLevel.low
    private var playControlScrubGesture: PanGestureRecognizer!
    private weak var focusedInfoView: InfoItemView?

    private struct Constants {
        static let pageControlHeight: CGFloat = 20
        static let unfocusThresholdPercent: CGFloat = 0.15
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor

        setupInfoItems()
        setupCollectionView()
        setupPageControl()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        focusedInfoView = infoCollectionView.item(at: .zero) as? InfoItemView
    }


    // MARK: API

    func updateOrigin(relativeTo verticalPosition: CGFloat, with buttonFrame: CGRect) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        let translatedPosition = verticalPosition + buttonFrame.origin.y + buttonFrame.height - view.frame.height
        let updatedVerticalPosition = translatedPosition < 0 ? screen.frame.minY : translatedPosition
        view.window?.setFrameOrigin(CGPoint(x: window.frame.origin.x, y: updatedVerticalPosition))
    }


    // MARK: Setup

    private func setupInfoItems() {
        let url = URL.from(Configuration.serverURL + "/static/mp4/MapExplorerInteraction.mp4")!
        let localURL = URL.from(Configuration.serverURL + "/Users/irshdc/dev/Caching-Server-UBC/static/mp4/MapExplorerInteraction.mp4")!
        let thumbnailURL = URL.from(Configuration.serverURL + "/static/png/MapExplorerInteraction.png")!
        let localThumbnailURL = URL.from(Configuration.serverURL + "/Users/irshdc/dev/Caching-Server-UBC/static/png/MapExplorerInteraction.png")!

        let media = Media(url: url, localURL: localURL, thumbnail: thumbnailURL, localThumbnail: localThumbnailURL, title: "", color: style.selectedColor)


        let label1 = InfoLabel(title: "Colors", description: "Throughout the entire installation, colours are consistent. Blue items indicate residential schools. pink items indicate events, green items indicate organizations and purple items indicate artifacts.")
        let label2 = InfoLabel(title: "Touch the Screen", description: "Tapping a pin, dragging the timeline, or pinching the map are great ways to get started exploring the installation.")
        let label3 = InfoLabel(title: "Individually", description: "When you begin moving the map, the timeline, or interacting with the nodes, the installation will automatically create an individual session for you.")
        let label4 = InfoLabel(title: "Group Interaction", description: "If you are working alone with the installation, the aeshtetic layer may move across all screens. As more people begin using the installation it will continuously divide down into a maximum of six individual sessions.")

        let labels = [label1, label2, label3, label4]

        let testItem1 = InfoItem(title: "Title 1", labels: labels, media: media)
        let testItem2 = InfoItem(title: "Title 2", labels: labels, media: media)
        let testItem3 = InfoItem(title: "Title 3", labels: labels, media: media)
        let testItem4 = InfoItem(title: "Title 4", labels: labels, media: media)
        let testItem5 = InfoItem(title: "Title 5", labels: labels, media: media)
        let testItem6 = InfoItem(title: "Title 6", labels: labels, media: media)
        let testItem7 = InfoItem(title: "Title 7", labels: labels, media: media)
        let testItem8 = InfoItem(title: "Title 8", labels: labels, media: media)
        let testItem9 = InfoItem(title: "Title 9", labels: labels, media: media)
        infoItems = [testItem1, testItem2, testItem3, testItem4, testItem5, testItem6, testItem7, testItem8, testItem9]
    }

    private func setupCollectionView() {
        infoCollectionView.register(InfoItemView.self, forItemWithIdentifier: InfoItemView.identifier)
        infoScrollView.horizontalScroller?.alphaValue = 0
    }

    private func setupGestures() {
        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: infoCollectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnView(gesture)
        }

        let playerTapGesture = TapGestureRecognizer()
        gestureManager.add(playerTapGesture, to: infoCollectionView)
        gestureManager.add(playerTapGesture, to: toggleButtonArea)
        playerTapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapPlayer(gesture)
        }

        let playerVolumeTapGesture = TapGestureRecognizer()
        gestureManager.add(playerVolumeTapGesture, to: volumeButtonArea)
        playerVolumeTapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapPlayerVolume(gesture)
        }

        playControlScrubGesture = PanGestureRecognizer(recognizedThreshold: 0)
        gestureManager.add(playControlScrubGesture, to: playerControlArea)
        playControlScrubGesture.gestureUpdated = { [weak self] gesture in
            self?.didScrubOnView(gesture)
        }
    }

    private func setupPageControl() {
        pageControl.color = .white
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.wantsLayer = true
        view.addSubview(pageControl)

        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pageControl.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pageControl.heightAnchor.constraint(equalToConstant: Constants.pageControlHeight).isActive = true
        pageControl.numberOfPages = UInt(infoItems.count)
    }


    // MARK: GestureResponder

    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        return bounds.contains(view.frame.transformed(from: window.frame))
    }

    func subview(contains position: CGPoint) -> Bool {
        return view.isHidden ? false : view.frame.contains(position)
    }


    // MARK: InfoViewDelegate

    func didToggleVolume(level: VolumeLevel) {
        volume = level
    }


    // MARK: NSCollectionViewDelegateFlowLayout and NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return infoItems.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let infoView = infoCollectionView.makeItem(withIdentifier: InfoItemView.identifier, for: indexPath) as? InfoItemView else {
            return NSCollectionViewItem()
        }

        infoView.infoItem = infoItems[indexPath.item]
        infoView.delegate = self
        return infoView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: view.frame.width, height: infoClipView.frame.height)
    }


    // MARK: Gesture Handling

    private func didPanOnView(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = infoCollectionView.visibleRect
            rect.origin.x -= pan.delta.dx
            infoCollectionView.scrollToVisible(rect)
            // If the view has been panned beyond the threshold, unfocus the view
            if rectPastThreshold(rect: rect, percent: Constants.unfocusThresholdPercent) {
                playControlScrubGesture.invalidate()
                focusedInfoView?.unfocus()
            }
        case .possible:
            let rect = infoCollectionView.visibleRect
            let offset = rect.origin.x / rect.width
            let index = round(offset)
            let margin = offset.truncatingRemainder(dividingBy: 1)
            let duration = margin < 0.5 ? margin : 1 - margin
            let origin = CGPoint(x: rect.width * index, y: 0)
            animateCollectionView(to: origin, duration: duration, for: Int(index))
        default:
            return
        }
    }

    private func didScrubOnView(_ gesture: GestureRecognizer) {
        if let pan = gesture as? PanGestureRecognizer {
            focusedInfoView?.handle(pan)
        }
    }

    private func didTapPlayer(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            focusedInfoView?.handlePlayer(tap)
        }
    }

    private func didTapPlayerVolume(_ gesture: GestureRecognizer) {
        if let tap = gesture as? TapGestureRecognizer, tap.state == .ended {
            focusedInfoView?.handleVolume(tap)
        }
    }


    // MARK: Helpers

    private func animateCollectionView(to point: CGPoint, duration: CGFloat, for index: Int) {
        infoCollectionView.animate(to: point, duration: duration, completion: { [weak self] in
            self?.finishedAnimatingToItem(index: index)
        })
    }

    private func finishedAnimatingToItem(index: Int) {
        pageControl.selectedPage = UInt(index)
        if let infoItemView = infoCollectionView.item(at: IndexPath(item: index, section: 0)) as? InfoItemView {
            focusedInfoView = infoItemView
            focusedInfoView?.set(volume: volume)
        }
    }

    /// Determines if the origin of the given rect has been offset by more then the given threshold
    private func rectPastThreshold(rect: CGRect, percent: CGFloat) -> Bool {
        let offset = rect.origin.x / rect.width
        let margin = offset.truncatingRemainder(dividingBy: 1)
        let distance = margin < 0.5 ? margin : 1 - margin
        return distance > percent
    }
}
