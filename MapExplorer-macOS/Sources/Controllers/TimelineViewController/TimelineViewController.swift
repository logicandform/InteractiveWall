//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


enum TimelineType {
    case month
    case year
    case decade
    case century
}


class TimelineViewController: NSViewController, GestureResponder, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Timeline")

    @IBOutlet weak var timelineBackgroundView: NSView!
    @IBOutlet weak var timelineCollectionView: FlippedCollectionView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var monthCollectionView: NSCollectionView!
    @IBOutlet weak var monthScrollView: NSScrollView!
    @IBOutlet weak var yearCollectionView: NSCollectionView!
    @IBOutlet weak var yearScrollView: NSScrollView!
    @IBOutlet weak var decadeCollectionView: NSCollectionView!
    @IBOutlet weak var decadeScrollView: NSScrollView!
    @IBOutlet weak var timelineIndicatorView: NSView!

    var gestureManager: GestureManager!
    private var timelineHandler: TimelineHandler?
    private let source = TimelineDataSource()
    private var timelineType = TimelineType.century
    private var decades = [Int]()
    private var years = [Int]()
    private var selectedDecade: Int?
    private var selectedYear: Int?
    private var selectedMonth: Month?
    private var selectedViewForType = [TimelineType: TimelineControlItemView]()

    private struct Constants {
        static let timelineCellWidth: CGFloat = 20
        static let timelineSelectedCellWidth: CGFloat = 150
        static let animationDuration = 0.5
        static let controlItemWidth: CGFloat = 70
        static let firstDecade = 1860
        static let lastDecade = 1980
        static let timelineControlWidth: CGFloat = 490
        static let visibleControlItems = 7
        static let timelineIndicatorBorderRadius: CGFloat = 8
        static let timelineIndicatorBorderWidth: CGFloat = 2
    }

    private struct Keys {
        static let id = "id"
        static let type = "type"
        static let group = "group"
        static let index = "index"
        static let state = "state"
        static let selection = "selection"
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


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        TouchManager.instance.register(gestureManager, for: .timeline)

        setupBackground()
        setupTimeline()
        setupControls()
        setupGestures()
        setupNotifications()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setDate(day: 0, month: .january, year: 1880)
    }


    // MARK: Setup

    private func setupBackground() {
        timelineBackgroundView.alphaValue = 0
        timelineBackgroundView.wantsLayer = true
        timelineBackgroundView.layer?.backgroundColor = style.timelineBackgroundColor.cgColor
    }

    private func setupTimeline() {
        timelineHandler = TimelineHandler(timeline: timelineCollectionView)
        ConnectionManager.instance.timelineHandler = timelineHandler
        ConnectionManager.instance.timelineViewController = self
        timelineCollectionView.register(TimelineItemView.self, forItemWithIdentifier: TimelineItemView.identifier)
        timelineCollectionView.register(NSNib(nibNamed: TimelineHeaderView.nibName, bundle: .main), forSupplementaryViewOfKind: TimelineHeaderView.supplementaryKind, withIdentifier: TimelineHeaderView.identifier)
        timelineCollectionView.dataSource = source
        timelineScrollView.horizontalScroller?.alphaValue = 0
    }

    private func setupControls() {
        years = Array(Constants.firstDecade...Constants.lastDecade)
        decades = years.filter { $0 % 10 == 0 }
        monthCollectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        yearCollectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        decadeCollectionView.register(TimelineControlItemView.self, forItemWithIdentifier: TimelineControlItemView.identifier)
        monthScrollView.horizontalScroller?.alphaValue = 0
        yearScrollView.horizontalScroller?.alphaValue = 0
        decadeScrollView.horizontalScroller?.alphaValue = 0
        timelineIndicatorView.wantsLayer = true
        timelineIndicatorView.layer?.cornerRadius = Constants.timelineIndicatorBorderRadius
        timelineIndicatorView.layer?.borderWidth = Constants.timelineIndicatorBorderWidth
        timelineIndicatorView.layer?.borderColor = style.selectedColor.cgColor
    }

    private func setupGestures() {
        let timelinePanGesture = PanGestureRecognizer()
        gestureManager.add(timelinePanGesture, to: timelineCollectionView)
        timelinePanGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnTimeline(gesture)
        }

        let timelineTapGesture = TapGestureRecognizer()
        gestureManager.add(timelineTapGesture, to: timelineCollectionView)
        timelineTapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnTimeline(gesture)
        }

        addGestures(to: monthCollectionView)
        addGestures(to: yearCollectionView)
        addGestures(to: decadeCollectionView)
    }

    private func addGestures(to collectionView: NSCollectionView) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: collectionView)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.didTapOnControl(gesture)
        }

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: collectionView)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.didPanOnControl(gesture)
        }
    }

    private func setupNotifications() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.transition.name, object: nil)
        for notification in TimelineNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
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
            let indexPath = timelineCollectionView.indexPathForItem(at: location + timelineCollectionView.visibleRect.origin) else {
                return
        }

        let state = source.selectedIndexes.contains(indexPath.item)
        postSelectNotification(for: indexPath.item, state: !state)
    }

    private func didTapOnControl(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended,
            let collectionView = gestureManager.view(for: gesture) as? NSCollectionView,
            canSelectItem(in: collectionView),
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let itemView = collectionView.item(at: indexPath) as? TimelineControlItemView,
            let title = itemView.title else {
                return
        }

        switch collectionView {
        case monthCollectionView:
            if let month = Month(abbreviation: title) {
                select(month: month, view: itemView)
            }
        case yearCollectionView:
            if let year = Int(title) {
                select(year: year, view: itemView)
            }
        case decadeCollectionView:
            if let decade = Int(title) {
                select(decade: decade, view: itemView)
            }
        default:
            return
        }
    }

    private func didPanOnControl(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: gesture) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            update(collectionView, with: pan.delta)
        default:
            return
        }
    }

    private lazy var positionForView: [NSView: CGFloat] = [monthCollectionView: 0, yearCollectionView: 0, decadeCollectionView: 0]

    private func update(_ collectionView: NSCollectionView, with offset: CGVector, cascading: Bool = true) {
        let maxX = collectionView.frame.width - Constants.timelineControlWidth
        var rect = collectionView.visibleRect
        var position = positionForView[collectionView]!
        position -= offset.dx
        if position > maxX {
            position -= maxX
        } else if position < 0 {
            position = maxX - position
        }
        positionForView[collectionView] = position
        rect.origin.x = position
        collectionView.scrollToVisible(rect)

        guard cascading else {
            return
        }

        switch collectionView {
        case monthCollectionView:
            update(yearCollectionView, with: offset / 12, cascading: false)
            update(decadeCollectionView, with: offset / 120, cascading: false)
        case yearCollectionView:
            update(monthCollectionView, with: offset * 12, cascading: false)
            update(decadeCollectionView, with: offset / 10, cascading: false)
        case decadeCollectionView:
            update(monthCollectionView, with: offset * 120, cascading: false)
            update(yearCollectionView, with: offset * 10, cascading: false)
        default:
            return
        }
    }


    // MARK: Notification Handling

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        switch notification.name {
        case TimelineNotification.selection.name:
            if let selection = info[Keys.selection] as? [Int] {
                setTimelineSelection(Set(selection))
            }
        case TimelineNotification.select.name:
            if let index = info[Keys.index] as? Int, let state = info[Keys.state] as? Bool {
                setTimelineItem(index, selected: state)
            }
        default:
            return
        }
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case monthCollectionView:
            return Month.allValues.count + Constants.visibleControlItems
        case yearCollectionView:
            return years.count + Constants.visibleControlItems
        case decadeCollectionView:
            return decades.count + Constants.visibleControlItems
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        switch collectionView {
        case monthCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let month = Month.allValues.at(index: indexPath.item % Month.allValues.count)
                controlItemView.title = month?.abbreviation
                if let selectedMonth = selectedMonth {
                    controlItemView.set(highlighted: selectedMonth == month)
                }
                return controlItemView
            }
        case yearCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let year = years.at(index: indexPath.item % years.count)
                controlItemView.title = year?.description
                if let selectedYear = selectedYear {
                    controlItemView.set(highlighted: selectedYear == year)
                }
                return controlItemView
            }
        case decadeCollectionView:
            if let controlItemView = collectionView.makeItem(withIdentifier: TimelineControlItemView.identifier, for: indexPath) as? TimelineControlItemView {
                let decade = decades.at(index: indexPath.item % decades.count)
                controlItemView.title = decade?.description
                if let selectedDecade = selectedDecade {
                    controlItemView.set(highlighted: selectedDecade == decade)
                }
                return controlItemView
            }
        default:
            break
        }

        return NSCollectionViewItem()
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let height = collectionView.superview!.frame.size.height
        return CGSize(width: Constants.controlItemWidth, height: height)
    }


    // MARK: Control Selection

    private func canSelectItem(in collectionView: NSCollectionView) -> Bool {
        switch collectionView {
        case monthCollectionView:
            return selectedDecade != nil && selectedYear != nil
        case yearCollectionView:
            return selectedDecade != nil
        default:
            return true
        }
    }

    private func select(month: Month, view: TimelineControlItemView) {
        if month == selectedMonth {
            removeSelection(for: .month)
            transition(to: .year)
            return
        }

        selectedMonth = month
        transition(to: .month)
        selectedViewForType[.month]?.set(highlighted: false)
        selectedViewForType[.month] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func select(year: Int, view: TimelineControlItemView) {
        if year == selectedYear {
            removeSelection(for: .year)
            transition(to: .decade)
            return
        }

        removeSelection(for: .month)
        selectedYear = year
        transition(to: .year)
        selectedViewForType[.year]?.set(highlighted: false)
        selectedViewForType[.year] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func select(decade: Int, view: TimelineControlItemView) {
        if decade == selectedDecade {
            removeSelection(for: .decade)
            transition(to: .century)
            return
        }

        removeSelection(for: .year)
        selectedDecade = decade
        transition(to: .decade)
        selectedViewForType[.decade]?.set(highlighted: false)
        selectedViewForType[.decade] = view
        view.set(highlighted: true)
        // scroll the timeline
    }

    private func removeSelection(for type: TimelineType) {
        // Unhighlight items for type
        let visibleItems = collectionView(for: type)?.visibleItems() ?? []
        for item in visibleItems {
            if let controlItem = item as? TimelineControlItemView {
                controlItem.set(highlighted: false)
            }
        }

        switch type {
        case .month:
            selectedMonth = nil
        case .year:
            removeSelection(for: .month)
            selectedYear = nil
        case .decade:
            removeSelection(for: .year)
            selectedDecade = nil
        case .century:
            removeSelection(for: .decade)
        }
    }

    private func transition(to type: TimelineType) {
        // update the layout and data source for the timeline
//        switch type {
//        case .month:
//            monthCollectionView.reloadData()
//        case .year:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//        case .decade:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//            decadeCollectionView.reloadData()
//        case .century:
//            monthCollectionView.reloadData()
//            yearCollectionView.reloadData()
//            decadeCollectionView.reloadData()
//        }
    }


    // MARK: Timeline Selection

    private func postSelectNotification(for index: Int, state: Bool) {
        var info: JSON = [Keys.id: appID, Keys.index: index, Keys.state: state]
        if let group = ConnectionManager.instance.groupForApp(id: appID, type: .timeline) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.select.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func setTimelineSelection(_ selection: Set<Int>) {
        // Unselect current indexes that are not in the new selection
        source.selectedIndexes.subtracting(selection).forEach { index in
            setTimelineItem(index, selected: false)
        }
        // Select indexes that are not currently selected
        selection.subtracting(source.selectedIndexes).forEach { index in
            setTimelineItem(index, selected: true)
        }
    }

    private func setTimelineItem(_ index: Int, selected: Bool) {
        if selected {
            source.selectedIndexes.insert(index)
        } else {
            source.selectedIndexes.remove(index)
        }

        // Update item view for index
        let indexPath = IndexPath(item: index, section: 0)
        if let timelineItem = timelineCollectionView.item(at: indexPath) as? TimelineItemView, let attributes = timelineCollectionView.collectionViewLayout?.layoutAttributesForItem(at: indexPath) {
            timelineItem.view.layer?.zPosition = CGFloat(attributes.zIndex)
            timelineItem.animate(to: attributes.size)
        }
    }

    private func controlMonth() -> Month {
        let currentX = monthCollectionView.visibleRect.origin.x + Constants.timelineControlWidth / 2
        let maxX = CGFloat(Month.allValues.count) * Constants.controlItemWidth
        let x = currentX.truncatingRemainder(dividingBy: maxX)
        let index = Int(x / Constants.controlItemWidth)
        return Month.allValues[index]
    }

    private func controlYear() -> Int {
        let currentX = yearCollectionView.visibleRect.origin.x + Constants.timelineControlWidth / 2
        let maxX = CGFloat(years.count) * Constants.controlItemWidth
        let x = currentX.truncatingRemainder(dividingBy: maxX)
        let index = Int(x / Constants.controlItemWidth)
        return years[index]
    }

    private func controlDecade() -> Int {
        let currentX = decadeCollectionView.visibleRect.origin.x + Constants.timelineControlWidth / 2
        let maxX = CGFloat(decades.count) * Constants.controlItemWidth
        let x = currentX.truncatingRemainder(dividingBy: maxX)
        let index = Int(x / Constants.controlItemWidth)
        return decades[index]
    }


    // MARK: Helpers

    private func setDate(day: Int, month: Month, year: Int) {
        let centerInset = Constants.controlItemWidth * 3

        let monthMaxX = CGFloat(Month.allValues.count) * Constants.controlItemWidth
        let monthIndex = Month.allValues.index(of: month)!
        let monthX = CGFloat(monthIndex) * Constants.controlItemWidth
        var monthRect = monthCollectionView.visibleRect
        monthRect.origin.x = monthX - centerInset
        if monthRect.origin.x < 0 {
            monthRect.origin.x = monthMaxX + monthRect.origin.x
        }
        positionForView[monthCollectionView] = monthRect.origin.x
        monthCollectionView.scrollToVisible(monthRect)

        let monthOffset = (CGFloat(monthIndex) / 12 - 0.5) * Constants.controlItemWidth
        let yearMaxX = CGFloat(years.count) * Constants.controlItemWidth
        let yearIndex = years.index(of: year)!
        let yearX = CGFloat(yearIndex) * Constants.controlItemWidth
        var yearRect = yearCollectionView.visibleRect
        yearRect.origin.x = yearX - centerInset + monthOffset
        if yearRect.origin.x < 0 {
            yearRect.origin.x = yearMaxX + yearRect.origin.x
        }
        positionForView[yearCollectionView] = yearRect.origin.x
        yearCollectionView.scrollToVisible(yearRect)

        let yearOffset = (CGFloat(year.array.last!) / 10 - 0.5) * Constants.controlItemWidth
        let decade = decadeFor(year: year)
        let decadeMaxX = CGFloat(decades.count) * Constants.controlItemWidth
        let decadeIndex = decades.index(of: decade)!
        let decadeX = CGFloat(decadeIndex) * Constants.controlItemWidth
        var decadeRect = decadeCollectionView.visibleRect
        decadeRect.origin.x = decadeX - centerInset + yearOffset
        if decadeRect.origin.x < 0 {
            decadeRect.origin.x = decadeMaxX + decadeRect.origin.x
        }
        positionForView[decadeCollectionView] = decadeRect.origin.x
        decadeCollectionView.scrollToVisible(decadeRect)
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
}
