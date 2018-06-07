//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit
import MONode


class MainViewController: NSViewController, GestureResponder {
    static let storyboard = NSStoryboard.Name(rawValue: "Main")

    @IBOutlet var mainView: SKView!

    // MONode
    static let touchNetwork = NetworkConfiguration(broadcastHost: "10.58.73.255", nodePort: 13001)
    let socketManager = SocketManager(networkConfiguration: touchNetwork)
    var gestureManager: GestureManager!
    var touchNeedsUpdate = [Touch: Bool]()

    private var records = [RecordDisplayable]()


    // MARK: Init

    static func instance() -> MainViewController {
        let vc = NSStoryboard(name: MainViewController.storyboard, bundle: .main).instantiateInitialController() as! MainViewController
        return vc
    }


    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard mainView.scene == nil else {
            return
        }

        socketManager.delegate = self
        gestureManager = GestureManager(responder: self)


        // could show loading scene when we are making network request, then transistion to the main scene

        DataManager.instance.associateRecordsToRelatedRecords(then: { [weak self] records in
            self?.setupMainScene(with: records)
        })

        mainView.showsFPS = true
        mainView.showsNodeCount = true
        mainView.ignoresSiblingOrder = true
    }


    // MARK: Helpers

    private func setupMainScene(with records: [RecordDisplayable]) {
        self.records = records

        let mainScene = makeScene()
        mainScene.records = records
        mainScene.gestureManager = gestureManager

        mainView.presentScene(mainScene)
    }

    private func makeScene() -> MainScene {
        let scene = MainScene(size: CGSize(width: view.bounds.width, height: view.bounds.height))
        scene.backgroundColor = style.darkBackground
        scene.scaleMode = .aspectFill
        return scene
    }
}


extension MainViewController: SocketManagerDelegate {
    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet), shouldSend(touch) else {
            return
        }

        convert(touch, toScreen: touch.screen)
        gestureManager.handle(touch)
    }

    func handleError(_ message: String) {
        print("Socket error: \(message)")
    }

    private func shouldSend(_ touch: Touch) -> Bool {
        switch touch.state {
        case .down:
            touchNeedsUpdate[touch] = false
        case .up:
            touchNeedsUpdate.removeValue(forKey: touch)
        case .moved:
            if let update = touchNeedsUpdate[touch] {
                touchNeedsUpdate[touch] = !update
                return update
            }
        case .indicator:
            return true
        }

        return true
    }

    private func convertToScreen(_ touch: Touch) {
        guard let screen = NSScreen.screens.at(index: touch.screen) else {
            return
        }

        let xPos = (touch.position.x / Configuration.touchScreenSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    private func convert(_ touch: Touch, toScreen screen: Int) {
        let screen = NSScreen.at(position: screen)
        let xPos = (touch.position.x / Configuration.touchScreenSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
