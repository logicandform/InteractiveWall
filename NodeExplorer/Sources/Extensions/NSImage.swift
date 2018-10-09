//  Copyright © 2018 JABT. All rights reserved.

import AppKit

extension NSImage {

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

    /// Resizes image while retaining image ratio.
    func resizeImage(maxSize: NSSize) -> NSImage {
        var ratio: CGFloat = 0.0
        if self.size.width > self.size.height {
            ratio = maxSize.width / self.size.width
        } else {
            ratio = maxSize.height / self.size.height
        }

        // Calculate new size based on the ratio
        let newSize = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)

        let img = NSImage(size: newSize)
        img.lockFocus()
        let ctx = NSGraphicsContext.current
        ctx?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1)
        img.unlockFocus()

        return img
    }

}
