//  Copyright © 2018 JABT. All rights reserved.

import Foundation

private struct Keys {
    static let id = "id"
    static let title = "title"
    static let description = "description"
    static let mediaTitles = "mediaTitles"
    static let media = "mediaPaths"
    static let localMedia = "fullMediaPaths"
    static let thumbnails = "thumbnailPaths"
    static let localThumbnails = "fullThumbnailPaths"
}

let featuresDescription =
"""
In addition to the basic interaction with the map, there are a few lovely and subtle things that you can do:

Animating Back To a Pin
If a pin has already been tapped, and its record is still visible, the record will animate *back* to the pin instead of creating a copy of the record.

Flicking Records
Its possible to flick a record away. You can send it to someone on another screen, or just get it out of your hair.

Flicking Off Screen
If a record is flicked off screen, or its header bar is no longer visible, then the record will be removed from the interface.

Labels
If the "show labels" option is on in the filter panel, then each annotation will reveal its label after the user has sufficiently zoomed.

Scrolling Across Edges
If a user scrolls the map so the country moves past the left or right edges, the map will reappear at the opposite edge of the screen.
"""

let featuresJSON: JSON = [
    Keys.id: -1,
    Keys.title: "Map Explorer Features",
    Keys.description: featuresDescription,
    Keys.mediaTitles: ["Map Explorer Features"],
    Keys.media: ["/static/mov/MapExplorerFeatures.mov"],
    Keys.localMedia: ["/Users/irshdc/dev/Caching-Server-UBC/static/mov/MapExplorerFeatures.mov"],
    Keys.thumbnails: ["/static/png/MapExplorerFeatures.png"],
    Keys.localThumbnails: ["/Users/irshdc/dev/Caching-Server-UBC/static/png/MapExplorerFeatures.png"]
]

let interactiveDescription =
"""
The map explorer presents a view of Canada with the locations of many Residential Schools (blue pins) and events (pink pins). Interacting with the map explorer is very similar to how you would use a map application on a mobile device, or on a desktop computer. There are 4 basic interactions you can do to explore the map:

Panning
You can pan the map by dragging one or more fingers across the screen.

Zooming
You can zoom in or out of the map by pinching the screen with two or more fingers.

Tapping
You can zoom into an area of the map by double-tapping the screen.

Selecting
You can select an annotation by tapping on it – this launches a record.
"""

let interactiveJSON: JSON = [
    Keys.id: -2,
    Keys.title: "Map Explorer Interaction",
    Keys.description: interactiveDescription,
    Keys.mediaTitles: ["Map Explorer Interaction"],
    Keys.media: ["/static/mov/MapExplorerInteraction.mov"],
    Keys.localMedia: ["/Users/irshdc/dev/Caching-Server-UBC/static/mov/MapExplorerInteraction.mov"],
    Keys.thumbnails: ["/static/png/MapExplorerInteraction.png"],
    Keys.localThumbnails: ["/Users/irshdc/dev/Caching-Server-UBC/static/png/MapExplorerInteraction.png"]
]

let featureRecord = Artifact(json: featuresJSON)
let interactiveRecord = Artifact(json: interactiveJSON)
