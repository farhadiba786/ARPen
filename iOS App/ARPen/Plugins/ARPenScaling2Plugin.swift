//
//  ARPenScaling2Plugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 03.05.20.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class ARPenScaling2Plugin: Plugin,UserStudyRecordPluginProtocol {

//reference to userStudyRecordManager to add new records
var recordManager: UserStudyRecordManager!
var pluginImage: UIImage? = UIImage.init(named: "ARPenScaling2")
var pluginIdentifier: String = "ARPenScaling2"
var pluginInstructionsImage: UIImage?
var needsBluetoothARPen: Bool = false
var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
var currentView : ARSCNView?
var currentScene : PenScene?

var originalScale : SCNVector3 = SCNVector3Make(0.1, 0.1, 0.1)
var startPenPosition : SCNVector3 = SCNVector3Make(0.0, 0.0, 0.0)
var updatedPenPosition : SCNVector3 = SCNVector3Make(0.0, 0.0, 0.0)
var updates : [SCNVector3] = []
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
if pressed{
    //"activate" box while buttons is pressed and select it therefore
    //project point onto image plane and see if geometry is behind it via hittest
    let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
    var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )

    for hit in hitResults{
        if hit.node == box{
            if selected == false{
                selected = true
          
                hit.node.opacity = 0.95
          
                selectionCounter = selectionCounter + 1
                if selectionCounter == 1{
                  startTime = Date()
                  amountPenWasScaled = 0.0
                }
                //used for checkButton so it cannot be pressed twice in a row on accident
                firstSelection = true
            }
        }
        else{
            if let index = hitResults.firstIndex(of: hit) {
                hitResults.remove(at: index)
            }
        }
    }
    //if just pressed, initialize PenPosition
    if updatesSincePressed == 0 {
        startPenPosition = scene.pencilPoint.position
        print("startPenPosition\(startPenPosition)")
        updates.append(startPenPosition)
    }
    updatesSincePressed += 1
    
    //queue um updated position zu speichern oder irgendeien satenstruktur um immer nur zwei zu speichern
    
    updatedPenPosition = scene.pencilPoint.position
    print("updatePenPosition\(updatedPenPosition)")
   
    if selected == true {

            let scaleY = (abs(updatedPenPosition.y))
            print("scale: \(scaleY)")
            
            box.scale = SCNVector3(x: scaleY, y: scaleY, z: scaleY)
            }
            
    
}
else{
  selected = false
  box.opacity = 0.8
  updatesSincePressed = 0
  
  //if task is ended at this point the left amount of degrees between the objects is recorded
  
  //in case task is ended at this point record endTime
  endTime = Date()
}

}

func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
      
      self.currentScene = scene
      self.currentView = view
      
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
          boxModel.opacity = 0.5
          //boxNode.geometry?.materials = [greenMaterial,  redMaterial,    blueMaterial,yellowMaterial, purpleMaterial, whiteMaterial];
          //boxModel.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
          boxModel.scale = SCNVector3(x: randomScaleFactor, y: randomScaleFactor, z: randomScaleFactor)
          scene.drawingNode.addChildNode(boxModel)
      }
      else{
          boxModel.position = SCNVector3(0, 0, -0.25)
      }

      print ("childnodes\(scene.drawingNode.childNodes)")
      
  }

func deactivatePlugin() {
if let boxNode = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
       boxNode.removeFromParentNode()
   }
          
   if let boxModel = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
      boxModel.removeFromParentNode()
   }

self.currentScene = nil
self.currentView = nil
}
}

