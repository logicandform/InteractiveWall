//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit
import MONode
import PromiseKit
import AppKit


class TimelineViewController: NSViewController, GestureResponder, SelectionHandler, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Timeline")

    @IBOutlet weak var timelineBackgroundView: NSView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineClipView: NSClipView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var monthCollectionView: NSCollectionView!
    @IBOutlet weak var monthClipView: NSClipView!
    @IBOutlet weak var monthScrollView: NSScrollView!
    @IBOutlet weak var yearCollectionView: NSCollectionView!
    @IBOutlet weak var yearClipView: NSClipView!
    @IBOutlet weak var yearScrollView: NSScrollView!
    @IBOutlet weak var decadeCollectionView: NSCollectionView!
    @IBOutlet weak var decadeClipView: NSClipView!
    @IBOutlet weak var decadeScrollView: NSScrollView!
    @IBOutlet weak var timelineIndicatorView: NSView!

    var gestureManager: GestureManager!
    var currentDate = Constants.initialDate
    private(set) var timelineType = TimelineType.decade
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()
    private let controlsSource = TimelineControlsDataSource()

    private var timerForTouch = [Touch: Timer]()
    private var itemForTouch = [Touch: Int]()
    private var createRecordForTouch = [Touch: Bool]()

    private struct Constants {
        static let timelineCellWidth: CGFloat = 20
        static let timelineSelectedCellWidth: CGFloat = 150
        static let animationDuration = 0.5
        static let controlItemWidth: CGFloat = 70
        static let timelineControlWidth: CGFloat = 490
        static let timelineControlItemWidth: CGFloat = 70
        static let timelineIndicatorBorderRadius: CGFloat = 8
        static let timelineIndicatorBorderWidth: CGFloat = 2
        static let initialDate = (day: CGFloat(0.5), month: Month.january.rawValue, year: 1880)
        static let fadePercentage = 0.1
        static let resetAnimationDuration = 1.0
        static let recordSpawnOffset: CGFloat = 2
        static let longTouchDuration = 1.5
    }

    private struct Keys {
        static let id = "id"
        static let appID = "map"
        static let position = "position"
    }


    // MARK: Init

    static func instance() -> TimelineViewController {
        let storyboard = NSStoryboard(name: TimelineViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! TimelineViewController
    }


    // MARK: API

    func fade(out: Bool) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            timelineBackgroundView.animator().alphaValue = out ? 0 : 1
        })
    }

    func setDate(_ date: TimelineDate, animated: Bool = false) {
        currentDate.year = adjust(year: date.year)
        currentDate.month = adjust(month: date.month)
        currentDate.day = adjust(day: date.day)
        scrollCollectionViews(animated: animated)
    }

    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        gestureManager.displayTouchIndicators = false
        TouchManager.instance.register(gestureManager, for: .timeline)
        SelectionManager.instance.delegate = self

        setupBackground()
        setupTimeline()
        setupControls()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setupControlGradients()
        timelineHandler?.reset()
    }


    // MARK: Setup

    func setupTimelineDate() {
        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month + appID, year: Constants.initialDate.year), animated: true)
        case is TimelineYearLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year + appID), animated: true)
        case is TimelineDecadeLayout, is TimelineDecadeStackedLayout, is TimelineDecadeFlagLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year + (appID * 10)), animated: true)
        case is TimelineCenturyLayout:
            setDate(TimelineDate(day: Constants.initialDate.day, month: Constants.initialDate.month, year: Constants.initialDate.year), animated: true)
        default:
            return
        }
    }

    private func setupBackground() {
        timelineBackgroundView.alphaValue = 0
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
        timelineCollectionView.dataSource = source
        timelineScrollView.horizontalScroller?.alphaValue = 0
        createRecords()
    }

    private func setupControls() {
        controlsSource.monthCollectionView = monthCollectionView
        controlsSource.yearCollectionView = yearCollectionView
        controlsSource.decadeCollectionView = decadeCollectionView
        setupControls(in: monthCollectionView, scrollView: monthScrollView)
        setupControls(in: yearCollectionView, scrollView: yearScrollView)
        setupControls(in: decadeCollectionView, scrollView: decadeScrollView)
        timelineIndicatorView.wantsLayer = true
        timelineIndicatorView.layer?.cornerRadius = Constants.timelineIndicatorBorderRadius
        timelineIndicatorView.layer?.borderWidth = Constants.timelineIndicatorBorderWidth
        timelineIndicatorView.layer?.borderColor = style.selectedColor.cgColor
    }

    private func setupControlGradients() {
        setupHorizontalGradient(in: monthScrollView)
        setupHorizontalGradient(in: yearScrollView)
        setupHorizontalGradient(in: decadeScrollView)
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }

        let timelineLongTapGesture = TapGestureRecognizer(withDelay: false, cancelsOnMove: false)
        gestureManager.add(timelineLongTapGesture, to: timelineCollectionView)
        timelineLongTapGesture.touchUpdated = { [weak self] gesture, touch in
            self?.didLongTapOnTimeline(gesture, touch)
        }

        addGestures(to: monthCollectionView)
        addGestures(to: yearCollectionView)
        addGestures(to: decadeCollectionView)
    }

    private func addGestures(to collectionView: NSCollectionView) {
        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: collectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnControl(gesture)
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
            timelineHandler?.send(date: TimelineDate(date: currentDate), for: pan.state)
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func didLongTapOnTimeline(_ gesture: GestureRecognizer, _ touch: Touch) {
        guard let tap = gesture as? TapGestureRecognizer else {
            return
        }

        switch tap.state {
        case .began:
            if let location = tap.position,
                let indexPath = timelineCollectionView.indexPathForItem(at: location + timelineCollectionView.visibleRect.origin) {
                itemForTouch[touch] = indexPath.item
                startTimer(for: touch, item: indexPath.item)
                SelectionManager.instance.set(item: indexPath.item, selected: true)
            }
        case .failed:
            createRecordForTouch[touch] = false
        case .ended, .doubleTapped:
            timerForTouch[touch]?.invalidate()
            if let item = itemForTouch[touch], let timelineItem = timelineCollectionView.item(at: IndexPath(item: item, section: 0)) as? TimelineFlagView {
                SelectionManager.instance.set(item: item, selected: false)
                if let status = createRecordForTouch[touch], status {
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
            timelineHandler?.send(date: TimelineDate(date: currentDate))
        case .ended:
            timelineHandler?.endActivity()
        case .possible, .failed:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    private func updateDate(from collectionView: NSCollectionView, with offset: CGVector) {
        let days = -(offset.dx / Constants.timelineControlItemWidth)

        switch collectionView {
        case monthCollectionView:
            add(days: days)
        case yearCollectionView:
            add(days: days * 12)
        case decadeCollectionView:
            add(days: days * 120)
        case timelineCollectionView:
            addTimelineDays(with: offset)
        default:
            return
        }
    }

    private func addTimelineDays(with offset: CGVector) {
        let days = -(offset.dx / CGFloat(timelineType.sectionWidth))

        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            add(days: days)
        case is TimelineYearLayout, is TimelineDecadeLayout, is TimelineCenturyLayout, is TimelineDecadeStackedLayout, is TimelineDecadeFlagLayout:
            add(days: days * 12)
        default:
            return
        }
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


    // MARK: Control Selection

    private func setupControls(in collectionView: NSCollectionView, scrollView: NSScrollView) {
        collectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        collectionView.register(TimelineBorderView.self, forItemWithIdentifier: TimelineBorderView.identifier)
        scrollView.horizontalScroller?.alphaValue = 0
        collectionView.dataSource = controlsSource
    }

    private func setupHorizontalGradient(in view: NSView) {
        view.wantsLayer = true
        let transparent = CGColor.clear
        let opaque = style.darkBackgroundOpaque.cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1 - Constants.fadePercentage), 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        view.layer?.mask = gradientLayer
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
    func replace(selection items: Set<Int>) {
        // Unselect current indexes that are not in the new selection
        source.selectedIndexes.filter({ !items.contains($0) }).forEach { index in
            set(item: index, selected: false, animated: false)
        }
        // Select indexes that are not currently selected
        items.filter({ !source.selectedIndexes.contains($0) }).forEach { index in
            set(item: index, selected: true, animated: false)
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
        if selected {
            source.selectedIndexes.insert(item)
        } else {
            source.selectedIndexes.remove(item)
        }

        // Update views
        if let timelineFlagView = timelineCollectionView.item(at: IndexPath(item: item, section: 0)) as? TimelineFlagView {
            timelineFlagView.set(highlighted: selected, animated: animated)
        }
    }

    private func set(item: Int, highlighted: Bool) {
        // Update data source
        if highlighted {
            source.highlightedIndexes.insert(item)
        } else {
            source.highlightedIndexes.remove(item)
        }

        // Update model
        let event = source.events[item]
        event.highlighted = highlighted
    }


    // MARK: Helpers

    private func postRecordNotification(for timelineItem: TimelineFlagView) {
        let translatedXPosition = timelineItem.view.frame.origin.x + (timelineItem.view.frame.width / 2) - timelineCollectionView.visibleRect.origin.x
        let transformedXPosition = max(0, translatedXPosition)
        var adjustedFrame = timelineItem.view.frame
        adjustedFrame.origin.y = timelineItem.view.frame.origin.y + timelineItem.view.frame.height - TimelineFlagView.flagHeight(for: timelineItem.event) - Constants.recordSpawnOffset
        let transformedYPosition = adjustedFrame.transformed(from: timelineScrollView.frame).transformed(from: timelineBackgroundView.frame).origin.y
        postRecordNotification(for: timelineItem.event.type, with: timelineItem.event.id, at: CGPoint(x: transformedXPosition, y: transformedYPosition))
    }

    private func scrollCollectionViews(animated: Bool = false) {
        let centerInset = Constants.controlItemWidth * 3

        let dayOffset = (currentDate.day - 0.5) * Constants.controlItemWidth
        let monthMaxX = CGFloat(Month.allValues.count) * Constants.controlItemWidth
        let monthX = CGFloat(currentDate.month) * Constants.controlItemWidth
        var monthRect = monthCollectionView.visibleRect
        monthRect.origin.x = monthX - centerInset + dayOffset
        if monthRect.origin.x < 0 {
            monthRect.origin.x = monthMaxX + monthRect.origin.x
        }

        let monthOffset = (CGFloat(currentDate.month) / 12) * Constants.controlItemWidth
        let yearMaxX = CGFloat(source.years.count) * Constants.controlItemWidth
        let yearIndex = source.years.index(of: currentDate.year) != nil ? source.years.index(of: currentDate.year) : currentDate.year < source.firstYear ? -1 : source.years.count - 1
        let yearX = CGFloat(yearIndex!) * Constants.controlItemWidth
        var yearRect = yearCollectionView.visibleRect
        yearRect.origin.x = yearX - centerInset + monthOffset
        if yearRect.origin.x < 0 {
            yearRect.origin.x = yearMaxX + yearRect.origin.x
        }

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
            monthCollectionView.animate(to: monthRect.origin, duration: Constants.resetAnimationDuration)
            yearCollectionView.animate(to: yearRect.origin, duration: Constants.resetAnimationDuration)
            decadeCollectionView.animate(to: decadeRect.origin, duration: Constants.resetAnimationDuration)
        } else {
            monthCollectionView.scrollToVisible(monthRect)
            yearCollectionView.scrollToVisible(yearRect)
            decadeCollectionView.scrollToVisible(decadeRect)
        }

        scrollTimeline(animated: animated)
    }

    private func scrollTimeline(animated: Bool = false) {
        var timelineMaxX = CGFloat(source.years.count) * CGFloat(timelineType.sectionWidth)
        let timelineYearIndex = source.years.index(of: currentDate.year) != nil ? source.years.index(of: currentDate.year) : currentDate.year < source.firstYear ? -1 : source.years.count - 1
        var timelineRect = timelineCollectionView.visibleRect
        let previousRect = timelineRect

        switch timelineCollectionView.collectionViewLayout {
        case is TimelineMonthLayout:
            timelineMaxX = CGFloat(source.years.count) * CGFloat(timelineType.sectionWidth) * 12
            let timelineMonthOffset = ((CGFloat(currentDate.month) + currentDate.day - 0.5)) * CGFloat(timelineType.sectionWidth)
            let timelineYearX = CGFloat(timelineYearIndex!) * CGFloat(timelineType.sectionWidth) * 12
            timelineRect.origin.x = timelineYearX - timelineRect.width / 2 + timelineMonthOffset
            if timelineRect.origin.x < 0 {
                timelineRect.origin.x = timelineMaxX + timelineRect.origin.x
            }
            timelineCollectionView.scrollToVisible(timelineRect)
        case is TimelineYearLayout, is TimelineCenturyLayout, is TimelineDecadeLayout, is TimelineDecadeStackedLayout, is TimelineDecadeFlagLayout:
            let timelineMonthOffset = ((CGFloat(currentDate.month) + currentDate.day - 0.5) / 12) * CGFloat(timelineType.sectionWidth)
            let timelineYearX = CGFloat(timelineYearIndex!) * CGFloat(timelineType.sectionWidth)
            timelineRect.origin.x = timelineYearX - timelineRect.width / 2 + timelineMonthOffset
            if timelineRect.origin.x < 0 {
                timelineRect.origin.x = timelineMaxX + timelineRect.origin.x
            }
        default:
            return
        }

        if animated {
            timelineCollectionView.animate(to: timelineRect.origin, duration: Constants.resetAnimationDuration)
        } else {
            timelineCollectionView.scrollToVisible(timelineRect)
        }

        let indexPaths = timelineCollectionView.indexPathsForVisibleItems()
        let tailIndexPaths = timelineCollectionView.indexPathsForVisibleSupplementaryElements(ofKind: TimelineTailView.supplementaryKind)
        if previousRect.origin.x - timelineRect.origin.x < -timelineMaxX + timelineClipView.frame.width {
            for visibleIndex in indexPaths {
                timelineCollectionView.item(at: visibleIndex)?.view.frame.origin.x += CGFloat(source.years.count * timelineType.sectionWidth)
            }
            for visibleTailIndex in tailIndexPaths {
                timelineCollectionView.supplementaryView(forElementKind: TimelineTailView.supplementaryKind, at: visibleTailIndex)?.frame.origin.x += CGFloat(source.years.count * timelineType.sectionWidth)
            }
        } else if previousRect.origin.x - timelineRect.origin.x > timelineMaxX - timelineClipView.frame.width {
            for visibleIndex in indexPaths {
                timelineCollectionView.item(at: visibleIndex)?.view.frame.origin.x -= CGFloat(source.years.count * timelineType.sectionWidth)
            }
            for visibleTailIndex in tailIndexPaths {
                timelineCollectionView.supplementaryView(forElementKind: TimelineTailView.supplementaryKind, at: visibleTailIndex)?.frame.origin.x -= CGFloat(source.years.count * timelineType.sectionWidth)
            }
        }
    }

    private func decadeFor(year: Int) -> Int {
        return year / 10 * 10
    }

    private func collectionView(for type: TimelineType) -> NSCollectionView? {
        switch type {
        case .month:
            return monthCollectionView
        case .year:
            return yearCollectionView
        case .decade:
            return decadeCollectionView
        case .century:
            return nil
        }
    }

    private func postRecordNotification(for type: RecordType, with id: Int, at position: CGPoint) {
        guard let window = view.window else {
            return
        }

        let location = window.frame.origin + position
        let info: JSON = [Keys.appID: appID, Keys.id: id, Keys.position: location.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(RecordNotification.with(type).name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func createRecords() {
        // Schools
        let schoolChain = firstly {
            try CachingNetwork.getSchools()
        }.catch { error in
            print(error)
        }

        // Events
        let eventChain = firstly {
            try CachingNetwork.getEvents()
        }.catch { error in
            print(error)
        }

        when(fulfilled: schoolChain, eventChain).then { [weak self] results in
            self?.loadNetworkResults(results)
        }
    }

    private func loadNetworkResults(_ results: (schools: [School], events: [Event])) {
        var records = [Record]()
        records.append(contentsOf: results.schools)
        records.append(contentsOf: results.events)
        source.setup(with: records)
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
