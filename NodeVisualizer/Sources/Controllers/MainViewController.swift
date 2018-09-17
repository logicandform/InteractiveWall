//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit
import MONode


class MainViewController: NSViewController, NodeGestureResponder, SocketManagerDelegate {
    static let touchNetwork = NetworkConfiguration(broadcastHost: Configuration.broadcastIP, nodePort: Configuration.touchPort)
    static let storyboard = NSStoryboard.Name(rawValue: "Main")

    @IBOutlet var mainView: SKView!
    private var initialized = false

    // MONode
    let socketManager = SocketManager(networkConfiguration: touchNetwork)
    var gestureManager: NodeGestureManager!
    var touchNeedsUpdate = [Touch: Bool]()


    // MARK: Init

    static func instance() -> MainViewController {
        return NSStoryboard(name: MainViewController.storyboard, bundle: .main).instantiateInitialController() as! MainViewController
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        socketManager.delegate = self
        gestureManager = NodeGestureManager(responder: self)

        mainView.showsFPS = true
        mainView.showsNodeCount = true
        mainView.showsFields = false
        mainView.showsPhysics = false
        mainView.ignoresSiblingOrder = true
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if !initialized {
            initialized = true
            setupEntities()
            setupMainScene()
        }
    }


    // MARK: Setup

    private func setupEntities() {
        switch Configuration.env {
        case .production:
            RecordManager.instance.createEntities()
        case .testing:
            TestingDataManager.instance.instantiate()
            TestingDataManager.instance.createEntities()
        }
    }


    // MARK: SocketManagerDelegate

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


    // MARK: Helpers

    private func setupMainScene() {
        let mainScene = makeMainScene()
        EntityManager.instance.scene = mainScene
        mainScene.gestureManager = gestureManager
        mainView.presentScene(mainScene)
    }

    private func makeMainScene() -> MainScene {
        let mainScene = MainScene(size: CGSize(width: mainView.bounds.width, height: mainView.bounds.height))
        mainScene.backgroundColor = style.darkBackground
        mainScene.scaleMode = .aspectFill
        return mainScene
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

    private func convert(_ touch: Touch, toScreen screen: Int) {
        let screen = NSScreen.at(position: screen)
        let xPos = (touch.position.x / Configuration.touchScreen.size.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreen.size.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
