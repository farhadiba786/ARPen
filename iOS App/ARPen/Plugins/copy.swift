//
//  PinchScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 14.07.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class Copy: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    var pluginImage : UIImage? = UIImage.init(named: "PinchScalingPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "PinchScalingPlugin")
    var pluginIdentifier: String = "copy"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView:  UILabel?

    //Gesture Recognizer
    var pinchGesture: UIPinchGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    var currentPoint = CGPoint()

    //Variables for bounding Box updates
    var centerPosition = SCNVector3()
    var updatedWidth : CGFloat = 0
    var updatedHeight : CGFloat = 0
    var updatedLength : CGFloat = 0
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))

    //Variables to ensure only one Corner an be selected at a time
    var selected : Bool = false
    var tapped1 : Bool = false
    var tapped2 : Bool = false
    var tapped3 : Bool = false
    var tapped4 : Bool = false
    var tapped5 : Bool = false
    var tapped6 : Bool = false
    var tapped7 : Bool = false
    var tapped8 : Bool = false

    //Variables For USER STUDY TASK
    var userStudyReps = 0

    //variables for initial bounding Box
    var originalWidth : CGFloat = 0
    var originalHeight : CGFloat = 0
    var originalLength : CGFloat = 0

    //variables for measuring
    var finalWidth : CGFloat = 0
    var finalHeight : CGFloat = 0
    var finalLength : CGFloat = 0
    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    var studyData : [String:String] = [:]
    

    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
            
    }
    
    //function for scaling object by pulling a corner
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
         print("not found")
         return
        }
        guard let r2d2 = scene.drawingNode.childNode(withName: "currentr2d2", recursively: false) else{
            print("not found")
            return
        }
         
        if selected == false{
            return
        }
        
        
        if (recognizer.state == .changed){
            //Project onto diagonal connecting lbd and rfh if one of the corners is selected
            //print ("recoginzer \(recognizer.scale)")
            let scaleFactor =  Float(recognizer.scale) * box.scale.x

            updatedHeight = originalHeight * CGFloat(scaleFactor)
            print("updatedHeight: \(updatedHeight)")
            updatedWidth = originalWidth * CGFloat(scaleFactor)
            print("updatedWidth: \(updatedWidth)")
            updatedLength = originalLength * CGFloat(scaleFactor)
            print("updatedlength: \(updatedLength)")

            if(tapped1){
                centerPosition = SCNVector3(x: corners.rfh.x - Float(updatedWidth/2), y: corners.rfh.y - Float(updatedHeight/2), z: corners.rfh.z - Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }
            else if(tapped8){
                centerPosition = SCNVector3(x: corners.lbd.x + Float(updatedWidth/2), y: corners.lbd.y + Float(updatedHeight/2), z: corners.lbd.z + Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }

            if(tapped2){
                centerPosition = SCNVector3(x: corners.rbh.x - Float(updatedWidth/2), y: corners.rbh.y - Float(updatedHeight/2), z: corners.rbh.z + Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }
            else if(tapped7){
                centerPosition = SCNVector3(x: corners.lfd.x + Float(updatedWidth/2), y: corners.lfd.y + Float(updatedHeight/2), z: corners.lfd.z - Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }

            if(tapped3){
                centerPosition = SCNVector3(x: corners.lfh.x + Float(updatedWidth/2), y: corners.lfh.y - Float(updatedHeight/2), z: corners.lfh.z - Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }
            else if(tapped6){
                centerPosition = SCNVector3(x: corners.rbd.x - Float(updatedWidth/2), y: corners.rbd.y + Float(updatedHeight/2), z: corners.rbd.z + Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }

            if(tapped4){
                centerPosition = SCNVector3(x: corners.lbh.x + Float(updatedWidth/2), y: corners.lbh.y - Float(updatedHeight/2), z: corners.lbh.z + Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
            r2d2.position = centerPosition
            }
            else if(tapped5){
                centerPosition = SCNVector3(x: corners.rfd.x - Float(updatedWidth/2), y: corners.rfd.y + Float(updatedHeight/2), z: corners.rfd.z - Float(updatedLength/2))
                box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                r2d2.position = centerPosition
            }

            //update Corners
            setCorners()
            setSpherePosition()
             
            recognizer.scale=1
        }
    }
    
    //function for selecting objects via touchscreen
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
            print("not found")
            return
        }
        guard let corner1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let corner8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let r2d2 = scene.drawingNode.childNode(withName: "currentr2d2", recursively: false) else{
            print("not found")
            return
        }
        
        let touchPoint = sender.location(in: sceneView)

        var hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        
        //Selecting a corner will select the box
        for hit in hitResults{
            //select:lbd --> pivot:rfh
            if hit.node == corner1 {
                if selected == false{
                    print("1centerPosition:\(centerPosition)")
                    print("1updatedHeight: \(updatedHeight)")
                    print("1updatedWidth: \(updatedWidth)")
                    print("1updatedLength: \(updatedLength)")
                    print("1cornersMethod: \(corners)")
                    
                    selected = true
                    tapped1 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(abs(corners.rfh.x - centerPosition.x)), Float(abs(corners.rfh.y - centerPosition.y)), Float(abs(corners.rfh.z - centerPosition.z)))
                    box.position = corners.rfh
                    
                    print("pivot1: \(box.pivot)")
                    print("position1: \(box.position)")
                }
                else if selected == true && tapped1{
                    tapped1 = false
                    selected = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    print("pivot1: \(box.pivot)")
                    print("position1: \(box.position)")
                    return
                }
            }
            //select:lfd --> pivot:rbh
            else if hit.node == corner2{
                if selected == false{
                    print("2centerPosition:\(centerPosition)")
                    print("2updatedHeight: \(updatedHeight)")
                    print("2updatedWidth: \(updatedWidth)")
                    print("2updatedLength: \(updatedLength)")
                    print("2cornersMethod: \(corners)")
                    
                    selected = true
                    tapped2 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbh.x-centerPosition.x), Float(corners.rbh.y-centerPosition.y), Float(corners.rbh.z-centerPosition.z))
                    box.position = corners.rbh
                    
                    print("pivot2: \(box.pivot)")
                    print("position2: \(box.position)")
                }
                else if selected == true && tapped2{
                    selected = false
                    tapped2 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    print("pivot2: \(box.pivot)")
                    print("position2: \(box.position)")
                    return
                }
            }
            //select:rbd --> pivot:lfh
            else if hit.node == corner3 {
                if selected == false{
                    print("3centerPosition:\(centerPosition)")
                    print("3updatedHeight: \(updatedHeight)")
                    print("3updatedWidth: \(updatedWidth)")
                    print("3updatedLength: \(updatedLength)")
                    print("3cornersMethod: \(corners)")
                    
                    selected = true
                    tapped3 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfh.x + centerPosition.x), Float( corners.lfh.y - centerPosition.y), Float(corners.lfh.z - centerPosition.z))
                    box.position = corners.lfh
                    print("3pivot: \(box.pivot)")
                    print("3position: \(box.position)")
                }
                else if selected == true && tapped3{
                    selected = false
                    tapped3 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    return
                    //print("3pivot: \(box.pivot)")
                    //print("3position: \(box.position)")
                }
            }
            //select:rfd --> pivot:lbh
            else if hit.node == corner4 {
                if selected == false{

                    print("4centerPosition:\(centerPosition)")
                    print("4updatedHeight: \(updatedHeight)")
                    print("4updatedWidth: \(updatedWidth)")
                    print("4updatedLength: \(updatedLength)")
                    print("4cornersMethod: \(corners)")
                    selected = true
                    tapped4 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbh.x-centerPosition.x), Float(corners.lbh.y-centerPosition.y), Float(corners.lbh.z-centerPosition.z))
                    box.position = corners.lbh
                    
                    print("4pivot: \(box.pivot)")
                    print("4position: \(box.position)")
                }
                else if selected == true && tapped4{
                    selected = false
                    tapped4 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("4pivot: \(box.pivot)")
                    //print("4position: \(box.position)")
                    return
                }
            }
            //select:lbh --> pivot:rfd
            else if hit.node == corner5{
                if selected == false{

                    print("5centerPosition:\(centerPosition)")
                    print("5updatedHeight: \(updatedHeight)")
                    print("5updatedWidth: \(updatedWidth)")
                    print("5updatedLength: \(updatedLength)")
                    print("5cornersMethod: \(corners)")
                    selected = true
                    tapped5 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.rfd.x-centerPosition.x), Float(corners.rfd.y-centerPosition.y), Float(corners.rfd.z-centerPosition.z))
                    box.position = corners.rfd
                    
                    print("5pivot: \(box.pivot)")
                    print("5position: \(box.position)")
                }
                else if selected == true && tapped5{
                    selected = false
                    tapped5 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("5pivot: \(box.pivot)")
                    //print("5position: \(box.position)")
                    return
                }
            }
            //select:lfh --> pivot:rbd
            else if hit.node == corner6{
                if selected == false{

                    print("6centerPosition:\(centerPosition)")
                    print("6updatedHeight: \(updatedHeight)")
                    print("6updatedWidth: \(updatedWidth)")
                    print("6updatedLength: \(updatedLength)")
                    print("6cornersMethod: \(corners)")
                    
                    selected = true
                    tapped6 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), -Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbd.x-centerPosition.x), Float(corners.rbd.y-centerPosition.y), Float(corners.rbd.z-centerPosition.z))
                    box.position = corners.rbd
                    
                    print("6pivot: \(box.pivot)")
                    print("6position: \(box.position)")
                }
                else if selected == true  && tapped6{
                    selected = false
                    tapped6 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("6pivot: \(box.pivot)")
                    //print("6position: \(box.position)")
                    return
                }
            }
            //select:rbh --> pivot:lfd
            else if hit.node == corner7 {
                if selected == false{
                    print("7centerPosition:\(centerPosition)")
                    print("7updatedHeight: \(updatedHeight)")
                    print("7updatedWidth: \(updatedWidth)")
                    print("7updatedLength: \(updatedLength)")
                    print("7cornersMethod: \(corners)")
                    
                    selected = true
                    tapped7 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfd.x-centerPosition.x), Float(corners.lfd.y-centerPosition.y), Float(corners.lfd.z-centerPosition.z))
                    box.position = corners.lfd
                    
                    print("7pivot: \(box.pivot)")
                    print("7position: \(box.position)")
                }
                else if selected == true && tapped7{
                    selected = false
                    tapped7 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("7pivot: \(box.pivot)")
                    //print("7position: \(box.position)")
                    return
                }
            }
            //select:rfh --> pivot:lbd
            else if hit.node == corner8 {
                if selected == false{
                    print("8centerPosition:\(centerPosition)")
                    print("8updatedHeight: \(updatedHeight)")
                    print("8updatedWidth: \(updatedWidth)")
                    print("8updatedLength: \(updatedLength)")
                    print("8cornersMethod: \(corners)")
                    
                    selected = true
                    tapped8 = true
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                    box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                    //box.pivot = SCNMatrix4MakeTranslation(-Float(0.5*updatedWidth), -Float(0.5*updatedHeight), -Float(0.5*updatedLength))
                    box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbd.x-centerPosition.x), Float(corners.lbd.y-centerPosition.y), Float(corners.lbd.z-centerPosition.z))
                    box.position = corners.lbd
                    
                    print("8pivot: \(box.pivot)")
                    print("8position: \(box.position)")
                }
                else if selected == true && tapped8{
                    selected = false
                    tapped8 = false
                    hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("8pivot: \(box.pivot)")
                    //print("8position: \(box.position)")
                    return
                }
            }
            //only select the corners
            else{
                if let index = hitResults.firstIndex(of: hit) {
                    hitResults.remove(at: index)
                }
            }
        }
    }
    
    //need to adjust the corners while scaling visually
    func setSpherePosition(){
        guard let scene = self.currentScene else {return}
        guard let sphere1 = scene.drawingNode.childNode(withName: "lbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere2 = scene.drawingNode.childNode(withName: "lfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere3 = scene.drawingNode.childNode(withName: "rbdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere4 = scene.drawingNode.childNode(withName: "rfdCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere5 = scene.drawingNode.childNode(withName: "lbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere6 = scene.drawingNode.childNode(withName: "lfhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere7 = scene.drawingNode.childNode(withName: "rbhCorner", recursively: false) else{
            print("not found")
            return
        }
        guard let sphere8 = scene.drawingNode.childNode(withName: "rfhCorner", recursively: false) else{
            print("not found")
            return
        }
        
        sphere1.position = corners.lbd
        sphere2.position = corners.lfd
        sphere3.position = corners.rbd
        sphere4.position = corners.rfd
        sphere5.position = corners.lbh
        sphere6.position = corners.lfh
        sphere7.position = corners.rbh
        sphere8.position = corners.rfh
    }
    
    func setCorners() {
        let thePosition = centerPosition
        let halfWidth = Float(updatedWidth/2)
        let halfHeight = Float(updatedHeight/2)
        let halfLength = Float(updatedLength/2)

        self.corners.lbd = SCNVector3Make(thePosition.x - halfWidth, thePosition.y - halfHeight, thePosition.z - halfLength)
        self.corners.lfd = SCNVector3Make(thePosition.x - halfWidth, thePosition.y - halfHeight, thePosition.z + halfLength)
        self.corners.rbd = SCNVector3Make(thePosition.x + halfWidth, thePosition.y - halfHeight, thePosition.z - halfLength)
        self.corners.rfd = SCNVector3Make(thePosition.x + halfWidth, thePosition.y - halfHeight, thePosition.z + halfLength)
        self.corners.lbh = SCNVector3Make(thePosition.x - halfWidth, thePosition.y + halfHeight, thePosition.z - halfLength)
        self.corners.lfh = SCNVector3Make(thePosition.x - halfWidth, thePosition.y + halfHeight, thePosition.z + halfLength)
        self.corners.rbh = SCNVector3Make(thePosition.x + halfWidth, thePosition.y + halfHeight, thePosition.z - halfLength)
        self.corners.rfh = SCNVector3Make(thePosition.x + halfWidth, thePosition.y + halfHeight, thePosition.z + halfLength)
    }
     
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        
        self.currentScene = scene
        self.currentView = view
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        print ("tapGesture: \(String(describing: tapGesture))")
        
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        self.currentView?.addGestureRecognizer(pinchGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        //define r2d2
        let starwars = SCNScene(named: "art.scnassets/R2D2/r2d2Center.dae")
        let r2d2Node = starwars?.rootNode.childNode(withName: "Merged_Meshes", recursively: true)
        let r2d2 = r2d2Node!
        r2d2.scale = SCNVector3(0.001,0.001,0.001)
        
        //Define boundingBox
        let boundingBoxCorners = r2d2Node!.boundingBox
        let OriginalMinCorner = boundingBoxCorners.0
        let OriginalMaxCorner = boundingBoxCorners.1
        let minCorner = SCNVector3(x:OriginalMinCorner.x*0.001,y:OriginalMinCorner.y*0.001,z:OriginalMinCorner.z*0.001)
        let maxCorner = SCNVector3(x:OriginalMaxCorner.x*0.001,y:OriginalMaxCorner.y*0.001,z:OriginalMaxCorner.z*0.001)
        //print("maxCorner\(maxCorner)")
        //print("minCorner\(minCorner)")

        let sm = "float u = _surface.diffuseTexcoord.x; \n" +
                 "float v = _surface.diffuseTexcoord.y; \n" +
                 "int u100 = int(u * 100); \n" +
                 "int v100 = int(v * 100); \n" +
                 "if (u100 % 99 == 0 || v100 % 99 == 0) { \n" +
                 "  // do nothing \n" +
                 "} else { \n" +
                 "    discard_fragment(); \n" +
                 "} \n"
        
        originalWidth = CGFloat(maxCorner.x - minCorner.x)
        originalHeight = CGFloat(maxCorner.z - minCorner.z)
        originalLength = CGFloat(maxCorner.y - minCorner.y)
        //print("width: \(originalWidth)")
        //print("height: \(originalHeight)")
        //print("length: \(originalLength)")
        
        self.updatedWidth = originalWidth
        self.updatedHeight = originalHeight
        self.updatedLength = originalLength
        
        let box = SCNBox(width: originalWidth, height: originalHeight, length: originalLength, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents  = UIColor.systemBlue
        box.firstMaterial?.emission.contents = UIColor.systemBlue
        box.firstMaterial?.shaderModifiers = [SCNShaderModifierEntryPoint.surface: sm]
        box.firstMaterial?.isDoubleSided = true
        let boundingBox = SCNNode(geometry: box)
        
        if boundingBox != scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.position = SCNVector3(0,0,-0.3)
            centerPosition = boundingBox.position
            print("position:\(boundingBox.position)")
            boundingBox.name = "currentBoundingBox"
            boundingBox.opacity = 0.6
            scene.drawingNode.addChildNode(boundingBox)
            }
        else{
            boundingBox.position = SCNVector3(0,0,-0.3)
            
        }
        
        setCorners()
        //print("corners: \(corners)")
        
        //Visualize corners for Selection
        let sphere1 = SCNNode()
        let sphere2 = SCNNode()
        let sphere3 = SCNNode()
        let sphere4 = SCNNode()
        let sphere5 = SCNNode()
        let sphere6 = SCNNode()
        let sphere7 = SCNNode()
        let sphere8 = SCNNode()
        
        if sphere1 != scene.drawingNode.childNode(withName: "lbdCorner", recursively: false){
            sphere1.position = corners.lbd
            sphere1.geometry = SCNSphere(radius: 0.008)
            sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere1.name = "lbdCorner"
            scene.drawingNode.addChildNode(sphere1)
            }
        else{
            sphere1.position = corners.lbd
        }
        
        if sphere2 != scene.drawingNode.childNode(withName: "lfdCorner", recursively: false){
            sphere2.position = corners.lfd
            sphere2.geometry = SCNSphere(radius: 0.008)
            sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere2.name = "lfdCorner"
            scene.drawingNode.addChildNode(sphere2)
            }
        else{
            sphere2.position = corners.lfd
        }
        
        if sphere3 != scene.drawingNode.childNode(withName: "rbdCorner", recursively: false){
            sphere3.position = corners.rbd
            sphere3.geometry = SCNSphere(radius: 0.008)
            sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere3.name = "rbdCorner"
            scene.drawingNode.addChildNode(sphere3)
            }
        else{
            sphere3.position = corners.rbd
        }
        
        if sphere4 != scene.drawingNode.childNode(withName: "rfdCorner", recursively: false){
            sphere4.position = corners.rfd
            sphere4.geometry = SCNSphere(radius: 0.008)
            sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere4.name = "rfdCorner"
            scene.drawingNode.addChildNode(sphere4)
            }
        else{
            sphere4.position = corners.rfd
        }
        
        if sphere5 != scene.drawingNode.childNode(withName: "lbhCorner", recursively: false){
            sphere5.position = corners.lbh
            sphere5.geometry = SCNSphere(radius: 0.008)
            sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere5.name = "lbhCorner"
            scene.drawingNode.addChildNode(sphere5)
            }
        else{
            sphere5.position = corners.lbh
        }
        
        if sphere6 != scene.drawingNode.childNode(withName: "lfhCorner", recursively: false){
            sphere6.position = corners.lfh
            sphere6.geometry = SCNSphere(radius: 0.008)
            sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere6.name = "lfhCorner"
            scene.drawingNode.addChildNode(sphere6)
            }
        else{
            sphere6.position = corners.lfh
        }
        
        if sphere7 != scene.drawingNode.childNode(withName: "rbhCorner", recursively: false){
            sphere7.position = corners.rbh
            sphere7.geometry = SCNSphere(radius: 0.008)
            sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere7.name = "rbhCorner"
            scene.drawingNode.addChildNode(sphere7)
            }
        else{
            sphere7.position = corners.rbh
        }
        
        if sphere8 != scene.drawingNode.childNode(withName: "rfhCorner", recursively: false){
            sphere8.position = corners.rfh
            sphere8.geometry = SCNSphere(radius: 0.008)
            sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere8.name = "rfhCorner"
            scene.drawingNode.addChildNode(sphere8)
            }
        else{
            sphere8.position = corners.rfh
        }
        
        //create Object to scale
               if r2d2 != scene.drawingNode.childNode(withName: "currentr2d2", recursively: false){
                   //r2d2.position = SCNVector3(-0.05+Float(width/2),-0.05,-0.3+Float(length/2))
                   r2d2.position = centerPosition
                   r2d2.name = "currentr2d2"
                   //r2d2.pivot = SCNMatrix4MakeTranslation(-Float(width/2),0,-Float(length/2))
                   scene.drawingNode.addChildNode(r2d2)
                   r2d2.opacity = 1.0
                   
               }
               else{
                   r2d2.position = centerPosition
               }
        
        
    }
    
    
    func deactivatePlugin() {
        if let boundingBox = currentScene?.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.removeFromParentNode()
        }
        if let sphere1 = currentScene?.drawingNode.childNode(withName: "lbdCorner", recursively: false){
            sphere1.removeFromParentNode()
        }
        if let sphere2 = currentScene?.drawingNode.childNode(withName: "lfdCorner", recursively: false){
            sphere2.removeFromParentNode()
        }
        if let sphere3 = currentScene?.drawingNode.childNode(withName: "rbdCorner", recursively: false){
            sphere3.removeFromParentNode()
        }
        if let sphere4 = currentScene?.drawingNode.childNode(withName: "rfdCorner", recursively: false){
            sphere4.removeFromParentNode()
        }
        if let sphere5 = currentScene?.drawingNode.childNode(withName: "lbhCorner", recursively: false){
            sphere5.removeFromParentNode()
        }
        if let sphere6 = currentScene?.drawingNode.childNode(withName: "lfhCorner", recursively: false){
            sphere6.removeFromParentNode()
        }
        if let sphere7 = currentScene?.drawingNode.childNode(withName: "rbhCorner", recursively: false){
            sphere7.removeFromParentNode()
        }
        if let sphere8 = currentScene?.drawingNode.childNode(withName: "rfhCorner", recursively: false){
            sphere8.removeFromParentNode()
        }
        
        if let r2d2 = currentScene?.drawingNode.childNode(withName: "currentr2d2", recursively: false){
            r2d2.removeFromParentNode()
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




