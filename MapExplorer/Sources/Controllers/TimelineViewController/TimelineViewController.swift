//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit
import MONode
import PromiseKit
import AppKit
import MacGestures


class TimelineViewController: NSViewController, GestureResponder, SelectionHandler, NSCollectionViewDelegateFlowLayout {
    static let storyboard = "Timeline"

    @IBOutlet weak var timelineBackgroundView: NSView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineClipView: NSClipView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineBaseView: NSView!
    @IBOutlet weak var decadeCollectionView: NSCollectionView!
    @IBOutlet weak var decadeClipView: NSClipView!
    @IBOutlet weak var decadeScrollView: NSScrollView!
    @IBOutlet weak var timelineIndicatorView: NSView!
    @IBOutlet weak var timelineBottomConstraint: NSLayoutConstraint!

    var gestureManager: GestureManager!
    private(set) var currentDate = Constants.initialDate
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()
    private let controlsSource = TimelineControlsDataSource()
    private var timerForTouch = [Touch: Timer]()
    private var itemForTouch = [Touch: Int]()
    private var createRecordForTouch = [Touch: Bool]()
    private var animating = false

    private struct Constants {
        static let animationDuration = 0.5
        static let controlItemWidth: CGFloat = 70
        static let timelineControlItemWidth: CGFloat = 70
        static let timelineIndicatorBorderRadius: CGFloat = 8
        static let timelineIndicatorBorderWidth: CGFloat = 2
        static let initialDate = (day: CGFloat(0.5), month: Month.january.rawValue, year: 1880)
        static let fadePercentage = 0.1
        static let resetAnimationDuration = 1.0
        static let recordSpawnOffset: CGFloat = 2
        static let longTouchDuration = 1.5
        static let verticalAnimationDuration = 1.2
        static let timelineIndicatorColor = CGColor.white
    }

    private struct Keys {
        static let id = "id"
        static let app = "app"
        static let type = "type"
        static let position = "position"
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
        TouchManager.instance.register(gestureManager, for: .timeline)
        SelectionManager.instance.delegate = self

        setupViews()
        setupTimeline()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        reset(animated: false)
    }


    // MARK: API

