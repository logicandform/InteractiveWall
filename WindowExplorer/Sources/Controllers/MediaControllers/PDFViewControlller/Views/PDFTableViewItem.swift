//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import Quartz

class PDFTableViewItem: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "PDFTableViewItem")
    static let nibName = NSNib.Name(rawValue: "PDFTableViewItem")
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var textField: NSTextField!

    var tintColor = style.selectedColor
    var page: PDFPage? {
        didSet {
            load(page)
        }
    }
    
    
    // MARK: Init
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        set(highlighted: false)
    }
    
    
    // MARK: API
    
    func set(highlighted: Bool) {
        if highlighted {
            layer?.backgroundColor = tintColor.cgColor
            textField.textColor = style.darkBackground
        } else {
            layer?.backgroundColor = style.clear.cgColor
            textField.textColor = .white
        }
    }
    
    
    // MARK: Helpers
    
    private func load(_ page: PDFPage?) {
        guard let page = page else {
            return
        }
        
        imageView.image = page.thumbnail(of: imageView.frame.size, for: .mediaBox)
        if let pageNumber = page.pageRef?.pageNumber {
            textField.stringValue = String(pageNumber)
        } else {
            textField.stringValue = ""
        }
    }
}

