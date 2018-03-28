//  Copyright © 2018 JABT. All rights reserved.

import AVFoundation
import MultiChannelPan

/// MultiChannelPanner
final class MultiChannelPanner {
    /// Four letter unique description of the node
    static let componentDescription = AudioComponentDescription(effect: "mpan")

    // MARK: - Properties

    var audioNode: AVAudioNode!
    private var internalAU: MultiChannelPanAudioUnit?
    private var token: AUParameterObserverToken?
    private var locationParameter: AUParameter?

    /// Location
    var location: Double = 0.5 {
        willSet {
            if location == newValue {
                return
            }

            if let token = token, let locationParameter = locationParameter {
                locationParameter.setValue(Float(newValue), originator: token)
            }
        }
    }

    // MARK: - Initialization

    /// Initialize this node
    init(location: Double = 0.5) {
        AUAudioUnit.registerSubclass(MultiChannelPanAudioUnit.self, as: MultiChannelPanner.componentDescription, name: "Local \(self)", version: UInt32.max)
        AVAudioUnit.instantiate(with: MultiChannelPanner.componentDescription, options: []) { avAudioUnit, _ in
            guard let avAudioUnit = avAudioUnit else {
                return
            }
            AudioController.shared.engine.attach(avAudioUnit)
            self.audioNode = avAudioUnit
            self.internalAU = avAudioUnit.auAudioUnit as? MultiChannelPanAudioUnit
        }

        guard let tree = internalAU?.parameterTree else {
            print("Parameter Tree Failed")
            return
        }

        self.locationParameter = tree["location"]
        self.token = tree.token(byAddingParameterObserver: { [weak self] _, _ in
            // Ignore, audio unit doesn't change any values
        })

        self.location = location
    }
}

/// Helper function to convert codes for Audio Units
/// - parameter string: Four character string to convert
public func fourCC(_ string: String) -> UInt32 {
    let utf8 = string.utf8
    precondition(utf8.count == 4, "Must be a 4 char string")
    var out: UInt32 = 0
    for char in utf8 {
        out <<= 8
        out |= UInt32(char)
    }
    return out
}

extension AUParameterTree {
    public subscript (key: String) -> AUParameter? {
        return value(forKey: key) as? AUParameter
    }
}
