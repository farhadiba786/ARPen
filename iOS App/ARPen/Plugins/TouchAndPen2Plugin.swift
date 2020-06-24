   //
   //  TouchAndPen2Plugin.swift
   //  ARPen
   //
   //  Created by Farhadiba Mohammed on 25.04.20.
   //  Copyright © 2018 RWTH Aachen. All rights reserved.
   //

   import Foundation
   import ARKit

   //include the UserStudyRecordPluginProtocol to demo recording of user study data
   class TouchAndPen2Plugin: Plugin,UserStudyRecordPluginProtocol {

   //reference to userStudyRecordManager to add new records
   var recordManager: UserStudyRecordManager!
   var pluginImage: UIImage? = UIImage.init(named: "TouchAndPen2")
   var pluginIdentifier: String = "TouchAndPen2"
   var pluginInstructionsImage: UIImage?
   var needsBluetoothARPen: Bool = false
   var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
   var currentView : ARSCNView?
   var currentScene : PenScene?
   var tapGesture : UITapGestureRecognizer?
       

   var originalScale : SCNVector3 = SCNVector3Make(0.1, 0.1, 0.1)
   var penPosition : SCNVector3 = SCNVector3Make(0.0, 0.0, 0.0)
   var translationFromStartToUpdatedPenPosition = simd_quatf()
   var updatesSincePressed = 0
   var selected : Bool = false
   var firstSelection : Bool = false

   //Variables For USER STUDY TASK
   var randomScaleFactor : Float = 0.0

   //variables for measuring
   var selectionCounter = 0
   var scaleDifferenceBetweenBoxAndModel : Float = 0.0
   var scaleDifferenceBetweenBoxAndModelEnd : Float = 0.0
   var amountBoxWasScaled : Float = 0.0
   var amountPenWasScaled: Float = 0.0

   var startTime : Date = Date()
   var endTime : Date = Date()
   var elapsedTime: Double = 0.0

   var userStudyReps = 0

   var studyData : [String:String] = [:]

   var rotationTime: Float = 0

   func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]){
   guard let scene = self.currentScene else {return}
   guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
     print("not found")
     return
   }
   guard let model = scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false) else{
     print("not found")
     return
   }
   
   guard let sceneView = self.currentView else { return }
   //let checked = buttons[Button.checkButton]!
   // let undo = buttons[Button.undoButton]!

   let pressed = buttons[Button.Button1]!
   if(selected == true){
       if pressed{
           
       penPosition = scene.pencilPoint.position
       print("penPosition\(penPosition)")

       let scaleFactor = abs(penPosition.y)
       print("scaleFactor: \(scaleFactor)")
       box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
       
       }
       
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
               if selected == false{
                   selected = true
                   hit.node.opacity = 0.9
               }
               else if selected == true{
                   selected = false
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
           
           self.selected = false
           
           self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
           self.currentView?.addGestureRecognizer(tapGesture!)
           self.currentView?.isUserInteractionEnabled = true
           print ("tapGesture: \(String(describing: tapGesture))")
           
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
           boxNode.pivot = SCNMatrix4MakeTranslation(-0.5, 0.5, -0.5)
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
               boxNode.position = SCNVector3(0, 0, -0.25)
               boxNode.name = "currentBoxNode"
               scene.drawingNode.addChildNode(boxNode)
               boxNode.opacity = 0.8
               //boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
               
           }
           else{
               boxNode.position = SCNVector3(0, 0, -0.25)
           }

           //create Object as model
           if boxModel != scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
               boxModel.position = SCNVector3(0, 0, -0.25)
               boxModel.name = "modelBoxNode"
               boxModel.opacity = 0.65
               //boxNode.geometry?.materials = [greenMaterial,  redMaterial,    blueMaterial,yellowMaterial, purpleMaterial, whiteMaterial];
               //boxModel.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
               boxModel.scale = SCNVector3(x: randomScaleFactor, y: randomScaleFactor, z: randomScaleFactor)
               scene.drawingNode.addChildNode(boxModel)
           }
           else{
               boxModel.position = SCNVector3(0, 0, -0.25)
           }

           //scaleDifference = abs(boxNode.scale.x - randomScaleFactor)
          // print("scaleDifference \(scaleDifference)")

           
       }
       
       
       func deactivatePlugin() {
           if let boxNode = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
               boxNode.removeFromParentNode()
           }

           if let boxModel = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
               boxModel.removeFromParentNode()
           }

           self.currentScene = nil

           if let tapGestureRecognizer = self.tapGesture{
               self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
           }

           self.currentView = nil
       }
       
   }


