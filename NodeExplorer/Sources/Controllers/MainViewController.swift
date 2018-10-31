//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit
import MacGestures


class MainViewController: NSViewController, NodeGestureResponder {
    static let storyboard = "Main"

    @IBOutlet var mainView: SKView!

    var gestureManager: NodeGestureManager!
    private let touchListener = TouchListener()
    private var initialized = false


    // MARK: Init

    static func instance() -> MainViewController {
        return NSStoryboard(name: MainViewController.storyboard, bundle: .main).instantiateInitialController() as! MainViewController
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = NodeGestureManager(responder: self)

        setupPort()
        setupView()
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

    private func setupPort() {
        touchListener.listenToPort(named: ApplicationType.nodeNetwork.port(app: 0))
        touchListener.receivedTouch = { [weak self] touch in
            self?.gestureManager.handle(touch)
        }
    }

    private func setupView() {
        mainView.showsFPS = true
        mainView.showsNodeCount = true
    }

    private func setupEntities() {
        switch Configuration.env {
        case .production:
            RecordManager.instance.createEntities()
        case .testing:
            TestingDataManager.instance.instantiate()
            TestingDataManager.instance.createEntities()
        }
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
        mainScene.backgroundColor = style.darkBackgroundOpaque
        mainScene.scaleMode = .aspectFill
        return mainScene
    }
}
