//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa
import MacGestures


protocol InfoViewDelegate: class {
    func didToggleVolume(level: VolumeLevel)
}


class InfoViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, GestureResponder, InfoViewDelegate {
    static let storyboard = "Info"

    @IBOutlet weak var infoScrollView: FadingScrollView!
    @IBOutlet weak var infoClipView: NSClipView!
    @IBOutlet weak var infoCollectionView: NSCollectionView!
    @IBOutlet weak var toggleButtonArea: NSView!
    @IBOutlet weak var volumeButtonArea: NSView!
    @IBOutlet weak var playerControlArea: NSView!
    @IBOutlet weak var toggleLeftButton: ImageView!
    @IBOutlet weak var toggleRightButton: ImageView!

    var appID: Int!
    var gestureManager: GestureManager!
    private var infoItems = [InfoItem]()
    private var pageControl = PageControl()
    private var volume = VolumeLevel.low
    private var playControlScrubGesture: PanGestureRecognizer!
    private weak var focusedInfoView: InfoItemView?

    private struct Constants {
        static let pageControlHeight: CGFloat = 20
        static let unfocusThresholdPercent: CGFloat = 0.15
        static let fadeAnimationDuration = 0.5
        static let pageControlIndicatorSize: CGFloat = 12
        static let toggleAnimationDuration = 0.4
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupGestures()
        setupCollectionView()
        setupToggleButtons()
        setupPageControl()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        focusedInfoView = infoCollectionView.item(at: .zero) as? InfoItemView
    }


    // MARK: API

    /// Resets videos and collection view offset
    func reset() {
        pageControl.selectedPage = UInt(0)
        infoCollectionView.scroll(.zero)
        for infoItem in infoCollectionView.visibleItems().compactMap({ $0 as? InfoItemView }) {
            infoItem.playerControl?.reset()
        }
    }


    // MARK: Setup

    private func setupView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func setupCollectionView() {
        infoItems = parseInfoItems()
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

        let leftToggleTap = TapGestureRecognizer()
        gestureManager.add(leftToggleTap, to: toggleLeftButton)
        leftToggleTap.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended {
                self?.toggleInfoItem(forward: false)
            }
        }

        let rightToggleTap = TapGestureRecognizer()
        gestureManager.add(rightToggleTap, to: toggleRightButton)
        rightToggleTap.gestureUpdated = { [weak self] gesture in
            if gesture.state == .ended {
                self?.toggleInfoItem(forward: true)
            }
        }
    }

    private func setupToggleButtons() {
        toggleLeftButton.wantsLayer = true
        toggleLeftButton.layer?.cornerRadius = toggleLeftButton.frame.width / 2
        toggleLeftButton.layer?.backgroundColor = NSColor.gray.cgColor
        let leftButtonImage = NSImage(named: "left-arrow-icon")
        toggleLeftButton.set(leftButtonImage, scaling: .center)
        toggleRightButton.wantsLayer = true
        toggleRightButton.layer?.cornerRadius = toggleRightButton.frame.width / 2
        toggleRightButton.layer?.backgroundColor = NSColor.gray.cgColor
        let rightButtonImage = NSImage(named: "right-arrow-icon")
        toggleRightButton.set(rightButtonImage, scaling: .center)
    }

    private func setupPageControl() {
        pageControl.color = style.menuSelectedColor
        pageControl.unselectedColor = NSColor.gray
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.wantsLayer = true
        pageControl.indicatorSize = Constants.pageControlIndicatorSize
        view.addSubview(pageControl)

        pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pageControl.centerYAnchor.constraint(equalTo: toggleLeftButton.centerYAnchor).isActive = true
        pageControl.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
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
        return view.frame.contains(position)
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
            animateCollectionView(to: origin, duration: Double(duration), for: Int(index))
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

    /// Generates the info items from the stored plist
    private func parseInfoItems() -> [InfoItem] {
        if let path = Bundle.main.path(forResource: "info_content", ofType: "plist") {
            let url = URL(fileURLWithPath: path)
            if let data = try? Data(contentsOf: url), let plist = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil), let itemsJSON = plist as? [JSON] {
                return itemsJSON.compactMap { InfoItem(json: $0) }
            }
        }

        return []
    }

    /// Animate collection view to the view at the given index
    private func animateCollectionView(to point: CGPoint, duration: TimeInterval, for index: Int) {
        infoCollectionView.animate(to: point, duration: duration, completion: { [weak self] in
            self?.finishedAnimatingToItem(index: index)
        })
    }

    /// Update selected page and set focused item
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

    private func toggleInfoItem(forward: Bool) {
        playControlScrubGesture.invalidate()
        focusedInfoView?.unfocus()
        let current = CGFloat(pageControl.selectedPage)
        let target = forward ? current + 1 : current - 1
        let maxIndex = max(infoItems.count - 1, 0)
        let index = clamp(target, min: 0, max: CGFloat(maxIndex))
        let rect = infoCollectionView.visibleRect
        let origin = CGPoint(x: rect.width * index, y: 0)
        animateCollectionView(to: origin, duration: Constants.toggleAnimationDuration, for: Int(index))
    }
}
