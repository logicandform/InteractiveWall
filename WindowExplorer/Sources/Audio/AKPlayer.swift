//  Created by Ryan Francesconi, revision history on Github.
//  Copyright © 2017 AudioKit. All rights reserved.

import AVFoundation

/**
 AKPlayer is meant to be a simple yet powerful audio player that just works. It supports
 scheduling of sounds and looping. Players can be locked to a common
 clock as well as video by using hostTime in the various play functions. By default the
 player will buffer audio as needed, otherwise it will play it from disk. Looping will cause the file to buffer.

 There are a few options for syncing to external objects.

 A locked video function would resemble:
 ```
 func videoPlay(at time: TimeInterval = 0, hostTime: UInt64 = 0 ) {
 let cmHostTime = CMClockMakeHostTimeFromSystemUnits(hostTime)
 let cmVTime = CMTimeMakeWithSeconds(time, 1000000)
 let futureTime = CMTimeAdd(cmHostTime, cmVTime)
 videoPlayer.setRate(1, time: kCMTimeInvalid, atHostTime: futureTime)
 }
 ```

 Basic usage looks like:
 ```
 guard let player = AKPlayer(url: url) else { return }
 player.completionHandler = { print("Done") }

 // Loop Options
 player.loop.start = 1
 player.loop.end = 3
 player.isLooping = true

 player.play()
 ```

 Please note that pre macOS 10.13 / iOS 11 the completionHandler isn't sample accurate. It's pretty close though.
 */
public class AKPlayer {
    open var avAudioNode: AVAudioNode

    public struct Loop {
        public var start: Double = 0 {
            willSet {
                if newValue != start { needsUpdate = true }
            }
        }
        public var end: Double = 0 {
            willSet {
                if newValue != end { needsUpdate = true }
            }
        }
        var needsUpdate: Bool = false
    }

    // MARK: - Private Parts

    // The underlying player node
    let playerNode = AVAudioPlayerNode()
    private var inmixer = AVAudioMixerNode()
    private var panner = MultiChannelPanner()
    private static var outmixer = AVAudioMixerNode()
    private var startingFrame: AVAudioFramePosition?
    private var endingFrame: AVAudioFramePosition?
    private var nextRenderFrame: AVAudioFramePosition = 0

    // these timers will go away when AudioKit is built for 10.13
    // in that case the real completion handlers of the scheduling can be used.
    // Pre 10.13 the completion handlers are inaccurate to the point of unusable.
    private var prerollTimer: Timer?
    private var completionTimer: Timer?

    private var playerTime: Double {
        if let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }

    var sampleRate: Double = 44100
    private var _startTime: Double = 0
    private var _endTime: Double = 0

    // MARK: - Public Properties

    /// Completion handler to be called when Audio is done playing. The handler won't be called if
    /// stop() is called while playing or when looping.
    public var completionHandler: (() -> Void)?

    public var buffer: AVAudioPCMBuffer?

    /// The internal audio file
    public private(set) var audioFile: AVAudioFile?

    /// The duration of the loaded audio file
    public var duration: Double {
        guard let audioFile = audioFile else { return 0 }
        return Double(audioFile.length) / audioFile.fileFormat.sampleRate
    }

    /// Looping params
    public var loop = Loop()

    public var location: Double {
        get {
            return panner.location
        }
        set {
            panner.location = newValue
        }
    }

    /// Volume 0.0 -> 1.0, default 1.0
    public var volume: Double {
        get { return Double(playerNode.volume) }
        set { playerNode.volume = Float(newValue) }
    }

    /// Left/Right balance -1.0 -> 1.0, default 0.0
    public var pan: Double {
        get { return Double(playerNode.pan) }
        set { playerNode.pan = Float(newValue) }
    }

    /// Get or set the start time of the player.
    public var startTime: Double {
        get {
            return max(0, isLooping ? loop.start : _startTime)
        }

        set {
            self._startTime = max(0, newValue)
        }
    }

    /// Get or set the end time of the player.
    public var endTime: Double {
        get {
            return isLooping ? loop.end : _endTime
        }

        set {
            var newValue = newValue
            if newValue == 0 {
                newValue = duration
            }
            self._endTime = min(newValue, duration)
        }
    }

    /// - Returns: The total frame count that is being playing.
    /// Differs from the audioFile.length as this will be updated with the edited amount
    /// of frames based on startTime and endTime
    public private(set) var frameCount: AVAudioFrameCount = 0

