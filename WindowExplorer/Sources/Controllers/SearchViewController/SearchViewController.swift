//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class SearchViewController: BaseViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    static let storyboard = NSStoryboard.Name(rawValue: "Search")

    @IBOutlet weak var primaryCollectionView: NSCollectionView!
    @IBOutlet weak var secondaryCollectionView: NSCollectionView!
    @IBOutlet weak var tertiaryCollectionView: NSCollectionView!
    @IBOutlet weak var quaternaryCollectionView: NSCollectionView!

    private var currentType: RecordType?
    private var selectedItemForView = [NSCollectionView: SearchItemView]()
    private lazy var collectionViews: [NSCollectionView] = [primaryCollectionView, secondaryCollectionView, tertiaryCollectionView, quaternaryCollectionView]

    private struct Constants {
        static let animationDuration = 0.5
        static let searchItemHeight: CGFloat = 70
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedStringValue = NSAttributedString(string: titleLabel.stringValue, attributes: style.windowTitleAttributes)

        setupGestures()
        resetCloseWindowTimer()
        animateViewIn()
    }


    // MARK: Setup

    private func setupGestures() {
        collectionViews.compactMap{$0}.forEach { collectionView in
            let collectionViewPan = PanGestureRecognizer()
            gestureManager.add(collectionViewPan, to: collectionView)
            collectionViewPan.gestureUpdated = handleCollectionViewPan(_:)

            let collectionViewTap = TapGestureRecognizer()
            gestureManager.add(collectionViewTap, to: collectionView)
            collectionViewTap.gestureUpdated = handleCollectionViewTap(_:)
        }
    }


    // MARK: GestureHandling

    private func handleCollectionViewPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let collectionView = gestureManager.view(for: pan) as? NSCollectionView else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var rect = collectionView.visibleRect
            rect.origin.y += pan.delta.dy
            collectionView.scrollToVisible(rect)
        default:
            return
        }
    }

    private func handleCollectionViewTap(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer,
            let collectionView = gestureManager.view(for: tap) as? NSCollectionView,
            let location = tap.position,
            let indexPath = collectionView.indexPathForItem(at: location + collectionView.visibleRect.origin),
            let searchItem = collectionView.item(at: indexPath) as? SearchItemView else {
            return
        }

        switch tap.state {
        case .began:
            selectedItemForView[collectionView]?.set(highlighted: false)
            selectedItemForView[collectionView] = searchItem
            selectedItemForView[collectionView]?.set(highlighted: true)
        case .failed:
            selectedItemForView[collectionView]?.set(highlighted: false)
        case .ended:
            select(searchItem, index: indexPath.item, in: collectionView)
        default:
            return
        }
    }

    private func toggleWindowSize() {
        guard let window = view.window else {
            return
        }

        var frame = window.frame
        frame.size.width += 350
        window.setFrame(frame, display: true, animate: true)
    }


    // MARK: NSCollectionViewDelegate & NSCollectionViewDataSource

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case primaryCollectionView:
             return RecordType.allValues.count
        case secondaryCollectionView:
            return 5
        case tertiaryCollectionView:
            return 7
        case quaternaryCollectionView:
            return 10
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let searchItemView = collectionView.makeItem(withIdentifier: SearchItemView.identifier, for: indexPath) as? SearchItemView else {
            return NSCollectionViewItem()
        }

        searchItemView.type = currentType

        switch collectionView {
        case primaryCollectionView:
            searchItemView.text = RecordType.allValues[indexPath.item].title
            searchItemView.type = RecordType.allValues[indexPath.item]
        case secondaryCollectionView:
            searchItemView.text = "2"
        case tertiaryCollectionView:
            searchItemView.text = "3"
        case quaternaryCollectionView:
            searchItemView.text = "4"
        default:
            break
        }

        return searchItemView
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.frame.size.width, height: Constants.searchItemHeight)
    }


    // MARK: Overrides

    override func animateViewIn() {
        primaryCollectionView.alphaValue = 0
        windowDragArea.alphaValue = 0
        secondaryCollectionView.alphaValue = 0
        tertiaryCollectionView.alphaValue = 0
        quaternaryCollectionView.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            primaryCollectionView.animator().alphaValue = 1
            windowDragArea.animator().alphaValue = 1
        })
    }

    override func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            if let strongSelf = self {
                WindowManager.instance.closeWindow(for: strongSelf)
            }
        })
    }


    // MARK: Helpers

    private func select(_ item: SearchItemView, index: Int, in collectionView: NSCollectionView) {
        switch collectionView {
        case primaryCollectionView:
            currentType = RecordType.allValues[index]
        case secondaryCollectionView:
            break
        case tertiaryCollectionView:
            break
        case quaternaryCollectionView:
            break
        default:
            break
        }

        if let index = collectionViews.index(of: collectionView) {
            toggle(to: index, completion: { [weak self] in
                self?.collectionViews.at(index: index + 1)?.reloadData()
                self?.toggle(to: index + 1)
            })
        }
    }

    private func toggle(to index: Int, completion: (() -> Void)? = nil) {
        guard let window = view.window, index < collectionViews.count else {
            return
        }

        // Unselect nested search items
        collectionViews.enumerated().forEach { indexOfView, collectionView in
            if indexOfView > index {
                selectedItemForView[collectionView]?.set(highlighted: false)
            }
        }

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
                self?.collectionViews.enumerated().forEach { indexOfView, collectionView in
                    collectionView.animator().alphaValue = indexOfView <= index ? 1 : 0
                }
            }, completionHandler: completion)

        var frame = window.frame
        frame.size.width = style.searchWindowSize.width * CGFloat(index + 1)
        window.setFrame(frame, display: true, animate: true)
    }
}
