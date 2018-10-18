//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa
import AVKit
import MacGestures


class InfoItemView: NSCollectionViewItem, PlayerControlDelegate {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "InfoItemView")

    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var highlightView: NSView!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var mediaImageView: ImageView!
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var playerControl: PlayerControl!
    @IBOutlet weak var playerStateImageView: NSImageView!
    @IBOutlet weak var playerControlTopConstraint: NSLayoutConstraint!

    weak var delegate: InfoViewDelegate?
    private var showingControls = false

    var infoItem: InfoItem! {
        didSet {
            load(infoItem)
        }
    }

    private struct Constants {
        static let playerControlHeight: CGFloat = 40
        static let playerControlAnimationDuration = 0.5
        static let headerHeight: CGFloat = 40
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }


    // MARK: API

    func handlePlayer(_ tap: TapGestureRecognizer) {
        guard infoItem.media.type == .video, let position = tap.position, playerView.frame.contains(position) else {
            return
        }

        if showingControls {
            playerControl.toggle()
        } else {
            togglePlayerControl(on: true)
        }
    }

    func handleVolume(_ tap: TapGestureRecognizer) {
        guard infoItem.media.type == .video else {
            return
        }

        if showingControls {
            playerControl.toggleVolume()
        } else {
            togglePlayerControl(on: true)
        }
    }

    func handle(_ pan: PanGestureRecognizer) {
        guard infoItem.media.type == .video else {
            return
        }

        if showingControls {
            playerControl.didScrubControl(pan)
        }
    }

    func unfocus() {
        playerControl.set(.paused)
        togglePlayerControl(on: false)
    }

    func set(volume level: VolumeLevel) {
        playerControl.set(volume: level)
    }


    // MARK: Setup

    private func setupViews() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        highlightView.wantsLayer = true
        highlightView.layer?.backgroundColor = style.menuTintColor.cgColor
        playerControl.tintColor = style.menuTintColor
        playerStateImageView.wantsLayer = true
        playerStateImageView.layer?.cornerRadius = playerStateImageView.frame.width / 2
        playerStateImageView.layer?.backgroundColor = style.darkBackground.cgColor
    }

    private func load(_ item: InfoItem) {
        titleLabel.attributedStringValue = NSAttributedString(string: item.title, attributes: style.windowTitleAttributes)
        setupStackView(for: item.labels)

        switch item.media.type {
        case .video:
            setupPlayer(for: item.media)
        case .image:
            setupImage(for: item.media)
        default:
            return
        }
    }

    private func setupStackView(for labels: [InfoLabel]) {
        for label in labels {
            if !label.title.isEmpty {
                let titleString = NSAttributedString(string: label.title, attributes: style.recordSmallHeaderAttributes)
                let titleLabel = textField(for: titleString)
                stackView.addView(titleLabel, in: .top)
                stackView.setCustomSpacing(style.smallHeaderTrailingSpace, after: titleLabel)
            }
            if !label.description.isEmpty {
                let descriptionString = NSAttributedString(string: label.description, attributes: style.recordDescriptionAttributes)
                let descriptionLabel = textField(for: descriptionString)
                stackView.addView(descriptionLabel, in: .top)
                stackView.setCustomSpacing(style.descriptionTrailingSpace, after: descriptionLabel)
            }
        }
    }

    private func setupPlayer(for media: Media) {
        guard media.type == .video else {
            return
        }

        let url = Configuration.localMediaURLs ? media.localURL : media.url
        let player = AVPlayer(url: url)
        player.isMuted = true
        playerView.player = player

        playerControl.player = player
        playerControl.delegate = self
    }

    private func setupImage(for media: Media) {
        guard media.type == .image else {
            return
        }

        playerView.isHidden = true
        playerStateImageView.isHidden = true

        CachingNetwork.getImage(for: media) { [weak self] image in
            if let image = image {
                self?.mediaImageView.set(image)
            }
        }
    }


    // MARK: PlayerControlDelegate

    func playerChangedState(_ state: PlayerState) {
        if let image = state.image {
            playerStateImageView.image = image
        }

        let playerStateAlpha: CGFloat = state == .playing ? 0 : 1
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = 1
            self?.playerStateImageView.animator().alphaValue = playerStateAlpha
        })
    }

    func playerChangedVolume(_ state: VolumeLevel) {
        delegate?.didToggleVolume(level: state)
    }


    // MARK: Helpers

    private func togglePlayerControl(on: Bool) {
        if showingControls == on {
            return
        }

        let state = on ? PlayerState.playing : PlayerState.paused
        playerControl.set(state)
        showingControls = on
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.playerControlAnimationDuration
            self?.playerControlTopConstraint.animator().constant = on ? -Constants.playerControlHeight : 0
        })
    }

    private func textField(for attributedString: NSAttributedString) -> NSTextField {
        let label = NSTextField(labelWithAttributedString: attributedString)
        label.drawsBackground = false
        label.isBordered = false
        label.isSelectable = false
        label.sizeToFit()
        return label
    }
}
