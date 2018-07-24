//
//  ViewController.swift
//  JellyfishAR
//
//  Created by Evan Butler on 7/17/18.
//  Copyright © 2018 Chromaplex. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController {
    //MARK: Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    //MARK: Properties
    let configuration = ARWorldTrackingConfiguration()
    var timer = Each(1).seconds
    var countdown = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.session.run(configuration)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func play(_ sender: Any) {
        self.setTimer()
        self.addNode()
        self.play.isEnabled = false
    }
    
    @IBAction func reset(_ sender: Any) {
        // Reset UI
        self.timer.stop()
        self.resetTimer()
        self.play.isEnabled = true
        self.timerLabel.text = "Let's Play!"
        
        // Remove child nodes from scene
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // Reset session
        self.sceneView.session.pause()
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func addNode() {
        let jellyfishScene = SCNScene(named: "Models.scnassets/Jellyfish.scn")
        let jellyfishNode = jellyfishScene?.rootNode.childNode(withName: "Jellyfish", recursively: false)
        
        jellyfishNode?.position = SCNVector3(randomNumbers(min: -1, max: 1), randomNumbers(min: -0.5, max: 0.5), randomNumbers(min: -1, max: 1))
        
        self.sceneView.scene.rootNode.addChildNode(jellyfishNode!)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let sceneViewTappedOn = sender.view as! SCNView
        let touchCoordinates = sender.location(in: sceneViewTappedOn)
        let hitTest = sceneViewTappedOn.hitTest(touchCoordinates)
        
        // check if node was touched and countdown has not reached 0
        if hitTest.isEmpty || countdown == 0 {
            return
        }
        
        self.resetTimer()
        
        let node = hitTest.first!.node
        
        // only animate if animation not currently in progress
        if !node.animationKeys.isEmpty {
            return
        }
        
        SCNTransaction.begin()
        attachAnimation(to: node)
        // scene transaction ensures this code is not executed until after animation is complete
        SCNTransaction.completionBlock = {
            // removes the jellyfish we tapped on
            node.removeFromParentNode()
            // adds a new jellyfish at a random position
            self.addNode()
        }
        SCNTransaction.commit()
    }
    
    func attachAnimation(to node: SCNNode) {
        let spin = CABasicAnimation(keyPath: "position")
        spin.fromValue = node.presentation.position
        spin.toValue = SCNVector3(node.presentation.position.x - 0.2, node.presentation.position.y - 0.2, node.presentation.position.z - 0.2)
        // duration in seconds
        spin.duration = 0.07
        // autoreverse animates the node back to its original position
        spin.autoreverses = true
        spin.repeatCount = 5
        node.addAnimation(spin, forKey: "position")
    }
    
    func randomNumbers(min firstNum: CGFloat, max secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func setTimer() {
        self.timer.perform { () -> NextStep in
            self.countdown -= 1
            self.timerLabel.text = String(self.countdown)
            
            if self.countdown == 0 {
                self.timerLabel.text = "You lose!"
                return .stop
            }
            
            return .continue
        }
    }
    
    func resetTimer() {
        self.countdown = 10
        self.timerLabel.text = String(self.countdown)
    }
}

