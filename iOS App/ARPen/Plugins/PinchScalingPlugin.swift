//
//  PinchScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 07.04.20.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class PinchScalingPlugin: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "PinchScaling")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "PinchScalingPluginInstructions")
    var pluginIdentifier: String = "PinchScaling"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView:  UILabel?
    var pinchGesture: UIPinchGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    
    var tapped : Bool = false
    var firstSelection : Bool = false
    
    var currentPoint = CGPoint()
    var previousPoint = CGPoint()
    
    //Variables For USER STUDY TASK
    var randomScaleFactor : Float = 0.0
    
    var userStudyReps = 0
    var originalScale : SCNVector3 = SCNVector3Make(0.1, 0.1, 0.1)
    
    //variables for measuring
    var selectionCounter = 0
    var scaleDifferenceStart: Float = 0.0
    var scaleDifferenceEnd: Float = 0.0
    var amountBoxWasScaled : Float = 0.0
    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    
    var studyData : [String:String] = [:]

    

    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
            
    }
    
    //function for scaling object through pinch gesture
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let sceneView = self.currentView else { return }
        
        if tapped == false{
            return
        }
        
        if recognizer.state == .began{
                self.currentPoint = recognizer.location(in: sceneView)
        }
    
        if (recognizer.state == .changed){
            let pinchScaleX =  Float(recognizer.scale) * box.scale.x
            let pinchScaleY =  Float(recognizer.scale) * box.scale.y
            let pinchScaleZ =  Float(recognizer.scale) * box.scale.z

            amountBoxWasScaled = Float(recognizer.scale)
            print ("scaleAmount \(amountBoxWasScaled)")

            box.scale = SCNVector3(x: Float(pinchScaleX), y: Float(pinchScaleY), z: Float(pinchScaleZ))
            recognizer.scale=1
        }
    }
    
    //function for selecting objects via touchscreen
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
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
        
        let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = SCNLight.LightType.ambient
            ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLightNode)
            
        let omniLightNode = SCNNode()
            omniLightNode.light = SCNLight()
            omniLightNode.light!.type = SCNLight.LightType.omni
            omniLightNode.light!.color = UIColor(white: 0.75, alpha: 1.0)
            omniLightNode.position = SCNVector3Make(0, 50, 50)
            scene.rootNode.addChildNode(omniLightNode)
        
        self.tapped = false
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        print ("tapGesture: \(String(describing: tapGesture))")
        
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        self.currentView?.addGestureRecognizer(pinchGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        //create random scale factor for model
        randomScaleFactor = Float.random(in: 0.05...0.15)
        while (randomScaleFactor == 0.1){
        randomScaleFactor = Float.random(in: 0.05...0.15)
        }
        
        let cube = SCNScene(named: "art.scnassets/box.scn")
        let cubeNode = cube?.rootNode.childNode(withName: "Box", recursively: true)
        cubeNode?.scale = originalScale
        //let boxNodeModel = cube?.rootNode.childNode(withName: "box2", recursively: true)

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
        
        let boxNode = cubeNode!
        boxNode.geometry?.materials = [greenMaterial,  redMaterial, blueMaterial,
        yellowMaterial, purpleMaterial, whiteMaterial]
        
        let boxNodeModel = cubeNode?.clone()
        boxNodeModel?.geometry = cubeNode?.geometry?.copy() as? SCNGeometry
        boxNodeModel?.geometry?.firstMaterial = boxNodeModel?.geometry?.firstMaterial!.copy() as? SCNMaterial
      
        var newMaterial = [SCNMaterial]()
        newMaterial = [grayMaterial,  redMaterial, blueMaterial,
        yellowMaterial, purpleMaterial, whiteMaterial];
  
        boxNodeModel?.geometry?.materials = newMaterial
        
        let boxModel = boxNodeModel!

        //create Object to scale
        if boxNode != scene.drawingNode.childNode(withName: "currenBoxNode", recursively: false){
            boxNode.position = SCNVector3(0, 0, -0.3)
            boxNode.name = "currentBoxNode"
            scene.drawingNode.addChildNode(boxNode)
            boxNode.opacity = 0.8
            //boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            
        }
        else{
            boxNode.position = SCNVector3(0, 0, -0.3)
        }

        //create Object as model
        if boxModel != scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.position = SCNVector3(0, 0, -0.3)
            boxModel.name = "modelBoxNode"
            boxModel.opacity = 0.65
            //boxNode.geometry?.materials = [greenMaterial,  redMaterial,    blueMaterial,yellowMaterial, purpleMaterial, whiteMaterial];
            //boxModel.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
            boxModel.scale = SCNVector3(x: randomScaleFactor, y: randomScaleFactor, z: randomScaleFactor)
            scene.drawingNode.addChildNode(boxModel)
        }
        else{
            boxModel.position = SCNVector3(0, 0, -0.3)
        }

        //scaleDifference = abs(boxNode.scale.x - randomScaleFactor)
        //print("scaleDifference \(scaleDifference)")
        //print ("childnodes\(scene.drawingNode.childNodes)")
        
    }
    
    
    func deactivatePlugin() {
        if let boxNode = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            boxNode.removeFromParentNode()
        }

        if let boxModel = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.removeFromParentNode()
        }

        self.currentScene = nil

        if let pinchGestureRecognizer = self.pinchGesture{
            self.currentView?.removeGestureRecognizer(pinchGestureRecognizer)
        }

        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }

        self.currentView = nil
    }
    
}


