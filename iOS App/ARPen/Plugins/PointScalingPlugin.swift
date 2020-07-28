//
//  PointScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 24.07.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class PointScalingPlugin: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    var pluginImage : UIImage? = UIImage.init(named: "PointScalingPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "PointScalingPlugin")
    var pluginIdentifier: String = "PointScaling"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView:  UILabel?

    var buttonPressedBefore: Bool = false
    var pressCounter = 0
    var firstPoint = SCNVector3()
    var secondPoint = SCNVector3()
    private var selectedCorner = SCNVector3()

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
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
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
        let pressed = buttons[Button.Button1]!
        //first button press selects corner
        if pressCounter == 0{
            if pressed{
                let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
                var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                
                //Selecting a corner will select the box
                for hit in hitResults{
                    if !selected{
                        //select:lbd
                        if hit.node == corner1 {
                            selected = true
                            tapped1 = true
                            selectedCorner = corners.lbd
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:lfd
                        else if hit.node == corner2{
                            selected = true
                            tapped2 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:rbd
                        else if hit.node == corner3{
                            selected = true
                            tapped3 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:rfd
                        else if hit.node == corner4{
                            selected = true
                            tapped4 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:lbh
                        else if hit.node == corner5{
                            selected = true
                            tapped5 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:lfh
                        else if hit.node == corner6{
                            selected = true
                            tapped6 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:rbh
                        else if hit.node == corner7{
                            selected = true
                            tapped7 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //select:rfh
                        else if hit.node == corner8{
                            selected = true
                            tapped8 = true
                            hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                        }
                        //only select the corners
                        else{
                            if let index = hitResults.firstIndex(of: hit) {
                                hitResults.remove(at: index)
                            }
                        }
                    }
                }
            }
            //Need to release button to complete selection, to enable a deselection through button press
            if !pressed && selected{
                pressCounter += 1
            }
        }
        if pressCounter > 0{
            if pressed{
                let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
                var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                
                // Deselection of Corner
                for hit in hitResults{
                    //select:lbd
                    if hit.node == corner1 && tapped1{
                        selected = false
                        tapped1 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:lfd
                    else if hit.node == corner2 && tapped2{
                        selected = false
                        tapped2 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:rbd
                    else if hit.node == corner3 && tapped3{
                        selected = false
                        tapped3 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:rfd
                    else if hit.node == corner4 && tapped4{
                        selected = false
                        tapped4 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:lbh
                    else if hit.node == corner5 && tapped5{
                        selected = false
                        tapped5 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:lfh
                    else if hit.node == corner6 && tapped6{
                        selected = false
                        tapped6 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:rbh
                    else if hit.node == corner7 && tapped7{
                        selected = false
                        tapped7 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //select:rfh
                    else if hit.node == corner8 && tapped8{
                        selected = false
                        tapped8 = false
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    }
                    //only select the corners
                    else{
                        if let index = hitResults.firstIndex(of: hit) {
                            hitResults.remove(at: index)
                        }
                    }
                }
                
                //Marking new Corner Points
                if selected{
                    //only first button press determines new corner position
                    if pressCounter == 1 && !buttonPressedBefore{
                        firstPoint = scene.pencilPoint.position
                        print("firstPoint: \(firstPoint)")
                        buttonPressedBefore = true
                        
                       //Visualize corners for Selection
                       let marker1 = SCNNode()
                       if marker1 != scene.drawingNode.childNode(withName: "firstPointMarker", recursively: false){
                           marker1.position = firstPoint
                           marker1.geometry = SCNSphere(radius: 0.004)
                           marker1.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                           marker1.name = "firstPointMarker"
                           scene.drawingNode.addChildNode(marker1)
                           }
                       else{
                           marker1.position = firstPoint
                       }
                    }
                }
            }
            //Need to release button to complete deselection
            if !pressed && !selected{
                pressCounter = 0
            }
            //Need to release button before marking second point
            if !pressed && buttonPressedBefore{
                pressCounter += 1
                buttonPressedBefore = false
            }
            if pressed && pressCounter == 2{
                secondPoint = scene.pencilPoint.position
                if let marker1 = currentScene?.drawingNode.childNode(withName: "firstPointMarker", recursively: false){
                    marker1.removeFromParentNode()
                }

                print("SecondPoint: \(secondPoint)")
                // Determine scale
                let absX = abs(firstPoint.x - secondPoint.x)
                print("absX: \(absX)")
                let absY = abs(firstPoint.y - secondPoint.y)
                print("absY: \(absY)")
                let absZ = abs(firstPoint.z - secondPoint.z)
                print("absZ: \(absZ)")
                
                //width
                if (absX >= absY && absX >= absZ){
                    //line drawn from left to right
                    updatedWidth = CGFloat(absX)
                    let scaleFactor = Float(updatedWidth/originalWidth)
                    updatedHeight = originalHeight * CGFloat(scaleFactor)
                    updatedLength = originalLength * CGFloat(scaleFactor)
                    
                    //lbd
                    if(tapped1){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfd
                    else if (tapped2){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbd
                    else if (tapped3){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfd
                    else if (tapped4){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //lbh
                    else if (tapped5){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfh
                    else if (tapped6){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbh
                    else if (tapped7){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfh
                    else if (tapped8){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    
                    setCorners()
                    setSpherePosition()
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    r2d2.position = centerPosition
                    box.position = centerPosition
                }
                else if (absY >= absZ && absY >= absX){
                    //line drawn from left to right
                    updatedHeight = CGFloat(absY)
                    let scaleFactor = Float(updatedHeight/originalHeight)
                    updatedWidth = originalWidth * CGFloat(scaleFactor)
                    updatedLength = originalLength * CGFloat(scaleFactor)
                
                    //lbd
                    if(tapped1){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfd
                    else if (tapped2){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbd
                    else if (tapped3){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfd
                    else if (tapped4){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //lbh
                    else if (tapped5){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfh
                    else if (tapped6){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbh
                    else if (tapped7){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfh
                    else if (tapped8){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                
                    setCorners()
                    setSpherePosition()
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    r2d2.position = centerPosition
                    box.position = centerPosition
                    box.position = centerPosition
                }
                else if (absZ >= absX && absZ >= absY ){
                    //line drawn from left to right
                    updatedLength = CGFloat(absZ)
                    let scaleFactor = Float(updatedLength/originalLength)
                    updatedHeight = originalHeight * CGFloat(scaleFactor)
                    updatedWidth = originalWidth * CGFloat(scaleFactor)
                        
                    //lbd
                    if(tapped1){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfd
                    else if (tapped2){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbd
                    else if (tapped3){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfd
                    else if (tapped4){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y + Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //lbh
                    else if (tapped5){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //lfh
                    else if (tapped6){
                        centerPosition = SCNVector3(x: firstPoint.x + Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    //rbh
                    else if (tapped7){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z + Float(updatedLength/2))
                    }
                    //rfh
                    else if (tapped8){
                        centerPosition = SCNVector3(x: firstPoint.x - Float(updatedWidth/2), y: firstPoint.y - Float(updatedHeight/2), z: firstPoint.z - Float(updatedLength/2))
                    }
                    
                    setCorners()
                    setSpherePosition()
                    
                    box.scale = SCNVector3(x:scaleFactor, y:scaleFactor, z:scaleFactor)
                    r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                    r2d2.position = centerPosition
                    box.position = centerPosition
                    box.position = centerPosition
                }
                print("updatedHeight: \(updatedHeight)")
                print("updatedWidth: \(updatedWidth)")
                print("updatedLength: \(updatedLength)")
                print (corners)
                pressCounter += 1
            }
            if !pressed && pressCounter>2 {
                pressCounter = 1
            }
        }
    }
     
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        
        self.currentScene = scene
        self.currentView = view
        
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
        box.firstMaterial?.diffuse.contents  = UIColor.systemGray
        box.firstMaterial?.emission.contents = UIColor.yellow
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

        self.currentView = nil
    }
    
}



