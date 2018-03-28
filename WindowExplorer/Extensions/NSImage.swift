//  Copyright © 2018 JABT. All rights reserved.

import AppKit

extension NSImage {

    convenience init?(named name: String) {
        self.init(named: NSImage.Name(rawValue: name))
    }

    func tinted(with tint: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else {
            return self
        }
        tinted.lockFocus()
        tint.set()

        let imageRect = NSRect(origin: .zero, size: size)
        imageRect.fill(using: .sourceAtop)

        tinted.unlockFocus()
        return tinted
    }
}
