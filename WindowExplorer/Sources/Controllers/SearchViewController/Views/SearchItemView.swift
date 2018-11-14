//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class SearchItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SearchItemView")

    @IBOutlet private weak var titleTextField: NSTextField!
    @IBOutlet private weak var attributionTextField: NSTextField!
    @IBOutlet private weak var spinner: NSProgressIndicator!

    var tintColor = style.menuTintColor
    private var defaultBorders = [CALayer]()
    private var highlightBorders = [CALayer]()

    var type: RecordType? {
        didSet {
            tintColor = type?.color ?? style.menuTintColor
        }
    }

    var item: SearchItemDisplayable! {
        didSet {
            apply(item)
        }
    }

    private struct Constants {
        static let animationDuration = 0.2
        static let textColor = NSColor.white
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    func setupBorders(index: Int) {
        removeBorders()
        let borderThickness = style.windowHighlightWidth + style.defaultBorderWidth
        let topThickness = index.isZero ? borderThickness : borderThickness - style.defaultBorderWidth
        highlightBorders.append(view.addBorder(for: .top, thickness: topThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .left, thickness: borderThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .bottom, thickness: borderThickness, zPosition: style.windowHighlightZPosition))
        highlightBorders.append(view.addBorder(for: .right, thickness: borderThickness, zPosition: style.windowHighlightZPosition))
        defaultBorders.append(view.addBorder(for: .left))
        defaultBorders.append(view.addBorder(for: .right))
        defaultBorders.append(view.addBorder(for: .bottom))
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        for border in highlightBorders {
            border.backgroundColor = tintColor.cgColor
            border.isHidden = !highlighted
        }
    }

    func set(loading: Bool) {
        if loading {
            spinner.startAnimation(nil)
        } else {
            spinner.stopAnimation(nil)
        }

        titleTextField.textColor = loading ? style.defaultBorderColor : Constants.textColor
        attributionTextField.textColor = loading ? style.defaultBorderColor : Constants.textColor
        spinner.isHidden = !loading
    }


    // MARK: Setup

    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = style.darkBackground.cgColor
        titleTextField.textColor = Constants.textColor
        attributionTextField.textColor = Constants.textColor
    }


    // MARK: Helpers

    private func apply(_ item: SearchItemDisplayable?) {
        titleTextField.stringValue = item?.title ?? ""
        attributionTextField.stringValue = ""

        if let recordType = item as? RecordType {
            type = recordType
        }

        if let group = item as? LetterGroup, let type = type {
            SearchHelper.count(for: type, group: group) { [weak self] count in
                if let count = count {
                    self?.attributionTextField.stringValue = "\(count)"
                }
            }
        }

        if let province = item as? Province {
            let count = GeocodeHelper.instance.schools(for: province).count
            attributionTextField.stringValue = "\(count)"
        }
    }

    private func removeBorders() {
        let borders = defaultBorders + highlightBorders
        defaultBorders.removeAll()
        highlightBorders.removeAll()

        for border in borders {
            border.removeFromSuperlayer()
        }
    }
}
