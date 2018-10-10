//
//  SwitchControl.swift
//  FCComponents Framework
//
//  Created by Alejandro Barros Cuetos on 03/07/14.
//  Copyright (c) 2014 Alejandro Barros Cuetos. All rights reserved.
//

import Foundation
import Cocoa
import QuartzCore


@IBDesignable
public class SwitchControl: NSButton {

    let kDefaultTintColor = style.unselectedRecordIcon
    let kBorderWidth: CGFloat = 1.0
    let kGoldenRatio: CGFloat = 1.61803398875
    let kDecreasedGoldenRatio: CGFloat = 1.38
    let disabledBorderColor = NSColor(calibratedWhite: 0, alpha: 0.2)
    let kAnimationDuration = 0.4
    let kEnabledOpacity: CFloat = 0.8
    let kDisabledOpacity: CFloat = 0.5

    @IBInspectable var isOn: Bool {
        didSet {
            self.refreshLayer()
        }
    }
    @IBInspectable var knobBackgroundColor: NSColor = .white {
        didSet {
            self.refreshLayer()
        }
    }
    @IBInspectable var disabledKnobBackgroundColor: NSColor = .white {
        didSet {
            self.refreshLayer()
        }
    }
    @IBInspectable var tintColor: NSColor = .blue {
        didSet {
            self.refreshLayer()
        }
    }
    @IBInspectable var disabledBackgroundColor: NSColor = .black {
        didSet {
            self.refreshLayer()
        }
    }

    var isActive: Bool = false
    var hasDragged: Bool = false
    var isDragginToOn: Bool = false
    var rootLayer: CALayer = CALayer()
    var backgroundLayer: CALayer = CALayer()
    var knobLayer: CALayer = CALayer()
    var knobInsideLayer: CALayer = CALayer()

    override public var frame: NSRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            self.refreshLayerSize()
        }
    }

    override public var acceptsFirstResponder: Bool { return true }

    override public var isEnabled: Bool {
        get { return super.isEnabled }
        set {
            super.isEnabled = newValue
            self.refreshLayer()
        }
    }

    // MARK: Initializers
    init(isOn: Bool, frame: NSRect) {
        self.isOn = isOn
        super.init(frame: frame)
        self.setupLayers()
    }

    required public init?(coder: NSCoder) {
        self.isOn = false
        self.tintColor = kDefaultTintColor

        super.init(coder: coder)
    }

    convenience override init(frame frameRect: NSRect) {
        self.init(isOn: false, frame: frameRect)
    }

    // MARK: Setup
    func setupLayers() {
        layer = rootLayer
        wantsLayer = true

        backgroundLayer.bounds = rootLayer.bounds
        backgroundLayer.anchorPoint = CGPoint(x: 0, y: 0)
        backgroundLayer.borderWidth = kBorderWidth

        rootLayer.addSublayer(backgroundLayer)

        knobLayer.frame = rectForKnob()
        knobLayer.autoresizingMask = CAAutoresizingMask.layerHeightSizable
        knobLayer.backgroundColor = knobBackgroundColor.cgColor
        knobLayer.shadowColor = knobBackgroundColor.cgColor
        knobLayer.shadowOffset = CGSize(width: 0, height: -2)
        knobLayer.shadowRadius = 1
        knobLayer.shadowOpacity = 0.3

        rootLayer.addSublayer(knobLayer)

        knobInsideLayer.frame = knobLayer.bounds
        knobInsideLayer.backgroundColor = knobBackgroundColor.cgColor
        knobInsideLayer.shadowColor = knobBackgroundColor.cgColor
        knobInsideLayer.shadowOffset = CGSize(width: 0, height: 0)
        knobInsideLayer.shadowRadius = 1
        knobInsideLayer.shadowOpacity = 0.35

        knobLayer.addSublayer(knobInsideLayer)

        refreshLayerSize()
        refreshLayer()
    }

    func rectForKnob() -> CGRect {
        let height = knobHeightForSize(size: backgroundLayer.bounds.size)
        let width = knobHeightForSize(size: backgroundLayer.bounds.size)

        let x = ((!hasDragged && !isOn) || (hasDragged && !isDragginToOn)) ? kBorderWidth : backgroundLayer.bounds.width - width - kBorderWidth

        return CGRect(x: x, y: kBorderWidth, width: width, height: height)
    }

    func knobHeightForSize(size: NSSize) -> CGFloat {
        return size.height - kBorderWidth * 2
    }

    func refreshLayerSize() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        knobLayer.frame = rectForKnob()
        knobInsideLayer.frame = knobLayer.bounds

        backgroundLayer.cornerRadius = backgroundLayer.bounds.size.height / 2
        knobLayer.cornerRadius = knobLayer.bounds.size.height / 2
        knobInsideLayer.cornerRadius = knobLayer.bounds.size.height / 2

        CATransaction.commit()
    }

    func refreshLayer () {
        CATransaction.begin()
        CATransaction.setAnimationDuration(kAnimationDuration)

        if (hasDragged && isDragginToOn) || (!hasDragged && isOn) {
            backgroundLayer.borderColor = tintColor.cgColor
            backgroundLayer.backgroundColor = tintColor.cgColor
            knobLayer.backgroundColor = knobBackgroundColor.cgColor
            knobInsideLayer.backgroundColor = knobBackgroundColor.cgColor
        } else {
            backgroundLayer.borderColor = disabledBorderColor.cgColor
            backgroundLayer.backgroundColor = disabledBackgroundColor.cgColor
            knobLayer.backgroundColor = disabledKnobBackgroundColor.cgColor
            knobInsideLayer.backgroundColor = disabledKnobBackgroundColor.cgColor
        }

        if !isActive {
            rootLayer.opacity = kEnabledOpacity
        } else {
            rootLayer.opacity = kDisabledOpacity
        }

        if !hasDragged {
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.25, 1.5, 0.5, 1.0))
        }

        knobLayer.frame = rectForKnob()
        knobInsideLayer.frame = knobLayer.bounds

        CATransaction.commit()
    }
}
