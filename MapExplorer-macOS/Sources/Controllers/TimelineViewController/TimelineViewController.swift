//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Timeline")

    @IBOutlet weak var backgroudImageView: NSImageView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineClipView: NSClipView!

    var gestureManager: GestureManager!
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()

    private struct Constants {
        static let timelineCellWidth: CGFloat = 20
        static let timelineSelectedCellWidth: CGFloat = 150
    }


    // MARK: Init

    static func instance() -> TimelineViewController {
        let storyboard = NSStoryboard(name: TimelineViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! TimelineViewController
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        TouchManager.instance.register(gestureManager)

        setupTimeline()
        setupBackground()
        setupGestures()
    }


    // MARK: Setup

    private func setupTimeline() {
        timelineHandler = TimelineHandler(timeline: timelineCollectionView)
        ConnectionManager.instance.timelineHandler = timelineHandler
        timelineCollectionView.register(TimelineItemView.self, forItemWithIdentifier: TimelineItemView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineHeaderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier)
        timelineCollectionView.dataSource = source
        timelineScrollView.horizontalScroller?.alphaValue = 0
    }

    private func setupBackground() {
        let name = appID % Configuration.appsPerScreen == 0 ? "MapLeft" : "MapRight"
        backgroudImageView.image = NSImage(named: name)
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = didPanOnTimeline(_:)

        let timelineTapGesture = TapGestureRecognizer()
        gestureManager.add(timelineTapGesture, to: timelineCollectionView)
        timelineTapGesture.gestureUpdated = didTapOnTimeline(_:)
    }


    // MARK: Gesture Handling

    private func didPanOnTimeline(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = timelineCollectionView.visibleRect
            rect.origin.x -= pan.delta.dx
            timelineHandler?.send(rect, for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didTapOnTimeline(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let location = tap.position,
            let indexPath = timelineCollectionView.indexPathForItem(at: location + timelineCollectionView.visibleRect.origin),
            let timelineItem = timelineCollectionView.item(at: indexPath) as? TimelineItemView else {
                return
        }

        if source.selectedIndexes.contains(indexPath.item) {
            source.selectedIndexes.remove(indexPath.item)
            timelineItem.set(highlighted: false)
        } else {
            source.selectedIndexes.insert(indexPath.item)
            timelineItem.set(highlighted: true)
        }
    }
}