    func fade(out: Bool) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = out ? 0 : 1
        })
    }

    func set(date: RecordDate, animated: Bool) {
        currentDate.year = adjust(year: date.year)
        currentDate.month = adjust(month: date.month)
        currentDate.day = adjust(day: date.day)
        scrollCollectionViews(animated: animated)
    }

    func set(verticalPosition: CGFloat, animated: Bool) {
        if !animated {
            timelineBottomConstraint.constant = verticalPosition
            return
        }

        animating = true
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.verticalAnimationDuration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            self?.timelineBottomConstraint.animator().constant = verticalPosition
            }, completionHandler: { [weak self] in
                self?.animating = false
        })
    }

    func reset(animated: Bool) {
        set(date: RecordDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year + (appID * TimelineDecadeFlagLayout.yearsPerScreen)), animated: animated)
        let center = view.frame.height / 2 - timelineBackgroundView.frame.height / 2
        set(verticalPosition: center, animated: animated)
    }


    // MARK: Setup

    private func setupViews() {
        view.alphaValue = 0
        view.wantsLayer = true
        view.layer?.backgroundColor = style.timelineShadingColor.cgColor
        timelineBackgroundView.wantsLayer = true
        timelineBackgroundView.layer?.backgroundColor = style.timelineBackgroundColor.cgColor
    }

    private func setupTimeline() {
        timelineHandler = TimelineHandler(timelineViewController: self)
        ConnectionManager.instance.timelineHandler = timelineHandler
        timelineCollectionView.register(TimelineItemView.self, forItemWithIdentifier: TimelineItemView.identifier)
        timelineCollectionView.register(TimelineFlagView.self, forItemWithIdentifier: TimelineFlagView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineBorderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineBorderView.supplementaryKind, withIdentifier: TimelineBorderView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineHeaderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineTailView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineTailView.supplementaryKind, withIdentifier: TimelineTailView.identifier)
        timelineScrollView.horizontalScroller?.alphaValue = 0
        setupDataSource()
        setupControls()
        setupTimelineLayout()
    }

    private func setupControls() {
        controlsSource.set(firstYear: source.firstYear, lastYear: source.lastYear)
        controlsSource.decadeCollectionView = decadeCollectionView
        setupControls(in: decadeCollectionView, scrollView: decadeScrollView)
        timelineIndicatorView.wantsLayer = true
        timelineIndicatorView.layer?.cornerRadius = Constants.timelineIndicatorBorderRadius
        timelineIndicatorView.layer?.borderWidth = Constants.timelineIndicatorBorderWidth
        timelineIndicatorView.layer?.borderColor = Constants.timelineIndicatorColor
        setupHorizontalGradient(in: decadeScrollView)
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }

        let timelineMultiTapGesture = MultiTapGestureRecognizer(withDelay: false, cancelsOnMove: false)
        gestureManager.add(timelineMultiTapGesture, to: timelineCollectionView)
        timelineMultiTapGesture.touchUpdated = { [weak self] touch, state in
            self?.didTapOnTimelineItem(touch, state: state)
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: decadeCollectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnControl(gesture)
        }

        let basePanGesture = PanGestureRecognizer()
        gestureManager.add(basePanGesture, to: timelineBaseView)
        basePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanTimelineBase(gesture)
        }
    }


    // MARK: Gesture Handling

    private func didPanOnTimeline(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: gesture) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            updateDate(from: collectionView, with: pan.delta)
            timelineHandler?.send(date: RecordDate(date: currentDate), for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didTapOnTimelineItem(_ touch: Touch, state: GestureState) {
        switch state {
        case .began:
            let positionInTimeline = touch.position + timelineCollectionView.visibleRect.origin
            if let indexPath = timelineCollectionView.indexPathForItem(at: positionInTimeline),
                let item = timelineCollectionView.item(at: indexPath) as? TimelineFlagView,
                item.flagContains(positionInTimeline) {
                itemForTouch[touch] = indexPath.item
                startTimer(for: touch, item: indexPath.item)
                SelectionManager.instance.set(item: indexPath.item, selected: true)
            }
        case .failed:
            createRecordForTouch[touch] = false
        case .ended:
            timerForTouch[touch]?.invalidate()
            if let item = itemForTouch[touch] {
                SelectionManager.instance.set(item: item, selected: false)
                if let timelineItem = timelineCollectionView.item(at: IndexPath(item: item, section: 0)) as? TimelineFlagView, let status = createRecordForTouch[touch], status {
                    postRecordNotification(for: timelineItem)
                }
            }

            timerForTouch.removeValue(forKey: touch)
            itemForTouch.removeValue(forKey: touch)
            createRecordForTouch.removeValue(forKey: touch)
        default:
            break
        }
    }

    private func didPanOnControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: gesture) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            updateDate(from: collectionView, with: pan.delta)
            timelineHandler?.send(date: RecordDate(date: currentDate), for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didPanTimelineBase(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            let offset = clamp(timelineBottomConstraint.constant + pan.delta.dy, min: 0, max: view.frame.height - timelineBackgroundView.frame.height)
            timelineHandler?.send(verticalPosition: offset, for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }


    // MARK: GestureResponder

    func draggableInside(bounds: CGRect) -> Bool {
        return true
    }

    func subview(contains position: CGPoint) -> Bool {
        return true
    }


    // MARK: Date Functions

    private func updateDate(from collectionView: NSCollectionView, with offset: CGVector) {
        let days = -(offset.dx / Constants.timelineControlItemWidth)

        switch collectionView {
        case decadeCollectionView:
            add(days: days * 120)
        case timelineCollectionView:
            addTimelineDays(with: offset)
        default:
            return
        }
    }

    private func addTimelineDays(with offset: CGVector) {
        let days = -(offset.dx / TimelineDecadeFlagLayout.yearWidth)
        add(days: days * 12)
    }

    private func adjust(day: CGFloat) -> CGFloat {
        let months = Int(day)

        if day < 0 {
            currentDate.month = adjust(month: months + currentDate.month - 1)
            return 1 - (abs(day) + CGFloat(months))
        } else if day > 1 {
            currentDate.month = adjust(month: months + currentDate.month)
            return day - CGFloat(months)
        }

        return day
    }

    private func adjust(month: Int) -> Int {
        let years = month / 12
        let remainder = month % 12

        if month < 0 {
            currentDate.year = adjust(year: currentDate.year + years - 1)
            return 12 + remainder
        } else if month > 11 {
            currentDate.year = adjust(year: currentDate.year + years + 1)
            return remainder
        }

        return month
    }

    private func adjust(year: Int) -> Int {
        if year < source.firstYear {
            return source.lastYear + (year - source.firstYear + 1)
        } else if year > source.lastYear {
            return source.firstYear + (year - source.lastYear - 1)
        }

        return year
    }

    private func add(days: CGFloat) {
        var newDay = currentDate.day + days
        let months = Int(newDay)

        if newDay < 0 {
            add(months: months - 1)
            newDay = 1 - (abs(newDay) + CGFloat(months))
            currentDate.day = newDay
        } else if newDay > 1 {
            add(months: months)
            newDay -= CGFloat(months)
            currentDate.day = newDay
        } else {
            currentDate.day = newDay
        }
    }

    private func add(months: Int) {
        if months.isZero { return }
        var newMonth = currentDate.month + months
        let years = newMonth / 12
        let remainder = newMonth % 12

        if newMonth < 0 {
            add(years: years - 1)
            newMonth = 12 + remainder
            currentDate.month = newMonth
        } else if newMonth > 11 {
            add(years: years)
            newMonth = remainder
            currentDate.month = newMonth
        } else {
            currentDate.month = newMonth
        }
    }

    private func add(years: Int) {
        if years.isZero { return }
        let diff = years % source.years.count
        var newYear = currentDate.year + diff

        if newYear < source.firstYear {
            newYear = source.lastYear - (source.firstYear - newYear) + 1
            currentDate.year = newYear
        } else if newYear > source.lastYear {
            newYear = source.firstYear + (newYear - source.lastYear) - 1
            currentDate.year = newYear
        } else {
            currentDate.year = newYear
        }
    }


    // MARK: SelectionHandler

    // Updates the highlighted state of the given items, updates tail views
    func handle(items: Set<Int>, highlighted: Bool) {
        for item in items {
            set(item: item, highlighted: highlighted)
        }
        updateTailViews()
    }

    /// Updates the state of one individual item
    func handle(item: Int, selected: Bool) {
        set(item: item, selected: selected, animated: true)
    }

    /// Replaces the current selection with the given items
    func replace(selection items: Set<TimelineSelection>) {
        // Unselect current indexes that are not in the new selection
        source.selectedIndexes.filter({ index in !items.contains(where: { $0.index == index }) }).forEach { index in
            set(item: index, selected: false, animated: false)
        }
        // Select indexes that are not currently selected
        items.filter({ !source.selectedIndexes.contains($0.index) }).forEach { selection in
            set(item: selection.index, selected: true, animated: false)
        }
    }

    /// Replaces the current highlights with the given items
    func replace(highlighted items: Set<Int>) {
        // Unhighlight current indexes that are not in the new highlighted indexes
        source.highlightedIndexes.filter({ !items.contains($0) }).forEach { index in
            set(item: index, highlighted: false)
        }
        // Highlight indexes that are not currently highlighted
        items.filter({ !source.highlightedIndexes.contains($0) }).forEach { index in
            set(item: index, highlighted: true)
        }
        updateTailViews()
    }

    private func set(item: Int, selected: Bool, animated: Bool) {
        // Update data source
        source.set(index: item, selected: selected)

        // Update views
        let timelineFlagView = timelineCollectionView.item(at: IndexPath(item: item, section: 0)) as? TimelineFlagView
        timelineFlagView?.set(highlighted: selected, animated: animated)
        setDuplicate(original: item, selected: selected, animated: animated)
    }

    private func set(item: Int, highlighted: Bool) {
        // Update data source
        source.set(index: item, highlighted: highlighted)

        // Update model
        let event = source.events[item]
        event.highlighted = highlighted
        setDuplicate(original: item, highlighted: highlighted)
    }


    // MARK: Helpers

    private func setupControls(in collectionView: NSCollectionView, scrollView: NSScrollView) {
        collectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        collectionView.register(TimelineBorderView.self, forItemWithIdentifier: TimelineBorderView.identifier)
        scrollView.horizontalScroller?.alphaValue = 0
        collectionView.dataSource = controlsSource
        collectionView.reloadData()
    }

    private func setupHorizontalGradient(in view: NSView) {
        let transparent = CGColor.clear
        let opaque = style.darkBackgroundOpaque.cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1 - Constants.fadePercentage), 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        view.wantsLayer = true
        view.layer?.mask = gradientLayer
    }

    private func postRecordNotification(for timelineItem: TimelineFlagView) {
        let translatedXPosition = timelineItem.view.frame.origin.x + (timelineItem.view.frame.width / 2) - timelineCollectionView.visibleRect.origin.x
        let transformedXPosition = max(0, translatedXPosition)
        var adjustedFrame = timelineItem.view.frame
        adjustedFrame.origin.y = timelineItem.view.frame.origin.y + timelineItem.view.frame.height - TimelineFlagView.flagHeight(for: timelineItem.event) - Constants.recordSpawnOffset
        let transformedYPosition = adjustedFrame.transformed(from: timelineScrollView.frame).transformed(from: timelineBackgroundView.frame).origin.y
        postRecordNotification(for: timelineItem.event.type, id: timelineItem.event.id, at: CGPoint(x: transformedXPosition, y: transformedYPosition))
    }

    private func scrollCollectionViews(animated: Bool = false) {
        let centerInset = Constants.controlItemWidth * 3
        let yearOffset = (CGFloat(currentDate.year.array.last!) / 10) * Constants.controlItemWidth
        let decade = decadeFor(year: currentDate.year)
        let decadeMaxX = CGFloat(controlsSource.decades.count) * Constants.controlItemWidth
        let decadeIndexBoundary = decade < controlsSource.decades.first! ? 0 : controlsSource.decades.count
        let decadeIndex = controlsSource.decades.index(of: decade) != nil ? controlsSource.decades.index(of: decade) : decadeIndexBoundary
        let decadeX = CGFloat(decadeIndex!) * Constants.controlItemWidth
        var decadeRect = decadeCollectionView.visibleRect
        decadeRect.origin.x = decadeX - centerInset + yearOffset
        if decadeRect.origin.x < 0 {
            decadeRect.origin.x = decadeMaxX + decadeRect.origin.x
        }

        if animated {
            decadeCollectionView.animate(to: decadeRect.origin, duration: Constants.resetAnimationDuration)
        } else {
            decadeCollectionView.scrollToVisible(decadeRect)
        }

        scrollTimeline(animated: animated)
    }

    private func scrollTimeline(animated: Bool = false) {
        let timelineMaxX = CGFloat(source.years.count) * TimelineDecadeFlagLayout.yearWidth
        let timelineYearIndex = source.years.index(of: currentDate.year) != nil ? source.years.index(of: currentDate.year) : currentDate.year < source.firstYear ? -1 : source.years.count - 1
        var timelineRect = timelineCollectionView.visibleRect
        let timelineMonthOffset = ((CGFloat(currentDate.month) + currentDate.day - 0.5) / 12) * TimelineDecadeFlagLayout.yearWidth
        let timelineYearX = CGFloat(timelineYearIndex!) * TimelineDecadeFlagLayout.yearWidth
        timelineRect.origin.x = timelineYearX - timelineRect.width / 2 + timelineMonthOffset
        if timelineRect.origin.x < 0 {
            timelineRect.origin.x = timelineMaxX + timelineRect.origin.x
        }

        if animated {
            timelineCollectionView.animate(to: timelineRect.origin, duration: Constants.resetAnimationDuration)
        } else {
            timelineCollectionView.scrollToVisible(timelineRect)
        }
    }

    private func decadeFor(year: Int) -> Int {
        return year / 10 * 10
    }

    private func setDuplicate(original item: Int, selected: Bool, animated: Bool) {
        guard let duplicateIndex = source.getDuplicateIndex(original: item) else {
            return
        }

        let timelineFlagView = timelineCollectionView.item(at: IndexPath(item: duplicateIndex, section: 0)) as? TimelineFlagView
        timelineFlagView?.set(highlighted: selected, animated: animated)
    }

    private func setDuplicate(original item: Int, highlighted: Bool) {
        guard let duplicateIndex = source.getDuplicateIndex(original: item) else {
            return
        }

        let event = source.events[duplicateIndex]
        event.highlighted = highlighted
    }

    private func postRecordNotification(for type: RecordType, id: Int, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.app: appID, Keys.id: id, Keys.position: location.toJSON(), Keys.type: type.rawValue]
        DistributedNotificationCenter.default().postNotificationName(RecordNotification.display.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func setupDataSource() {
        let schools = RecordManager.instance.records(for: .school)
        let events = RecordManager.instance.records(for: .event)
        let collections = RecordManager.instance.records(for: .collection).compactMap { $0 as? RecordCollection }.filter { $0.collectionType == .timeline }
        let records: [Record] = schools + events + collections

        source.setup(with: records)
    }

    private func setupTimelineLayout() {
        timelineCollectionView.collectionViewLayout = TimelineDecadeFlagLayout()
        timelineCollectionView.dataSource = source
        reset(animated: false)
        timelineCollectionView.reloadData()
    }

    /// Causes all timeline tail view's to redraw
    private func updateTailViews() {
        let tailViews = timelineCollectionView.visibleSupplementaryViews(ofKind: TimelineTailView.supplementaryKind) as [NSView]
        for tailView in tailViews {
            tailView.needsDisplay = true
        }
    }

    private func startTimer(for touch: Touch, item: Int) {
        createRecordForTouch[touch] = true
        timerForTouch[touch] = Timer.scheduledTimer(withTimeInterval: Constants.longTouchDuration, repeats: false) { [weak self] _ in
            self?.timerFired(for: touch, item: item)
        }
    }

    private func timerFired(for touch: Touch, item: Int) {
        SelectionManager.instance.highlight(item: item)
        createRecordForTouch[touch] = false
    }
}
