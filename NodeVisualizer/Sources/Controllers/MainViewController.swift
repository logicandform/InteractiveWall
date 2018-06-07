//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit


class MainViewController: NSViewController {
    static let storyboard = NSStoryboard.Name(rawValue: "Main")

    @IBOutlet var mainView: SKView!

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

        // could show loading scene when we are making network request, then transistion to the main scene

        DataManager.instance.associateRecordsToRelatedRecords(then: { [weak self] records in
            self?.records = records

            let mainScene = self?.makeScene()
            mainScene?.records = records

            self?.mainView.presentScene(mainScene)
        })

        mainView.showsFPS = true
        mainView.showsNodeCount = true
        mainView.ignoresSiblingOrder = true
    }


    // MARK: Helpers

    private func makeScene() -> MainScene {
        let width = view.frame.width
        let height = view.frame.height

        let scene = MainScene(size: CGSize(width: width, height: height))
        scene.backgroundColor = style.darkBackground
        scene.scaleMode = .aspectFill
        return scene
    }
}
