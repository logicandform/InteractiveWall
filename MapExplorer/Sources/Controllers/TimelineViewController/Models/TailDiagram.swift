//  Copyright © 2018 JABT. All rights reserved.

import Foundation


// A diagram used to plot the lines representing the durations of TimelineEvents.
final class TailDiagram {

    private var layers = [Layer]()


    // MARK: API

    /// Adds the given line to the first available layer.
    func add(_ line: Line) {
        for layer in layers {
            if layer.fits(line) {
                layer.lines.append(line)
                wrapLines()
                return
            }
        }

        // Add a new layer to fit line
        let layer = Layer(lines: [line])
        layers.append(layer)
        wrapLines()
    }

    func addMarkers(for event: TimelineEvent, start: CGFloat, end: CGFloat) {
        for layer in layers {
            if layer.lines.contains(where: { $0.start == start && $0.event == event }) {
                let marker = Marker(event: event, x: start)
                layer.markers.append(marker)
            }
            if layer.lines.contains(where: { $0.end == end && $0.event == event }) {
                let marker = Marker(event: event, x: end)
                layer.markers.append(marker)
            }
        }
    }

    /// Returns the maximum height for the section of the diagram between the given points
    func height(of layers: [Layer]) -> CGFloat {
        let baseHeight = style.timelineTailMargin
        let heightOfLayers = CGFloat(layers.count) * (style.timelineTailWidth + style.timelineTailMargin)

        return baseHeight + heightOfLayers
    }

    /// Returns an array of layers transposed from the given area
    func layersBetween(a: CGFloat, b: CGFloat) -> [Layer] {
        let area = Line(event: nil, start: a, end: b)
        var result = [Layer]()

        // Create layers with properties transposed to the given area
        for layer in layers {
            let newLayer = Layer()
            // Transpose all lines
            for line in layer.lines {
                if line.overlaps(area) {
                    let start = max(line.start - a, 0)
                    let end = min(line.end - a, area.width)
                    let newLine = Line(event: line.event, start: start, end: end)
                    newLayer.lines.append(newLine)
                }
            }
            // Transpose all drops
            for drop in layer.drops {
                if area.overlaps(x: drop.x) {
                    let x = clamp(drop.x - a, min: 0, max: area.width)
                    let transposedDrop = Drop(event: drop.event, x: x)
                    newLayer.drops.append(transposedDrop)
                }
            }
            // Transpose all markers
            for marker in layer.markers {
                if area.overlaps(x: marker.x) {
                    let x = clamp(marker.x - a, min: 0, max: area.width)
                    let transposedMarker = Marker(event: marker.event, x: x)
                    newLayer.markers.append(transposedMarker)
                }
            }
            if newLayer.isEmpty {
                break
            }
            result.append(newLayer)
        }

        return result
    }

    func reset() {
        layers.removeAll()
    }


    // MARK: Helpers

    private func wrapLines() {
        for index in (1 ..< layers.count) {
            let previousLayer = layers[index - 1]
            let currentLayer = layers[index]
            let dropPoint = previousLayer.end + style.timelineTailGap

            if let lastLine = currentLayer.lines.last {
                if lastLine.overlaps(x: dropPoint) {
                    let tail = Line(event: lastLine.event, start: dropPoint, end: lastLine.end)
                    let drop = Drop(event: lastLine.event, x: dropPoint)
                    lastLine.end = dropPoint
                    currentLayer.drops.append(drop)
                    previousLayer.lines.append(tail)
                    wrapLines()
                    return
                } else if lastLine.start > dropPoint {
                    let tail = Line(event: lastLine.event, start: lastLine.start, end: lastLine.end)
                    let drop = Drop(event: lastLine.event, x: lastLine.start)
                    lastLine.end = lastLine.start
                    currentLayer.drops.append(drop)
                    previousLayer.lines.append(tail)
                    wrapLines()
                    return
                }
            }
        }
    }
}


/// Represents a vertical level within a TailDiagram. Holds both horizontal and vertical lines.
final class Layer {

    // Horizontal lines
    var lines = [Line]()

    // Vertical lines
    var drops = [Drop]()

    // Circle markers
    var markers = [Marker]()

    var end: CGFloat {
        return lines.last?.end ?? 0
    }

    var isEmpty: Bool {
        return lines.isEmpty && drops.isEmpty && markers.isEmpty
    }


    // MARK: Init

    init() { }

    init(lines: [Line]) {
        self.lines = lines
    }


    // MARK: API

    /// Determines if there is room to fit the given line
    func fits(_ line: Line) -> Bool {
        guard let last = lines.last else {
            return true
        }

        let availableStart = last.end + style.timelineTailGap
        return availableStart <= line.start
    }
}

/// Represents a single horizontal line within a single Layer of a TailDiagram
final class Line {

    var event: TimelineEvent!
    var start: CGFloat
    var end: CGFloat

    var width: CGFloat {
        return end - start
    }


    // MARK: Init

    init(event: TimelineEvent?, start: CGFloat, end: CGFloat) {
        self.event = event
        self.start = start
        self.end = end
    }


    // MARK: API

    func overlaps(x: CGFloat) -> Bool {
        return start <= x && x <= end
    }

    func overlaps(_ line: Line) -> Bool {
        return start <= line.start && end >= line.start || start <= line.end && end >= line.end || start >= line.start && end <= line.end
    }
}

/// Represents a single vertical drop line of a TailDiagram
final class Drop {
    var event: TimelineEvent
    var x: CGFloat

    init(event: TimelineEvent, x: CGFloat) {
        self.event = event
        self.x = x
    }
}

/// Represents a position where a Tail begins or ends
final class Marker {
    var event: TimelineEvent
    var x: CGFloat

    init(event: TimelineEvent, x: CGFloat) {
        self.event = event
        self.x = x
    }
}
