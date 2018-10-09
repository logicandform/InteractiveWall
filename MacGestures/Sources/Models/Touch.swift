//  Copyright © 2018 JABT. All rights reserved.

import Foundation


public enum TouchState: Int {
    case down
    case up
    case moved
}


public class Touch: Hashable, CustomStringConvertible {

    public var position: CGPoint
    public var state: TouchState
    public let screen: Int
    public let id: Int

    public var hashValue: Int {
        return id ^ screen
    }

    public var description: String {
        return "( [Touch] ID: \(id), Position: \(position), State: \(state) )"
    }


    // MARK: Initializers

    public init(position: CGPoint, state: TouchState, id: Int, screen: Int) {
        self.position = position
        self.state = state
        self.screen = screen
        self.id = id
    }


    // MARK: API

    // Updates the values of `self` if the touches are equal
    public func update(with touch: Touch) {
        if self == touch {
            self.position = touch.position
            self.state = touch.state
        }
    }

    public func copy() -> Touch {
        return Touch(position: position, state: state, id: id, screen: screen)
    }

    public static func == (lhs: Touch, rhs: Touch) -> Bool {
        return lhs.id == rhs.id && lhs.screen == rhs.screen
    }
}
