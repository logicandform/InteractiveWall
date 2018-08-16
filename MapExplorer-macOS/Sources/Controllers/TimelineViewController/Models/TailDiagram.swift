//  Copyright © 2018 JABT. All rights reserved.

import Foundation


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

    /// Returns the maximum height for the section of the diagram between the given points
    func heightBetween(a: CGFloat, b: CGFloat) -> CGFloat {
        let line = Line(start: a, end: b)
        for (index, layer) in layers.reversed().enumerated() {
            let level = layers.count - index
            if layer.lines.contains(where: { $0.overlaps(line) }) {
                return CGFloat(level) * style.timelineInterTailMargin
            }
        }

        return style.timelineTailGap
    }

    /// Returns an array of layers transposed into the given area
    func layersBetween(a: CGFloat, b: CGFloat) -> [Layer] {
        let area = Line(start: a, end: b)

        var result = [Layer]()
        for layer in layers {
            let newLayer = Layer()

            for line in layer.lines {
                if line.overlaps(area) {
                    let start = max(line.start - a, 0)
                    let end = min(line.end - a, area.width)
                    let newLine = Line(start: start, end: end)
                    newLayer.lines.append(newLine)
                }
            }
            for drop in layer.drops {
                if area.overlaps(x: drop.x) {
                    let x = clamp(drop.x - a, min: 0, max: area.width)
                    let transposedDrop = Drop(x: x)
                    newLayer.drops.append(transposedDrop)
                }
            }
            if newLayer.lines.isEmpty {
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
            if let lastLine = currentLayer.lines.last, lastLine.overlaps(x: dropPoint) {
                let tail = Line(start: dropPoint, end: lastLine.end)
                let drop = Drop(x: dropPoint)
                lastLine.end = dropPoint
                currentLayer.drops.append(drop)
                previousLayer.lines.append(tail)
                wrapLines()
                return
            }
        }
    }
}


/// Represents a vertical level within a TailDiagram
final class Layer {

    // Horizontal lines
    var lines = [Line]()

    // Vertical lines
    var drops = [Drop]()

    var end: CGFloat {
        return lines.last?.end ?? 0
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

/// Represents a single connected line within a single Layer of a TailDiagram
final class Line {

    var start: CGFloat
    var end: CGFloat

    var width: CGFloat {
        return end - start
    }


    // MARK: Init

    init(start: CGFloat, end: CGFloat) {
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

    var x: CGFloat

    init(x: CGFloat) {
        self.x = x
    }
}
