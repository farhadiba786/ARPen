//
//  ScrollScalingPlugin.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 14.07.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class ScrollScalingPlugin: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    var pluginImage : UIImage? = UIImage.init(named: "ScrollScalingPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "ScrollScalingPlugin")
    var pluginIdentifier: String = "Scrolling"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView:  UILabel?

    //Gesture Recognizer
    var panGesture: UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    var currentPoint = CGPoint()

    //Variables for bounding Box updates
    var centerPosition = SCNVector3()
    var updatedWidth : CGFloat = 0
    var updatedHeight : CGFloat = 0
    var updatedLength : CGFloat = 0
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))
    
    var screenCorners : (lbd : CGPoint, lfd : CGPoint, rbd : CGPoint, rfd : CGPoint, lbh : CGPoint, lfh : CGPoint, rbh : CGPoint, rfh : CGPoint) = (CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0))

    //Variables to ensure only one Corner an be selected at a time
    var selectedCorner = SCNNode()
    var selected : Bool = false
    var tapped1 : Bool = false
    var tapped2 : Bool = false
    var tapped3 : Bool = false
    var tapped4 : Bool = false
    var tapped5 : Bool = false
    var tapped6 : Bool = false
    var tapped7 : Bool = false
    var tapped8 : Bool = false

    //Corner Variables for diagonals
    var next_rfh = SCNVector3()
    var next_lbd = SCNVector3()
    var next_lfh = SCNVector3()
    var next_rbd = SCNVector3()
    var next_rbh = SCNVector3()
    var next_lfd = SCNVector3()
    var next_lbh = SCNVector3()
    var next_rfd = SCNVector3()
    var dirVector1 = CGPoint()
    var dirVector2 = CGPoint()
    var dirVector3 = CGPoint()
    var dirVector4 = CGPoint()

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
        
        setScreenCorners()
        //define initial diagonals
        dirVector1 = CGPoint(x: screenCorners.lbd.x - screenCorners.rfh.x, y: screenCorners.lbd.y - screenCorners.rfh.y)
        dirVector2 = CGPoint(x: screenCorners.rbd.x - screenCorners.lfh.x, y: screenCorners.rbd.y - screenCorners.lfh.y)
        dirVector3 = CGPoint(x: screenCorners.lfd.x - screenCorners.rbh.x, y: screenCorners.lfd.y - screenCorners.rbh.y)
        dirVector4 = CGPoint(x: screenCorners.rfd.x - screenCorners.lbh.x, y: screenCorners.rfd.y - screenCorners.lbh.y)
            
    }
    
    func dotProduct(vecA: CGPoint, vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y )
    }

    //function for scaling object by pulling a corner
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let box = scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false) else{
         print("not found")
         return
        }
        guard let line1 = scene.drawingNode.childNode(withName: "diagonal1", recursively: false) else{
            print("not found")
            return
        }
        guard let line2 = scene.drawingNode.childNode(withName: "diagonal2", recursively: false) else{
            print("not found")
            return
        }
        guard let line3 = scene.drawingNode.childNode(withName: "diagonal3", recursively: false) else{
            print("not found")
            return
        }
        guard let line4 = scene.drawingNode.childNode(withName: "diagonal4", recursively: false) else{
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
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        if recognizer.state == .began {
            let touchPoint = recognizer.location(in: sceneView)
            print("currentpoint: \(touchPoint)")

            var hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            //Selecting a corner will select the box
            for hit in hitResults{
                //select:lbd --> pivot:rfh
                if hit.node == corner1 {
                    if selected == false{
                        print("pivotStart: \(box.pivot)")
                        print("1centerPosition:\(centerPosition)")
                        print("1updatedHeight: \(updatedHeight)")
                        print("1updatedWidth: \(updatedWidth)")
                        print("1updatedLength: \(updatedLength)")
                        print("1cornersMethod: \(corners)")
                        
                        selectedCorner = corner1
                        selected = true
                        tapped1 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(abs(corners.rfh.x - centerPosition.x)), Float(abs(corners.rfh.y - centerPosition.y)), Float(abs(corners.rfh.z - centerPosition.z)))
                        print("pivotmitte: \(box.pivot)")
                        box.position = corners.rfh
                        

                        let worldPos = box.worldPosition
                        let worldTrans = box.worldTransform
                        print("worldPos: \(worldPos)")
                        print("worldTrans: \(worldTrans)")
                        print("pivotende: \(box.pivot)")
                        print("position1: \(box.position)")
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
                        
                        selectedCorner = corner2
                        selected = true
                        tapped2 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbh.x-centerPosition.x), Float(corners.rbh.y-centerPosition.y), Float(corners.rbh.z-centerPosition.z))
                        box.position = corners.rbh
                        
                        print("pivot2: \(box.pivot)")
                        print("position2: \(box.position)")
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
                        
                        selectedCorner = corner3
                        selected = true
                        tapped3 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfh.x + centerPosition.x), Float( corners.lfh.y - centerPosition.y), Float(corners.lfh.z - centerPosition.z))
                        box.position = corners.lfh
                        
                        print("3pivot: \(box.pivot)")
                        print("3position: \(box.position)")
                    }
                }
                //select:rfd --> pivot:lbh
                else if hit.node == corner4 {
                    if selected == false{
                        
                        /*print("4centerPosition:\(centerPosition)")
                        print("4updatedHeight: \(updatedHeight)")
                        print("4updatedWidth: \(updatedWidth)")
                        print("4updatedLength: \(updatedLength)")
                        print("4cornersMethod: \(corners)")*/
                        selectedCorner = corner4
                        selected = true
                        tapped4 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                        //print("41pivot: \(box.pivot)")
                        //box.pivot = SCNMatrix4MakeTranslation(0.1, 0.1, 0.1)
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbh.x-centerPosition.x), Float(corners.lbh.y-centerPosition.y), Float(corners.lbh.z-centerPosition.z))
                        box.position = corners.lbh
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
                        selectedCorner = corner5
                        selected = true
                        tapped5 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.rfd.x-centerPosition.x), Float(corners.rfd.y-centerPosition.y), Float(corners.rfd.z-centerPosition.z))
                        box.position = corners.rfd
                        
                        print("5pivot: \(box.pivot)")
                        print("5position: \(box.position)")
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
                        
                        selectedCorner = corner6
                        selected = true
                        tapped6 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), -Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbd.x-centerPosition.x), Float(corners.rbd.y-centerPosition.y), Float(corners.rbd.z-centerPosition.z))
                        box.position = corners.rbd
                        
                        print("6pivot: \(box.pivot)")
                        print("6position: \(box.position)")
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
                        
                        selectedCorner = corner7
                        selected = true
                        tapped7 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfd.x-centerPosition.x), Float(corners.lfd.y-centerPosition.y), Float(corners.lfd.z-centerPosition.z))
                        box.position = corners.lfd
                        
                        print("7pivot: \(box.pivot)")
                        print("7position: \(box.position)")
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
                        
                        selectedCorner = corner8
                        selected = true
                        tapped8 = true
                        hit.node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        colorEdges()
                        box.pivot = SCNMatrix4MakeTranslation(-Float(0.5*updatedWidth), -Float(0.5*updatedHeight), -Float(0.5*updatedLength))
                        //box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbd.x-centerPosition.x), Float(corners.lbd.y-centerPosition.y), Float(corners.lbd.z-centerPosition.z))
                        box.position = corners.lbd
                        
                        print("8pivot: \(box.pivot)")
                        print("8position: \(box.position)")
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

        if recognizer.state == .changed{
            self.currentPoint = recognizer.location(in: sceneView)
            //Project onto diagonal connecting lbd and rfh if one of the corners is selected
            if (tapped1 || tapped8){
                let vecA = CGPoint(x:currentPoint.x - screenCorners.rfh.x, y:currentPoint.y - screenCorners.rfh.y)
                let scalar1 = dotProduct(vecA: vecA , vecB: dirVector1)  / dotProduct(vecA: dirVector1, vecB: dirVector1)
                let scaledDirVec = CGPoint(x: dirVector1.x * scalar1, y: dirVector1.y * scalar1)
                let projectedPoint1 = CGPoint(x: screenCorners.rfh.x + scaledDirVec.x, y: screenCorners.rfh.y + scaledDirVec.y)
                print("projection: \(projectedPoint1)")
                var hitTestResult = sceneView.hitTest(projectedPoint1, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                for hit in hitTestResult{
                        let currentPointInWC = hit.worldCoordinates
                        updatedHeight = CGFloat(abs(currentPointInWC.y - box.position.y))
                        let scaleFactor = Float(updatedHeight / originalHeight)
                        updatedWidth = originalWidth * CGFloat(scaleFactor)
                        updatedLength = originalLength * CGFloat(scaleFactor)

                        if(tapped1){
                            centerPosition = SCNVector3(x: corners.rfh.x - Float(updatedWidth/2), y: corners.rfh.y - Float(updatedHeight/2), z: corners.rfh.z - Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        else if(tapped8){
                            centerPosition = SCNVector3(x: corners.lbd.x + Float(updatedWidth/2), y: corners.lbd.y + Float(updatedHeight/2), z: corners.lbd.z + Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        //print("centerPosition: \(centerPosition)")
                        //update Corners
                        setCorners()
                        setSpherePosition()
                        removeAllEdges()
                        setEdges()
                        colorEdges()
                        
                        //update diagonals
                        if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                            line2.removeFromParentNode()
                        }
                        if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                            line3.removeFromParentNode()
                        }
                        if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                            line4.removeFromParentNode()
                        }
                        
                        let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                         next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                         next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                        
                        let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                         next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                         next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
                        
                        let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                         next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                         next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                        //diagonal from lfh to rbd
                        let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                            if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                            line2.name = "diagonal2"
                            scene.drawingNode.addChildNode(line2)
                        }
                        //diagonal from lfd to rbh
                        let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                            if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                            line3.name = "diagonal3"
                            scene.drawingNode.addChildNode(line3)
                        }
                        //diagonal from rfd to lbh
                        let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                            if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                            line4.name = "diagonal4"
                            scene.drawingNode.addChildNode(line4)
                        }
                        else{
                            if let index = hitTestResult.firstIndex(of: hit) {
                                hitTestResult.remove(at: index)
                            }
                        }

                    }
                }
            
                
            //Project onto diagonal connecting lfd and rbh if one of the corners is selected
            else if (tapped2 || tapped7){
                let vecA = CGPoint(x:currentPoint.x - screenCorners.rbh.x, y:currentPoint.y - screenCorners.rbh.y)
                let scalar3 = dotProduct(vecA: vecA , vecB: dirVector3)  / dotProduct(vecA: dirVector3, vecB: dirVector3)
                let scaledDirVec = CGPoint(x: dirVector3.x * scalar3, y: dirVector3.y * scalar3)
                let projectedPoint3 = CGPoint(x: screenCorners.rbh.x + scaledDirVec.x, y: screenCorners.rbh.y + scaledDirVec.y)
                print("projection: \(projectedPoint3)")
                var hitTestResult = sceneView.hitTest(projectedPoint3, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                for hit in hitTestResult{
                    if hit.node == line3{
                        let currentPointInWC = hit.worldCoordinates
                        updatedHeight = CGFloat(abs(currentPointInWC.y - box.position.y))
                        let scaleFactor = Float(updatedHeight / originalHeight)
                        updatedWidth = originalWidth * CGFloat(scaleFactor)
                        updatedLength = originalLength * CGFloat(scaleFactor)

                        if(tapped2){
                            centerPosition = SCNVector3(x: corners.rbh.x - Float(updatedWidth/2), y: corners.rbh.y - Float(updatedHeight/2), z: corners.rbh.z + Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        else if(tapped7){
                            centerPosition = SCNVector3(x: corners.lfd.x + Float(updatedWidth/2), y: corners.lfd.y + Float(updatedHeight/2), z: corners.lfd.z - Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        
                        //update Corners
                        setCorners()
                        setSpherePosition()
                        removeAllEdges()
                        setEdges()
                        colorEdges()
                        
                        //update diagonals
                        if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                            line2.removeFromParentNode()
                        }
                        if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                            line1.removeFromParentNode()
                        }
                        if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                            line4.removeFromParentNode()
                        }
                        
                        let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                         next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                         next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                        
                        let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                         next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                         next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                        
                        let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                         next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                         next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                        //diagonal from lfh to rbd
                        let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                            if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                 line2.name = "diagonal2"
                                 scene.drawingNode.addChildNode(line2)
                            }
                        //diagonal from lbd to rfh
                        let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                            if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                line1.name = "diagonal1"
                                scene.drawingNode.addChildNode(line1)
                            }
                        //diagonal from rfd to lbh
                        let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                            if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                                 line4.name = "diagonal4"
                                 scene.drawingNode.addChildNode(line4)
                            }
                    }
                    else{
                        if let index = hitTestResult.firstIndex(of: hit) {
                            hitTestResult.remove(at: index)
                        }
                    }
                }
            }
            //Project onto diagonal connecting rbd and lfh if one of the corners is selected
            else if (tapped3 || tapped6){
            let vecA = CGPoint(x:currentPoint.x - screenCorners.lfh.x, y:currentPoint.y - screenCorners.lfh.y)
            let scalar2 = dotProduct(vecA: vecA , vecB: dirVector2)  / dotProduct(vecA: dirVector2, vecB: dirVector2)
            let scaledDirVec = CGPoint(x: dirVector2.x * scalar2, y: dirVector2.y * scalar2)
            let projectedPoint2 = CGPoint(x: screenCorners.lfh.x + scaledDirVec.x, y: screenCorners.lfh.y + scaledDirVec.y)
            print("projection: \(projectedPoint2)")
            var hitTestResult = sceneView.hitTest(projectedPoint2, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                for hit in hitTestResult{
                    if hit.node == line2{
                    let currentPointInWC = hit.worldCoordinates
                    updatedHeight = CGFloat(abs(currentPointInWC.y - box.position.y))
                    let scaleFactor = Float(updatedHeight / originalHeight)
                    updatedWidth = originalWidth * CGFloat(scaleFactor)
                    updatedLength = originalLength * CGFloat(scaleFactor)

                    if(tapped3){
                        centerPosition = SCNVector3(x: corners.lfh.x + Float(updatedWidth/2), y: corners.lfh.y - Float(updatedHeight/2), z: corners.lfh.z - Float(updatedLength/2))
                        r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                        r2d2.position = centerPosition
                    }
                    else if(tapped6){
                        centerPosition = SCNVector3(x: corners.rbd.x - Float(updatedWidth/2), y: corners.rbd.y + Float(updatedHeight/2), z: corners.rbd.z + Float(updatedLength/2))
                        r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                        r2d2.position = centerPosition
                    }
                    
                    //updateCorners
                    setCorners()
                    setSpherePosition()
                    removeAllEdges()
                    setEdges()
                    colorEdges()

                    if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                        line1.removeFromParentNode()
                    }
                    if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                        line3.removeFromParentNode()
                    }
                    if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
                        line4.removeFromParentNode()
                    }
                        
                    let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                     next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                     next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                    
                    let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                     next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                     next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
                    
                    let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
                     next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
                     next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)

                    //diagonal from lfd to rbh
                    let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                        if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                            line3.name = "diagonal3"
                            scene.drawingNode.addChildNode(line3)
                        }
                    //diagonal from lbd to rfh
                    let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                        if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                            line1.name = "diagonal1"
                            scene.drawingNode.addChildNode(line1)
                        }
                    //diagonal from rfd to lbh
                    let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                        if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                            line4.name = "diagonal4"
                            scene.drawingNode.addChildNode(line4)
                        }
                    }
                    else{
                        if let index = hitTestResult.firstIndex(of: hit) {
                            hitTestResult.remove(at: index)
                        }
                    }
                }
            }
            //Project onto diagonal connecting rfd and lbh if one of the corners is selected
            else if (tapped4 || tapped5){
            let vecA = CGPoint(x:currentPoint.x - screenCorners.lbh.x, y:currentPoint.y - screenCorners.lbh.y)
            let scalar4 = dotProduct(vecA: vecA , vecB: dirVector4)  / dotProduct(vecA: dirVector4, vecB: dirVector4)
            let scaledDirVec = CGPoint(x: dirVector4.x * scalar4, y: dirVector4.y * scalar4)
            let projectedPoint4 = CGPoint(x: screenCorners.lbh.x + scaledDirVec.x, y: screenCorners.lbh.y + scaledDirVec.y)
            print("projection: \(projectedPoint4)")
            var hitTestResult = sceneView.hitTest(projectedPoint4, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                for hit in hitTestResult{
                //line4.opacity = 0.1
                    if hit.node == line4{
                        let currentPointInWC = hit.worldCoordinates
                        updatedHeight = CGFloat(abs(currentPointInWC.y - box.position.y))
                        let scaleFactor = Float(updatedHeight / originalHeight)
                        updatedWidth = originalWidth * CGFloat(scaleFactor)
                        updatedLength = originalLength * CGFloat(scaleFactor)

                        if(tapped4){
                            centerPosition = SCNVector3(x: corners.lbh.x + Float(updatedWidth/2), y: corners.lbh.y - Float(updatedHeight/2), z: corners.lbh.z + Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        else if(tapped5){
                            centerPosition = SCNVector3(x: corners.rfd.x - Float(updatedWidth/2), y: corners.rfd.y + Float(updatedHeight/2), z: corners.rfd.z - Float(updatedLength/2))
                            r2d2.scale = SCNVector3(x: 0.001*scaleFactor, y: 0.001*scaleFactor, z: 0.001*scaleFactor)
                            r2d2.position = centerPosition
                        }
                        
                        //update corners
                        setCorners()
                        setSpherePosition()
                        removeAllEdges()
                        setEdges()
                        colorEdges()
                        
                        //update diagonals
                        if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
                            line1.removeFromParentNode()
                        }
                        if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
                            line2.removeFromParentNode()
                        }
                        if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
                            line3.removeFromParentNode()
                        }
                        
                        let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
                         next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
                         next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
                        
                        let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
                         next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
                         next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
                        
                        let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
                         next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
                         next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)

                        //diagonal from lfd to rbh
                        let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                            if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                                line3.name = "diagonal3"
                                scene.drawingNode.addChildNode(line3)
                            }
                        //diagonal from lbd to rfh
                        let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                            if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                                line1.name = "diagonal1"
                                scene.drawingNode.addChildNode(line1)
                            }
                        //diagonal from lfh to rbd
                        let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                            if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                                line2.name = "diagonal2"
                                scene.drawingNode.addChildNode(line2)
                            }
                    }
                    else{
                         if let index = hitTestResult.firstIndex(of: hit) {
                             hitTestResult.remove(at: index)
                         }
                    }
                }
            }
        }
            
        else if recognizer.state == .ended{
            self.currentPoint = CGPoint(x:0, y:0)
            if selected == true{
                box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                selected = false
                tapped2 = false
                tapped3 = false
                tapped4 = false
                tapped5 = false
                tapped6 = false
                tapped7 = false
                tapped8 = false
                selectedCorner.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                
                //set boundingBox color back to blue
                edge1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge1.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge2.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge3.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge4.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge5.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge6.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge7.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge8.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge9.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge9.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge10.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge10.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge11.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge11.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                edge12.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                edge12.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
            }
        }
    }
    
    func setEdges(){
        guard let scene = self.currentScene else {return}
        //edge between lfd to rfd
        let edge1 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.rfd, inScene: scene)
        if edge1 != scene.drawingNode.childNode(withName: "edge1", recursively: false){
            edge1.name = "edge1"
            edge1.opacity = 0.6
            scene.drawingNode.addChildNode(edge1)
        }
        //edge between lfd to lfh
        let edge2 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.lfh, inScene: scene)
        if edge2 != scene.drawingNode.childNode(withName: "edge2", recursively: false){
            edge2.name = "edge2"
            edge2.opacity = 0.6
            scene.drawingNode.addChildNode(edge2)
        }
        //edge between lfh to rfh
        let edge3 = lineBetweenNodes(positionA: corners.lfh, positionB: corners.rfh, inScene: scene)
        if edge3 != scene.drawingNode.childNode(withName: "edge3", recursively: false){
            edge3.name = "edge3"
            edge3.opacity = 0.6
            scene.drawingNode.addChildNode(edge3)
        }
        //edge between rfh to rfd
        let edge4 = lineBetweenNodes(positionA: corners.rfh, positionB: corners.rfd, inScene: scene)
        if edge4 != scene.drawingNode.childNode(withName: "edge4", recursively: false){
            edge4.name = "edge4"
            edge4.opacity = 0.6
            scene.drawingNode.addChildNode(edge4)
        }
        //edge between lfd to lbd
        let edge5 = lineBetweenNodes(positionA: corners.lfd, positionB: corners.lbd, inScene: scene)
        if edge5 != scene.drawingNode.childNode(withName: "edge5", recursively: false){
            edge5.name = "edge5"
            edge5.opacity = 0.6
            scene.drawingNode.addChildNode(edge5)
        }
        //edge between lbd to lbh
        let edge6 = lineBetweenNodes(positionA: corners.lbd, positionB: corners.lbh, inScene: scene)
        if edge6 != scene.drawingNode.childNode(withName: "edge6", recursively: false){
            edge6.name = "edge6"
            edge6.opacity = 0.6
            scene.drawingNode.addChildNode(edge6)
        }
        //edge between lbh to lfh
        let edge7 = lineBetweenNodes(positionA: corners.lbh, positionB: corners.lfh, inScene: scene)
        if edge7 != scene.drawingNode.childNode(withName: "edge7", recursively: false){
            edge7.name = "edge7"
            edge7.opacity = 0.6
            scene.drawingNode.addChildNode(edge7)
        }
        //edge between lbh to rbh
        let edge8 = lineBetweenNodes(positionA: corners.lbh, positionB: corners.rbh, inScene: scene)
        if edge8 != scene.drawingNode.childNode(withName: "edge8", recursively: false){
            edge8.name = "edge8"
            edge8.opacity = 0.6
            scene.drawingNode.addChildNode(edge8)
        }
        //edge between rbh to rfh
        let edge9 = lineBetweenNodes(positionA: corners.rbh, positionB: corners.rfh, inScene: scene)
        if edge9 != scene.drawingNode.childNode(withName: "edge9", recursively: false){
            edge9.name = "edge9"
            edge9.opacity = 0.6
            scene.drawingNode.addChildNode(edge9)
        }
        //edge between rbh to rbd
        let edge10 = lineBetweenNodes(positionA: corners.rbh, positionB: corners.rbd, inScene: scene)
        if edge10 != scene.drawingNode.childNode(withName: "edge10", recursively: false){
            edge10.name = "edge10"
            edge10.opacity = 0.6
            scene.drawingNode.addChildNode(edge10)
        }
        //edge between rfd to rbd
        let edge11 = lineBetweenNodes(positionA: corners.rfd, positionB: corners.rbd, inScene: scene)
        if edge11 != scene.drawingNode.childNode(withName: "edge11", recursively: false){
            edge11.name = "edge11"
            edge11.opacity = 0.6
            scene.drawingNode.addChildNode(edge11)
        }
        //edge between lbd to rbd
        let edge12 = lineBetweenNodes(positionA: corners.lbd, positionB: corners.rbd, inScene: scene)
        if edge12 != scene.drawingNode.childNode(withName: "edge12", recursively: false){
            edge12.name = "edge12"
            edge12.opacity = 0.6
            scene.drawingNode.addChildNode(edge12)
        }
    }
    
    func removeAllEdges(){
        guard let scene = self.currentScene else {return}
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        edge1.removeFromParentNode()
        edge2.removeFromParentNode()
        edge3.removeFromParentNode()
        edge4.removeFromParentNode()
        edge5.removeFromParentNode()
        edge6.removeFromParentNode()
        edge7.removeFromParentNode()
        edge8.removeFromParentNode()
        edge9.removeFromParentNode()
        edge10.removeFromParentNode()
        edge11.removeFromParentNode()
        edge12.removeFromParentNode()
    }
    
    //changes color to yellow to visualize activated boundingBox
    func colorEdges(){
        guard let scene = self.currentScene else {return}
        guard let edge1 = scene.drawingNode.childNode(withName: "edge1", recursively: false) else{
            print("not found")
            return
        }
        guard let edge2 = scene.drawingNode.childNode(withName: "edge2", recursively: false) else{
            print("not found")
            return
        }
        guard let edge3 = scene.drawingNode.childNode(withName: "edge3", recursively: false) else{
            print("not found")
            return
        }
        guard let edge4 = scene.drawingNode.childNode(withName: "edge4", recursively: false) else{
            print("not found")
            return
        }
        guard let edge5 = scene.drawingNode.childNode(withName: "edge5", recursively: false) else{
            print("not found")
            return
        }
        guard let edge6 = scene.drawingNode.childNode(withName: "edge6", recursively: false) else{
            print("not found")
            return
        }
        guard let edge7 = scene.drawingNode.childNode(withName: "edge7", recursively: false) else{
            print("not found")
            return
        }
        guard let edge8 = scene.drawingNode.childNode(withName: "edge8", recursively: false) else{
            print("not found")
            return
        }
        guard let edge9 = scene.drawingNode.childNode(withName: "edge9", recursively: false) else{
            print("not found")
            return
        }
        guard let edge10 = scene.drawingNode.childNode(withName: "edge10", recursively: false) else{
            print("not found")
            return
        }
        guard let edge11 = scene.drawingNode.childNode(withName: "edge11", recursively: false) else{
            print("not found")
            return
        }
        guard let edge12 = scene.drawingNode.childNode(withName: "edge12", recursively: false) else{
            print("not found")
            return
        }
        
        edge1.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge1.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge2.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge2.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge3.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge3.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge4.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge4.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge5.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge5.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge6.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge6.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge7.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge7.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge8.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge8.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge9.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge9.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge10.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge10.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge11.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge11.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        edge12.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
        edge12.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        
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
    
    func setScreenCorners(){
        guard let sceneView = self.currentView else { return }
        /*self.screenCorners.lbd = sceneView.projectPoint(corners.lbd)
        self.screenCorners.lfd = sceneView.projectPoint(corners.lfd)
        self.screenCorners.rbd = sceneView.projectPoint(corners.rbd)
        self.screenCorners.rfd = sceneView.projectPoint(corners.rfd)
        self.screenCorners.lbh = sceneView.projectPoint(corners.lbh)
        self.screenCorners.lfh = sceneView.projectPoint(corners.lfh)
        self.screenCorners.rbh = sceneView.projectPoint(corners.rbh)
        self.screenCorners.rfh = sceneView.projectPoint(corners.rfh)*/
        
        self.screenCorners.lbd = CGPoint(x: Double(sceneView.projectPoint(corners.lbd).x), y: Double(sceneView.projectPoint(corners.lbd).y))
        self.screenCorners.lfd = CGPoint(x: Double(sceneView.projectPoint(corners.lfd).x), y: Double(sceneView.projectPoint(corners.lfd).y))
        self.screenCorners.rbd = CGPoint(x: Double(sceneView.projectPoint(corners.rbd).x), y: Double(sceneView.projectPoint(corners.rbd).y))
        self.screenCorners.rfd = CGPoint(x: Double(sceneView.projectPoint(corners.rfd).x), y: Double(sceneView.projectPoint(corners.rfd).y))
        self.screenCorners.lbh = CGPoint(x: Double(sceneView.projectPoint(corners.lbh).x), y: Double(sceneView.projectPoint(corners.lbh).y))
        self.screenCorners.lfh = CGPoint(x: Double(sceneView.projectPoint(corners.lfh).x), y: Double(sceneView.projectPoint(corners.lfh).y))
        self.screenCorners.rbh = CGPoint(x: Double(sceneView.projectPoint(corners.rbh).x), y: Double(sceneView.projectPoint(corners.rbh).y))
        self.screenCorners.rfh = CGPoint(x: Double(sceneView.projectPoint(corners.rfh).x), y: Double(sceneView.projectPoint(corners.rfh).y))
    }
    
    //compute the diagonals to drag the corner along
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.001
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.systemBlue

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.opacity = 0.01
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
     
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        
        self.currentScene = scene
        self.currentView = view
        
        //self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
       // self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        //print ("tapGesture: \(String(describing: tapGesture))")
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.currentView?.addGestureRecognizer(panGesture!)
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
       
        originalWidth = CGFloat(maxCorner.x - minCorner.x)
        originalHeight = CGFloat(maxCorner.z - minCorner.z)
        originalLength = CGFloat(maxCorner.y - minCorner.y)
        
        self.updatedWidth = originalWidth
        self.updatedHeight = originalHeight
        self.updatedLength = originalLength
        
        let box = SCNBox(width: originalWidth*0.01, height: originalHeight*0.01, length: originalLength*0.01, chamferRadius: 0)
        box.firstMaterial?.isDoubleSided = true
        let boundingBox = SCNNode(geometry: box)
        
        if boundingBox != scene.drawingNode.childNode(withName: "currentBoundingBox", recursively: false){
            boundingBox.position = SCNVector3(0,0,-0.3)
            centerPosition = boundingBox.position
            boundingBox.name = "currentBoundingBox"
            boundingBox.opacity = 0.01
            scene.drawingNode.addChildNode(boundingBox)
            }
        else{
            boundingBox.position = SCNVector3(0,0,-0.3)
            
        }
        
        setCorners()
        setEdges()
        
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
  
        //define initial diagonals
        let vector1 = SCNVector3(corners.lbd.x - corners.rfh.x, corners.lbd.y - corners.rfh.y, corners.lbd.z - corners.rfh.z)
         next_rfh = corners.rfh + SCNVector3(-5*vector1.x,-5*vector1.y,-5*vector1.z)
         next_lbd = corners.rfh + SCNVector3(6*vector1.x,6*vector1.y,6*vector1.z)
        
        let vector2 = SCNVector3(corners.rbd.x - corners.lfh.x, corners.rbd.y - corners.lfh.y, corners.rbd.z - corners.lfh.z)
         next_lfh = corners.lfh + SCNVector3(-5*vector2.x,-5*vector2.y,-5*vector2.z)
         next_rbd = corners.lfh + SCNVector3(6*vector2.x,6*vector2.y,6*vector2.z)
        
        let vector3 = SCNVector3(corners.lfd.x - corners.rbh.x, corners.lfd.y - corners.rbh.y, corners.lfd.z - corners.rbh.z)
         next_rbh = corners.rbh + SCNVector3(-5*vector3.x,-5*vector3.y,-5*vector3.z)
         next_lfd = corners.rbh + SCNVector3(6*vector3.x,6*vector3.y,6*vector3.z)
        
        let vector4 = SCNVector3(corners.rfd.x - corners.lbh.x, corners.rfd.y - corners.lbh.y, corners.rfd.z - corners.lbh.z)
         next_lbh = corners.lbh + SCNVector3(-5*vector4.x,-5*vector4.y,-5*vector4.z)
         next_rfd = corners.lbh + SCNVector3(6*vector4.x,6*vector4.y,6*vector4.z)
        
        //diagonal from lbd to rfh
        let line1 = lineBetweenNodes(positionA: next_lbd, positionB: next_rfh, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line1 != scene.drawingNode.childNode(withName: "diagonal1", recursively: false){
                    line1.name = "diagonal1"
                    scene.drawingNode.addChildNode(line1)
                }
        //diagonal from lfh to rbd
        let line2 = lineBetweenNodes(positionA: next_rbd, positionB: next_lfh, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line2 != scene.drawingNode.childNode(withName: "diagonal2", recursively: false){
                    line2.name = "diagonal2"
                    scene.drawingNode.addChildNode(line2)
                }
        //diagonal from lfd to rbh
        let line3 = lineBetweenNodes(positionA: next_rbh, positionB: next_lfd, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line3 != scene.drawingNode.childNode(withName: "diagonal3", recursively: false){
                    line3.name = "diagonal3"
                    scene.drawingNode.addChildNode(line3)
                }
       //diagonal from rfd to lbh
        let line4 = lineBetweenNodes(positionA: next_lbh, positionB: next_rfd, inScene: scene)
                //starwars?.rootNode.addChildNode(line)
                if line4 != scene.drawingNode.childNode(withName: "diagonal4", recursively: false){
                    line4.name = "diagonal4"
                    scene.drawingNode.addChildNode(line4)
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
        if let line1 = currentScene?.drawingNode.childNode(withName: "diagonal1", recursively: false){
            line1.removeFromParentNode()
        }
        if let line2 = currentScene?.drawingNode.childNode(withName: "diagonal2", recursively: false){
            line2.removeFromParentNode()
        }
        if let line3 = currentScene?.drawingNode.childNode(withName: "diagonal3", recursively: false){
            line3.removeFromParentNode()
        }
        if let line4 = currentScene?.drawingNode.childNode(withName: "diagonal4", recursively: false){
            line4.removeFromParentNode()
        }
        if let edge1 = currentScene?.drawingNode.childNode(withName: "edge1", recursively: false){
            edge1.removeFromParentNode()
        }
        if let edge2 = currentScene?.drawingNode.childNode(withName: "edge2", recursively: false){
            edge2.removeFromParentNode()
        }
        if let edge3 = currentScene?.drawingNode.childNode(withName: "edge3", recursively: false){
            edge3.removeFromParentNode()
        }
        if let edge4 = currentScene?.drawingNode.childNode(withName: "edge4", recursively: false){
            edge4.removeFromParentNode()
        }
        if let edge5 = currentScene?.drawingNode.childNode(withName: "edge5", recursively: false){
            edge5.removeFromParentNode()
        }
        if let edge6 = currentScene?.drawingNode.childNode(withName: "edge6", recursively: false){
            edge6.removeFromParentNode()
        }
        if let edge7 = currentScene?.drawingNode.childNode(withName: "edge7", recursively: false){
            edge7.removeFromParentNode()
        }
        if let edge8 = currentScene?.drawingNode.childNode(withName: "edge8", recursively: false){
            edge8.removeFromParentNode()
        }
        if let edge9 = currentScene?.drawingNode.childNode(withName: "edge9", recursively: false){
            edge9.removeFromParentNode()
        }
        if let edge10 = currentScene?.drawingNode.childNode(withName: "edge10", recursively: false){
            edge10.removeFromParentNode()
        }
        if let edge11 = currentScene?.drawingNode.childNode(withName: "edge11", recursively: false){
            edge11.removeFromParentNode()
        }
        if let edge12 = currentScene?.drawingNode.childNode(withName: "edge12", recursively: false){
            edge12.removeFromParentNode()
        }
        if let r2d2 = currentScene?.drawingNode.childNode(withName: "currentr2d2", recursively: false){
            r2d2.removeFromParentNode()
        }
        self.currentScene = nil

        if let panGestureRecognizer = self.panGesture{
            self.currentView?.removeGestureRecognizer(panGestureRecognizer)
        }

       /* if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }*/

        self.currentView = nil
    }
    
}