    /// - Returns: The current frame while playing
    public var currentFrame: AVAudioFramePosition {
        if let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            return playerTime.sampleTime
        }
        return 0
    }

    /// - Returns: Current time of the player in seconds while playing.
    public var currentTime: Double {
        let current = startTime + playerTime.truncatingRemainder(dividingBy: (endTime - startTime))
        return current
    }

    // MARK: - Public Options

    /// true if the player is buffering audio rather than playing from disk
    public var isBuffered: Bool {
        return isLooping
    }

    public var isLooping: Bool = false

    public var isPlaying: Bool {
        return playerNode.isPlaying
    }

    // MARK: - Initialization

    /// Create a player from a URL
    public convenience init?(url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        do {
            let avfile = try AVAudioFile(forReading: url)
            self.init(audioFile: avfile)
            return
        } catch {
            print("ERROR loading \(url.path) \(error)")
        }
        return nil
    }

    /// Create a player from an AVAudioFile
    public convenience init(audioFile: AVAudioFile) {
        self.init()
        self.audioFile = audioFile
        initialize()
    }

    public init() {
        avAudioNode = AKPlayer.outmixer
    }

    private func initialize() {
        guard let audioFile = audioFile else { return }

        if playerNode.engine == nil {
            AudioController.shared.engine.attach(playerNode)
        }
        if inmixer.engine == nil {
            AudioController.shared.engine.attach(inmixer)
        }
        if panner.audioNode?.engine == nil {
            AudioController.shared.engine.attach(panner.audioNode)
        }
        if AKPlayer.outmixer.engine == nil {
            AudioController.shared.engine.attach(AKPlayer.outmixer)
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: audioFile.fileFormat.sampleRate,
                                   channels: audioFile.fileFormat.channelCount)
        sampleRate = audioFile.fileFormat.sampleRate

        AudioController.shared.engine.connect(playerNode, to: inmixer, format: format)
        AudioController.shared.engine.connect(inmixer, to: panner.audioNode!, format: format)

        let mixerFormat = AVAudioFormat(
            standardFormatWithSampleRate: audioFile.fileFormat.sampleRate,
            channels: 6)
        AudioController.shared.engine.connect(panner.audioNode!, to: AKPlayer.outmixer, format: mixerFormat)

        loop.start = 0
        loop.end = duration
        buffer = nil
        preroll(from: 0, to: duration)
    }

    // MARK: - Loading

    /// Replace the contents of the player with this url
    public func load(url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        load(audioFile: file)
    }

    public func load(audioFile: AVAudioFile) {
        self.audioFile = audioFile
        initialize()
    }

    /// Mostly applicable to buffered players, this loads the buffer and gets it ready to play.
    /// Otherwise it just sets the startTime and endTime
    public func preroll(from startingTime: Double = 0, to endingTime: Double = 0) {
        var from = startingTime
        let to = endingTime

        if from > to {
            from = 0
        }
        startTime = from
        endTime = to

        guard isBuffered else { return }
        updateBuffer()
    }

    // MARK: - Playback

    public func start() {
        preroll(from: startTime, to: endTime)
        playerNode.play()
    }

    /// Play using full options. Last in the convenience play chain, all play() commands will end up here
    public func play(from startingTime: Double, to endingTime: Double, at audioTime: AVAudioTime?) {
        preroll(from: startingTime, to: endingTime)
        scheduleSegment(from: 0, frameCount: frameCount, at: audioTime, completion: nil)
        playerNode.play()
    }

    /// Stop playback and cancel any pending scheduled playback or completion events
    public func stop() {
        playerNode.stop()
        completionTimer?.invalidate()
        prerollTimer?.invalidate()
    }

    // MARK: - Scheduling

    // NOTE to maintainers: these timers can be removed when AudioKit is built for 10.13.
    // in that case the AVFoundation completion handlers of the scheduling can be used.
    // Pre 10.13, the completion handlers are inaccurate to the point of unusable.

    // if the file is scheduled, start a timer to determine when to start the completion timer
    private func startPrerollTimer(_ prerollTime: Double) {
        prerollTimer = Timer.scheduledTimer(timeInterval: prerollTime,
                                            target: self,
                                            selector: #selector(AKPlayer.startCompletionTimer),
                                            userInfo: nil,
                                            repeats: false)
    }

    // keep this timer separate in the cases of sounds that aren't scheduled
    @objc
    private func startCompletionTimer() {
        var segmentDuration = endTime - startTime
        if isLooping && loop.end > 0 {
            segmentDuration = loop.end - startTime
        }
        completionTimer = Timer.scheduledTimer(timeInterval: segmentDuration,
                                               target: self,
                                               selector: #selector(handleComplete),
                                               userInfo: nil,
                                               repeats: false)
    }

    func schedule(at time: CMTime, duration: Double, completion: (() -> Void)?) {
        let seekThreshold = AVAudioFramePosition(1 * sampleRate)
        let frameCount = AVAudioFrameCount(duration * sampleRate) - 1
        let newFrame = AVAudioFramePosition(time.seconds * sampleRate)

        if abs(newFrame - nextRenderFrame) >= seekThreshold {
            // If the difference is too large it's probably a seek operation
            nextRenderFrame = newFrame
        } else if newFrame < nextRenderFrame {
            // If running too fast just skip scheduling this segment
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + duration) {
                completion?()
            }
            return
        }
        // Missing `else` here because we don't want to reschedule audio, it causes audible glitches. This works
        // beacause it is a lot more common that video runs slower and if the opposite happens we'll eventually
        // correct it with the first case above (seek).

        scheduleSegment(from: nextRenderFrame, frameCount: frameCount, at: nil, completion: completion)
        nextRenderFrame += AVAudioFramePosition(frameCount)
    }

    func scheduleBuffer(at audioTime: AVAudioTime) {
        guard let buffer = buffer else { return }

        if playerNode.outputFormat(forBus: 0) != buffer.format {
            initialize()
        }

        let bufferOptions: AVAudioPlayerNodeBufferOptions = isLooping ? [.loops, .interrupts] : [.interrupts]

        // print("Scheduling buffer...\(startTime) to \(endTime)")
        if #available(iOS 11, macOS 10.13, tvOS 11, *) {
            playerNode.scheduleBuffer(buffer,
                                      at: audioTime,
                                      options: bufferOptions,
                                      completionCallbackType: .dataPlayedBack,
                                      completionHandler: completionHandler != nil ? handleCallbackComplete : nil)
        } else {
            // Fallback on earlier version
            playerNode.scheduleBuffer(buffer,
                                      at: audioTime,
                                      options: bufferOptions,
                                      completionHandler: nil) // these completionHandlers are inaccurate pre 10.13
        }

        playerNode.prepare(withFrameCount: buffer.frameLength)
    }

    // play from disk rather than ram
    func scheduleSegment(from start: AVAudioFramePosition, frameCount: AVAudioFrameCount, at time: AVAudioTime?, completion: (() -> Void)? = nil) {
        guard let audioFile = audioFile else { return }

        playerNode.scheduleSegment(audioFile, startingFrame: start, frameCount: frameCount, at: time, completionHandler: completion)
        playerNode.prepare(withFrameCount: frameCount)
    }

    // MARK: - Completion Handlers

    // this will be the method in the scheduling completionHandler >= 10.13
    @available(iOS 11, macOS 10.13, tvOS 11, *)
    @objc private func handleCallbackComplete(completionType: AVAudioPlayerNodeCompletionCallbackType) {
        // print("\(audioFile?.url.lastPathComponent ?? "?") currentFrame:\(currentFrame) totalFrames:\(frameCount)")
        // only forward the completion if is actually done playing.
        // if the user calls stop() themselves then the currentFrame will be < frameCount

        if currentFrame >= frameCount {
            DispatchQueue.main.async {
                self.completionHandler?()
            }
        }
    }

    @objc
    private func handleComplete() {
        stop()
        if isLooping {
            startTime = loop.start
            endTime = loop.end
            play(from: startTime, to: endTime, at: nil)
            return
        }
        completionHandler?()
    }

    // MARK: - Buffering routines

    // Fills the buffer with data read from audioFile
    private func updateBuffer(force: Bool = false) {
        if !isBuffered { return }

        guard let audioFile = audioFile else { return }

        let fileFormat = audioFile.fileFormat
        let processingFormat = audioFile.processingFormat

        let startFrame = AVAudioFramePosition(startTime * fileFormat.sampleRate)
        let endFrame = AVAudioFramePosition(endTime * fileFormat.sampleRate)

        let updateNeeded = (force || buffer == nil ||
            startFrame != startingFrame || endFrame != endingFrame || loop.needsUpdate)

        if !updateNeeded {
            return
        }

        guard audioFile.length > 0 else {
            print("ERROR updateBuffer: Could not set PCM buffer -> " +
                "\(audioFile) length = 0.")
            return
        }

        frameCount = AVAudioFrameCount(endFrame - startFrame)

        guard frameCount > 0 else {
            print("totalFrames to play is \(frameCount). Bailing.")
            return
        }

        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount) else { return }

        do {
            audioFile.framePosition = startFrame
            // read the requested frame count from the file
            try audioFile.read(into: pcmBuffer, frameCount: frameCount)

            buffer = pcmBuffer

        } catch let err as NSError {
            print("ERROR AKPlayer: Couldn't read data into buffer. \(err)")
            return
        }

        if isLooping {
            loop.needsUpdate = false
        }

        // these are only stored to check if the buffer needs to be updated in subsequent fills
        startingFrame = startFrame
        endingFrame = endFrame
    }

    /// Disconnect the node and release resources
    public func disconnect() {
        stop()
        audioFile = nil
        buffer = nil
        inmixer.engine?.detach(inmixer)
        panner.audioNode?.engine?.detach(panner.audioNode!)
        playerNode.engine?.detach(playerNode)
    }
}

