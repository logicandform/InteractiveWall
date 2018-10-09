//  MapAnimationType.swift

import Foundation

private struct Constants {
    static let clusterZoomAnimationDuration = 1.0
    static let doubleTapZoomAnimationDuration = 0.8
    static let resetAnimationDuration = 2.5
}

enum MapAnimationType {
    case doubleTap
    case clusterTap
    case reset

    var duration: Double {
        switch self {
        case .doubleTap:
            return Constants.doubleTapZoomAnimationDuration
        case .clusterTap:
            return Constants.clusterZoomAnimationDuration
        case .reset:
            return Constants.resetAnimationDuration
        }
    }

    var notification: MapNotification {
        switch self {
        case .doubleTap, .clusterTap:
            return .mapRect
        case .reset:
            return .reset
        }
    }
}
