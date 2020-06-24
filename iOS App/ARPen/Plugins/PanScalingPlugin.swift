//
//  PanScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 25.04.20.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class PanScalingPlugin: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "PanScaling")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "PanScalingPluginInstructions")
    var pluginIdentifier: String = "PanScaling"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var panGesture: UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    
    var startingPosition : SCNVector3 = SCNVector3Make(0, 0, 0)
    var tapped : Bool = false

    var currentPoint = CGPoint()
    var previousPoint = CGPoint()
    var originalScale : SCNVector3 = SCNVector3Make(0.1, 0.1, 0.1)
    
    //Variables for userStudy
    var randomScaleFactor : Float = 0.0
    var modelToBoxScaleDifference: Float = 0.0
    var userStudyReps = 0

    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
       //print ("helloWorld")
        }
        
    
    //function for scaling object by pulling a corner
    @objc func handlePan(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found 4")
            return
        }
        guard let plane = scene.drawingNode.childNode(withName: "hitPlane", recursively: false) else{
                   print("not found 5")
                   return
        }
    
        guard let sceneView = self.currentView else { return }
        
        if tapped == false{
            return
        }
        
        if recognizer.state == .began{
            self.previousPoint = recognizer.location(in: sceneView)
            var hitTestResult = sceneView.hitTest(previousPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            for hit in hitTestResult{
                if hit.node == plane{
                    let start = hitTestResult.first?.localCoordinates
                    self.startingPosition = start!
                }
                else{
                    if let index = hitTestResult.firstIndex(of: hit) {
                        hitTestResult.remove(at: index)
                    }
                }
             }
         }
   
        
        if recognizer.state == .changed{
            self.currentPoint = recognizer.location(in: sceneView)
            //print("currentPoint: \(currentPoint)")
            
            var hitTestResult = sceneView.hitTest(currentPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            //use hitplane to determine fingerposition
            for hit in hitTestResult{
                if hit.node == plane{
                    print("node: \(String(describing: hitTestResult.first?.node.name))")
                    let currentPointInLC = hitTestResult.first?.localCoordinates
                    print("localCoords: \(String(describing: currentPointInLC))")
                    print("startingPosition: \(self.startingPosition)")
                    
                    //idea: a corner is reached by travelling half the scale into each direction, as corner of cube should remain beneath fingertip and we scale uniformly we get the scale by multiplying the corner position by 2
                    let scaleFactor = abs(currentPointInLC!.y) * 2
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    
                }
                else{
                    if let index = hitTestResult.firstIndex(of: hit) {
                        hitTestResult.remove(at: index)
                    }
                }
            }
        }
            
        else if recognizer.state == .ended{
            self.currentPoint = CGPoint(x:0, y:0)
        }
       
    }
    
    //function for selecting objects via touchscreen
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found 2")
            return
        }
        
        let touchPoint = sender.location(in: sceneView)
        
        var hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        
        for hit in hitResults{
            if hit.node == box{
                if tapped == false{
                    tapped = true
                    hit.node.opacity = 0.95
                }
                else if tapped == true{
                    tapped = false
                    hit.node.opacity = 0.8
                }
            }
                
            //only select the boxNode
            else{
                if let index = hitResults.firstIndex(of: hit) {
                    hitResults.remove(at: index)
                }
            }
        }
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        
        self.currentScene = scene
        self.currentView = view
        
        self.tapped = false
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.currentView?.addGestureRecognizer(panGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        //create random scale factor for model
        randomScaleFactor = Float.random(in: 0.05...0.15)
        while (randomScaleFactor == 0.1){
        randomScaleFactor = Float.random(in: 0.05...0.15)
        }
        
        //color Variables
        var greenMaterial = SCNMaterial()
        greenMaterial.diffuse.contents = UIColor.green
        greenMaterial.locksAmbientWithDiffuse = true;

        let redMaterial = SCNMaterial()
        redMaterial.diffuse.contents = UIColor.red
        redMaterial.locksAmbientWithDiffuse = true;

        let blueMaterial  = SCNMaterial()
        blueMaterial.diffuse.contents = UIColor.blue
        blueMaterial.locksAmbientWithDiffuse = true;

        let yellowMaterial = SCNMaterial()
        yellowMaterial.diffuse.contents = UIColor.yellow
        yellowMaterial.locksAmbientWithDiffuse = true;

        let purpleMaterial = SCNMaterial()
        purpleMaterial.diffuse.contents = UIColor.purple
        purpleMaterial.locksAmbientWithDiffuse = true;

        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor.white
        whiteMaterial.locksAmbientWithDiffuse = true;
        
        let grayMaterial = SCNMaterial()
        grayMaterial.diffuse.contents = UIColor.gray
        grayMaterial.locksAmbientWithDiffuse = true;
        
        //Defining the box
        let cube = SCNScene(named: "art.scnassets/box.scn")
        let cubeNode = cube?.rootNode.childNode(withName: "Box", recursively: true)
        //let boxNodeModel = cube?.rootNode.childNode(withName: "box2", recursively: true)
        let boxNode = cubeNode!
        boxNode.geometry?.materials = [greenMaterial,  redMaterial, blueMaterial, yellowMaterial, purpleMaterial, whiteMaterial];
        
        //Defining the model
        let boxNodeModel = cubeNode?.clone()
        boxNodeModel?.geometry = cubeNode?.geometry?.copy() as? SCNGeometry
        boxNodeModel?.geometry?.firstMaterial = boxNodeModel?.geometry?.firstMaterial!.copy() as? SCNMaterial
         
        var newMaterial = [SCNMaterial]()
        newMaterial = [grayMaterial,  redMaterial, blueMaterial, yellowMaterial, purpleMaterial, whiteMaterial];
        boxNodeModel?.geometry?.materials = newMaterial
        
        let boxModel = boxNodeModel!
        
        //defining a hitplane which helps with later hitTests
        let hitPlane = SCNNode()
        if hitPlane != scene.drawingNode.childNode(withName: "hitPlane", recursively: false){
                hitPlane.position = SCNVector3(0, 0, -0.7)
                hitPlane.name = "hitPlane"
                hitPlane.opacity = 0.01
                hitPlane.geometry = SCNPlane(width:0.8, height:0.8)
                //hitPlane.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                scene.drawingNode.addChildNode(hitPlane)
        }
        else{
            hitPlane.position = SCNVector3(0, 0, -0.65)
        }

        //create Object to scale
        if boxNode != scene.drawingNode.childNode(withName: "currenBoxNode", recursively: false){
            boxNode.position = SCNVector3(0, 0, -0.6)
            boxNode.name = "currentBoxNode"
            scene.drawingNode.addChildNode(boxNode)
            boxNode.opacity = 0.7
            boxNode.scale = originalScale
           // boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        }
        else{
            boxNode.position = SCNVector3(0, 0, -0.6)
        }

        //create Object as model
        if boxModel != scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.position = SCNVector3(0, 0, -0.6)
            boxModel.name = "modelBoxNode"
            boxModel.opacity = 0.5
            //boxModel.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
            
            boxModel.scale = SCNVector3(x: randomScaleFactor, y: randomScaleFactor, z: randomScaleFactor)
            scene.drawingNode.addChildNode(boxModel)
        }
        else{
            boxModel.position = SCNVector3(0, 0, -0.6)
        }
    }
    
    func deactivatePlugin() {
        if let boxNode = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            boxNode.removeFromParentNode()
        }
               
        if let boxModel = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
           boxModel.removeFromParentNode()
        }

        if let hitPlane = currentScene?.drawingNode.childNode(withName: "hitPlane", recursively: false){
            hitPlane.removeFromParentNode()
        }
               
        self.currentScene = nil

        if let panGestureRecognizer = self.panGesture{
           self.currentView?.removeGestureRecognizer(panGestureRecognizer)
        }

        if let tapGestureRecognizer = self.tapGesture{
           self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }

        self.currentView = nil
    }
    
}



