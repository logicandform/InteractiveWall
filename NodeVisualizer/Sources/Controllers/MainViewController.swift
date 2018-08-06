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

        mainView.showsFPS = true
        mainView.showsNodeCount = true
//        mainView.showsFields = true
        mainView.showsPhysics = true
        mainView.ignoresSiblingOrder = true
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if Configuration.env == .testing {
            setupTestingEnvironment()
        } else {
            setupEnvironment()
        }
    }


    // MARK: Setup Environment

    private func setupEnvironment() {
        DataManager.instance.instantiate { [weak self] in
            self?.setupMainScene()
        }
    }

    private func setupTestingEnvironment() {
        TestingDataManager.instance.instantiate()
        setupMainScene()
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

    private func convert(_ touch: Touch, toScreen screen: Int) {
        let screen = NSScreen.at(position: screen)
        let xPos = (touch.position.x / Configuration.touchScreenSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreenSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