extension AKPlayer {
    public func start(at audioTime: AVAudioTime?) {
        play(from: startTime, to: endTime, at: audioTime)
    }

    public var isStarted: Bool {
        return isPlaying
    }

    public func setPosition(_ position: Double) {
        startTime = position
        if isPlaying {
            stop()
            play(from: startTime, to: endTime, at: nil)
        }
    }

    public func position(at audioTime: AVAudioTime?) -> Double {
        guard let playerTime = playerNode.playerTime(forNodeTime: audioTime ?? AVAudioTime.now()) else {
            return startTime
        }
        return startTime + Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    public func audioTime(at position: Double) -> AVAudioTime? {
        let sampleRate = playerNode.outputFormat(forBus: 0).sampleRate
        let sampleTime = (position - startTime) * sampleRate
        let playerTime = AVAudioTime(sampleTime: AVAudioFramePosition(sampleTime), atRate: sampleRate)
        return playerNode.nodeTime(forPlayerTime: playerTime)
    }

    open func prepare() {
        preroll(from: startTime, to: endTime)
    }
}

/// Utility to convert between host time and seconds
private let ticksToSeconds: Double = {
    var tinfo = mach_timebase_info()
    let err = mach_timebase_info(&tinfo)
    let timecon = Double(tinfo.numer) / Double(tinfo.denom)
    return timecon * 0.000_000_001
}()

/// Utility to convert between seconds to host time.
private let secondsToTicks: Double = {
    var tinfo = mach_timebase_info()
    let err = mach_timebase_info(&tinfo)
    let timecon = Double(tinfo.denom) / Double(tinfo.numer)
    return timecon * 1_000_000_000
}()

extension AVAudioTime {

