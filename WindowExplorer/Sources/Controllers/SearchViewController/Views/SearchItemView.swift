//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class SearchItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("SearchItemView")

    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var attributionTextField: NSTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!

    var tintColor = style.selectedColor

    var type: RecordType? {
        didSet {
            tintColor = type?.color ?? style.selectedColor
        }
    }

    var item: SearchItemDisplayable! {
        didSet {
            apply(item)
        }
    }

    private struct Constants {
        static let animationDuration = 0.2
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        set(highlighted: false)
    }


    // MARK: API

    func set(highlighted: Bool) {
        if highlighted {
            view.layer?.backgroundColor = tintColor.cgColor
        } else {
            view.layer?.backgroundColor = style.darkBackground.cgColor
        }
    }

    func set(loading: Bool) {
        if loading {
            spinner.startAnimation(nil)
        } else {
            spinner.stopAnimation(nil)
        }

        titleTextField.isHidden = loading
        spinner.isHidden = !loading
    }


    // MARK: Helpers

    private func apply(_ item: SearchItemDisplayable?) {
        titleTextField.stringValue = item?.title ?? ""
        attributionTextField.stringValue = ""

        if let recordType = item as? RecordType {
            type = recordType
        }

        if let group = item as? LetterGroup, let type = type {
            RecordFactory.count(for: type, in: group) { [weak self] count in
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
}
