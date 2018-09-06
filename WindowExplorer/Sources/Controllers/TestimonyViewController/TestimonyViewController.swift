//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import PromiseKit


protocol TestimonyDelegate: class {
    func testimonyDidClose()
}


class TestimonyViewController: BaseViewController, NSCollectionViewDelegateFlowLayout, NSCollectionViewDataSource {
    static let storyboard = NSStoryboard.Name(rawValue: "Testimony")

    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var collectionClipView: NSClipView!
    @IBOutlet weak var collectionScrollView: FadingScrollView!

    weak var testimonyDelegate: TestimonyDelegate?
    private var testimonies = [Media]()
    private let relationshipHelper = RelationshipHelper()
    private var selectedTestimonies = Set<Media>()

    private struct Constants {
        static let testimonyCellHeight: CGFloat = 160
        static let closeWindowTimeoutPeriod = 300.0
        static let animationDuration = 1.0
        static let windowHeaderTitle = "Survivors Speak"
        static let artifactTestimonyIDs = [9454, 9455, 9456, 9457, 9458, 9459, 9460, 9461, 9462, 9463, 9464, 9465]
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        windowDragArea.alphaValue = 0
        collectionView.alphaValue = 0
        relationshipHelper.parent = self
        relationshipHelper.controllerClosed = { [weak self] controller in
            self?.unselectTestimonyForController(controller)
        }
        titleLabel.attributedStringValue = NSAttributedString(string: Constants.windowHeaderTitle, attributes: style.windowTitleAttributes)
        windowDragAreaHighlight.layer?.backgroundColor = style.testimonyColor.cgColor

        setupTestimonies()
        setupCollectionView()
        setupGestures()
        animateViewIn()
    }


    // MARK: API

    func updateOrigin(to point: CGPoint, animating: Bool) {
        if animating {
            animate(to: point)
        } else {
            view.window?.setFrameOrigin(point)
        }

        relationshipHelper.reset()
    }


    // MARK: Setup

    private func setupTestimonies() {
        RecordFactory.records(for: .artifact, ids: Constants.artifactTestimonyIDs) { [weak self] artifacts in
            if let artifacts = artifacts {
                self?.load(artifacts)
            }
        }
    }

    private func setupCollectionView() {
        collectionView.register(TestimonyItemView.self, forItemWithIdentifier: TestimonyItemView.identifier)
        collectionScrollView.verticalScroller?.alphaValue = 0
    }

    private func setupGestures() {
        let relatedViewPan = PanGestureRecognizer()
        gestureManager.add(relatedViewPan, to: collectionView)
        relatedViewPan.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewPan(gesture)
        }

        let relatedItemTap = TapGestureRecognizer(withDelay: true)
        gestureManager.add(relatedItemTap, to: collectionView)
        relatedItemTap.gestureUpdated = { [weak self] gesture in
            self?.handleCollectionViewTap(gesture)
        }
    }


    // MARK: Overrides

    override func animateViewIn() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            windowDragArea.animator().alphaValue = 1
            collectionView.animator().alphaValue = 1
        })
    }

    override func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            windowDragArea.animator().alphaValue = 0
            collectionView.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }

    override func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.closeTimerFired()
        }
    }

    override func close() {
        testimonyDelegate?.testimonyDidClose()
        super.close()
    }


    // MARK: Gesture Handling

    override func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        case .began, .ended:
            relationshipHelper.reset()
        default:
            return
        }
    }

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = collectionView.visibleRect
            rect.origin.y += pan.delta.dy
            collectionView.scrollToVisible(rect)
            collectionScrollView.updateGradient()
        default:
            return
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let testimonyItemView = collectionView.item(at: indexPath) as? TestimonyItemView,
            let testimony = testimonyItemView.testimony else {
                return
        }

        testimonyItemView.set(highlighted: true)
        select(testimony)
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return testimonies.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let testimonyView = collectionView.makeItem(withIdentifier: TestimonyItemView.identifier, for: indexPath) as? TestimonyItemView else {
            return NSCollectionViewItem()
        }

        let testimony = testimonies[indexPath.item]
        testimonyView.testimony = testimony
        testimonyView.set(highlighted: selectedTestimonies.contains(testimony))
        return testimonyView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: view.frame.size.width, height: Constants.testimonyCellHeight)
    }


    // MARK: Helpers

    private func load(_ records: [Record]) {
        let media = records.reduce(Set<Media>()) { media, record -> Set<Media> in
            let recordMedia = Set<Media>(record.media)
            return media.union(recordMedia)
        }
        media.forEach { $0.tintColor = style.testimonyColor }
        testimonies = Array(media).sorted(by: { $0.title ?? "" < $1.title ?? "" })
        collectionView.reloadData()
        collectionView.performBatchUpdates(nil) { [weak self] finished in
            if let strongSelf = self, finished {
                strongSelf.collectionScrollView.updateGradient()
                strongSelf.animateViewIn()
            }
        }
    }

    private func select(_ testimony: Media) {
        if let windowType = WindowType(for: testimony) {
            selectedTestimonies.insert(testimony)
            relationshipHelper.display(windowType)
        }
    }

    private func unselectTestimonyForController(_ controller: BaseViewController) {
        guard let mediaViewController = controller as? MediaViewController, let testimony = mediaViewController.media else {
            return
        }

        selectedTestimonies.remove(testimony)

        for view in collectionView.visibleItems().compactMap({ $0 as? TestimonyItemView }) {
            if let testimony = view.testimony {
                view.set(highlighted: selectedTestimonies.contains(testimony))
            }
        }
    }

    private func closeTimerFired() {
        if relationshipHelper.isEmpty() {
            animateViewOut()
        }
    }
}