    /// An AVAudioTime with a valid hostTime representing now.
    open static func now() -> AVAudioTime {
        return AVAudioTime(hostTime: mach_absolute_time())
    }

    /// Returns an AVAudioTime offest by seconds.
    open func offset(seconds: Double) -> AVAudioTime {

        if isSampleTimeValid && isHostTimeValid {
            return AVAudioTime(hostTime: hostTime + UInt64(seconds / ticksToSeconds),
                               sampleTime: sampleTime + AVAudioFramePosition(seconds * sampleRate),
                               atRate: sampleRate)
        } else if isSampleTimeValid {
            return AVAudioTime(sampleTime: sampleTime + AVAudioFramePosition(seconds * sampleRate),
                               atRate: sampleRate)
        } else if isHostTimeValid {
            return AVAudioTime(hostTime: hostTime + UInt64(seconds / ticksToSeconds))
        }
        return self
    }

    /// Convert an AVAudioTime object to seconds with a hostTime reference
    open func toSeconds(hostTime: UInt64) -> Double {
        return AVAudioTime.seconds(forHostTime: self.hostTime - hostTime)
    }

    // Convert seconds to AVAudioTime with a hostTime reference
    open class func secondsToAudioTime(hostTime: UInt64, time: Double) -> AVAudioTime {
        // Find the conversion factor from host ticks to seconds
        var timebaseInfo = mach_timebase_info()
        mach_timebase_info(&timebaseInfo)
        let hostTimeToSecFactor = Double(timebaseInfo.numer) / Double(timebaseInfo.denom) / Double(NSEC_PER_SEC)
        let out = AVAudioTime(hostTime: hostTime + UInt64(time / hostTimeToSecFactor))
        return out
    }
}
