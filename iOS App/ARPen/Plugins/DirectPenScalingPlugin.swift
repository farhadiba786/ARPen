//
//  DirectPen.swift
//  ARPen
//
//  Created by Farhadiba Mohammed on 18.07.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class DirectPenScalingPlugin: Plugin, UserStudyRecordPluginProtocol {
  
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    var pluginImage : UIImage? = UIImage.init(named: "DirectPenPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "DirectPenPlugin")
    var pluginIdentifier: String = "DirectPen"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView:  UILabel?

    var currentPoint = CGPoint()
    private var insideSphere : SCNNode? = nil
    private var selectedCorner : SCNNode?
    private var highlighted: Bool = false

    //Variables for bounding Box updates
    var centerPosition = SCNVector3()
    var updatedWidth : CGFloat = 0
    var updatedHeight : CGFloat = 0
    var updatedLength : CGFloat = 0
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))
    var screenCorners : (lbd : CGPoint, lfd : CGPoint, rbd : CGPoint, rfd : CGPoint, lbh : CGPoint, lfh : CGPoint, rbh : CGPoint, rfh : CGPoint) = (CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0),CGPoint(x: 0, y: 0))


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
        lineGeometry.radius = 0.005
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.yellow

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.opacity = 0.01
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
    }
    
    func highlightIfPointInsideSphere(point : SCNVector3){
        //check if point is inside a corner sphere, radius 0.008
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
        
        if (corners.lbd.x - 0.008 <= point.x && point.x <= corners.lbd.x + 0.008 && corners.lbd.y - 0.008 <= point.y && point.y <= corners.lbh.y + 0.008
            && corners.lbd.z - 0.008 <= point.z && point.z <= corners.lbd.z + 0.008){
            sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere1
        }
        else if (corners.lfd.x - 0.008 <= point.x && point.x <= corners.lfd.x + 0.008 && corners.lfd.y - 0.008 <= point.y && point.y <= corners.lfd.y + 0.008
        && corners.lfd.z - 0.008 <= point.z && point.z <= corners.lfd.z + 0.008){
            sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere2
        }
        else if (corners.rbd.x - 0.008 <= point.x && point.x <= corners.rbd.x + 0.008 && corners.rbd.y - 0.008 <= point.y && point.y <= corners.rbd.y + 0.008
        && corners.rbd.z - 0.008 <= point.z && point.z <= corners.rbd.z + 0.008){
            sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere3
        }
        else if (corners.rfd.x - 0.008 <= point.x && point.x <= corners.rfd.x + 0.008 && corners.rfd.y - 0.008 <= point.y && point.y <= corners.rfd.y + 0.008
        && corners.rfd.z - 0.008 <= point.z && point.z <= corners.rfd.z + 0.008){
            sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere4
        }
        else if (corners.lbh.x - 0.008 <= point.x && point.x <= corners.lbh.x + 0.008 && corners.lbh.y - 0.008 <= point.y && point.y <= corners.lbh.y + 0.008
        && corners.lbh.z - 0.008 <= point.z && point.z <= corners.lbh.z + 0.008){
            sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere5
        }
        else if (corners.lfh.x - 0.008 <= point.x && point.x <= corners.lfh.x + 0.008 && corners.lfh.y - 0.008 <= point.y && point.y <= corners.lfh.y + 0.008
        && corners.lfh.z - 0.008 <= point.z && point.z <= corners.lfh.z + 0.008){
            sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere6
        }
        else if  (corners.rbh.x - 0.008 <= point.x && point.x <= corners.rbh.x + 0.008 && corners.rbh.y - 0.008 <= point.y && point.y <= corners.rbh.y + 0.008
               && corners.rbh.z - 0.008 <= point.z && point.z <= corners.rbh.z + 0.008){
            sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere = sphere7
        }
        else if (corners.rfh.x - 0.008 <= point.x && point.x <= corners.rfh.x + 0.008 && corners.rfh.y - 0.008 <= point.y && point.y <= corners.rfh.y + 0.008
        && corners.rfh.z - 0.008 <= point.z && point.z <= corners.rfh.z + 0.008){
            sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            insideSphere  = sphere8
        }
        else{
            sphere1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere6.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere7.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
            sphere8.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        }
    }
    
    func dotProduct(vecA: CGPoint, vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y)
    }

    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        setScreenCorners()
        //define initial diagonals
        dirVector1 = CGPoint(x: screenCorners.lbd.x - screenCorners.rfh.x, y: screenCorners.lbd.y - screenCorners.rfh.y)
        dirVector2 = CGPoint(x: screenCorners.rbd.x - screenCorners.lfh.x, y: screenCorners.rbd.y - screenCorners.lfh.y)
        dirVector3 = CGPoint(x: screenCorners.lfd.x - screenCorners.rbh.x, y: screenCorners.lfd.y - screenCorners.rbh.y)
        dirVector4 = CGPoint(x: screenCorners.rfd.x - screenCorners.lbh.x, y: screenCorners.rfd.y - screenCorners.lbh.y)
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
        
        let pressed = buttons[Button.Button1]!
        
        highlightIfPointInsideSphere(point: scene.pencilPoint.position)
        
        if pressed{
            //only perform scaling if pentip is inside corner sphere
            if let selectedCorner = self.insideSphere{
                selectedCorner.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                    //select:lbd --> pivot:rfh
                    if selectedCorner == corner1 {
                        if selected == false{
                            print("1centerPosition:\(centerPosition)")
                            print("1updatedHeight: \(updatedHeight)")
                            print("1updatedWidth: \(updatedWidth)")
                            print("1updatedLength: \(updatedLength)")
                            print("1cornersMethod: \(corners)")
                            
                            selected = true
                            tapped1 = true
                            line1.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(abs(corners.rfh.x - centerPosition.x)), Float(abs(corners.rfh.y - centerPosition.y)), Float(abs(corners.rfh.z - centerPosition.z)))
                            box.position = corners.rfh
                            
                            print("pivot1: \(box.pivot)")
                            print("position1: \(box.position)")
                        }
                    }
                    //select:lfd --> pivot:rbh
                    else if selectedCorner == corner2{
                        if selected == false{
                            print("2centerPosition:\(centerPosition)")
                            print("2updatedHeight: \(updatedHeight)")
                            print("2updatedWidth: \(updatedWidth)")
                            print("2updatedLength: \(updatedLength)")
                            print("2cornersMethod: \(corners)")
                            
                            selected = true
                            tapped2 = true
                            line3.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbh.x-centerPosition.x), Float(corners.rbh.y-centerPosition.y), Float(corners.rbh.z-centerPosition.z))
                            box.position = corners.rbh
                            
                            print("pivot2: \(box.pivot)")
                            print("position2: \(box.position)")
                        }
                    }
                    //select:rbd --> pivot:lfh
                    else if selectedCorner == corner3 {
                        if selected == false{
                            print("3centerPosition:\(centerPosition)")
                            print("3updatedHeight: \(updatedHeight)")
                            print("3updatedWidth: \(updatedWidth)")
                            print("3updatedLength: \(updatedLength)")
                            print("3cornersMethod: \(corners)")
                            
                            selected = true
                            tapped3 = true
                            line2.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfh.x + centerPosition.x), Float( corners.lfh.y - centerPosition.y), Float(corners.lfh.z - centerPosition.z))
                            box.position = corners.lfh
                            
                            print("3pivot: \(box.pivot)")
                            print("3position: \(box.position)")
                        }
                    }
                    //select:rfd --> pivot:lbh
                    else if selectedCorner == corner4 {
                        if selected == false{

                            print("4centerPosition:\(centerPosition)")
                            print("4updatedHeight: \(updatedHeight)")
                            print("4updatedWidth: \(updatedWidth)")
                            print("4updatedLength: \(updatedLength)")
                            print("4cornersMethod: \(corners)")
                            selected = true
                            tapped4 = true
                            line4.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbh.x-centerPosition.x), Float(corners.lbh.y-centerPosition.y), Float(corners.lbh.z-centerPosition.z))
                            box.position = corners.lbh
                            
                            print("4pivot: \(box.pivot)")
                            print("4position: \(box.position)")
                        }
                    }
                    //select:lbh --> pivot:rfd
                    else if selectedCorner == corner5{
                        if selected == false{

                            print("5centerPosition:\(centerPosition)")
                            print("5updatedHeight: \(updatedHeight)")
                            print("5updatedWidth: \(updatedWidth)")
                            print("5updatedLength: \(updatedLength)")
                            print("5cornersMethod: \(corners)")
                            selected = true
                            tapped5 = true
                            line4.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rfd.x-centerPosition.x), Float(corners.rfd.y-centerPosition.y), Float(corners.rfd.z-centerPosition.z))
                            box.position = corners.rfd
                            
                            print("5pivot: \(box.pivot)")
                            print("5position: \(box.position)")
                        }
                    }
                    //select:lfh --> pivot:rbd
                    else if selectedCorner == corner6{
                        if selected == false{

                            print("6centerPosition:\(centerPosition)")
                            print("6updatedHeight: \(updatedHeight)")
                            print("6updatedWidth: \(updatedWidth)")
                            print("6updatedLength: \(updatedLength)")
                            print("6cornersMethod: \(corners)")
                            
                            selected = true
                            tapped6 = true
                            line2.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(Float(updatedWidth/2), -Float(updatedHeight/2), -Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.rbd.x-centerPosition.x), Float(corners.rbd.y-centerPosition.y), Float(corners.rbd.z-centerPosition.z))
                            box.position = corners.rbd
                            
                            print("6pivot: \(box.pivot)")
                            print("6position: \(box.position)")
                        }
                    }
                    //select:rbh --> pivot:lfd
                    else if selectedCorner == corner7 {
                        if selected == false{
                            print("7centerPosition:\(centerPosition)")
                            print("7updatedHeight: \(updatedHeight)")
                            print("7updatedWidth: \(updatedWidth)")
                            print("7updatedLength: \(updatedLength)")
                            print("7cornersMethod: \(corners)")
                            
                            selected = true
                            tapped7 = true
                            line3.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(updatedWidth/2), -Float(updatedHeight/2), Float(updatedLength/2))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lfd.x-centerPosition.x), Float(corners.lfd.y-centerPosition.y), Float(corners.lfd.z-centerPosition.z))
                            box.position = corners.lfd
                            
                            print("7pivot: \(box.pivot)")
                            print("7position: \(box.position)")
                        }
                    }
                    //select:rfh --> pivot:lbd
                    else if selectedCorner == corner8 {
                        if selected == false{
                            print("8centerPosition:\(centerPosition)")
                            print("8updatedHeight: \(updatedHeight)")
                            print("8updatedWidth: \(updatedWidth)")
                            print("8updatedLength: \(updatedLength)")
                            print("8cornersMethod: \(corners)")
                            
                            selected = true
                            tapped8 = true
                            line1.opacity = 0.3
                            box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGray
                            box.geometry?.firstMaterial?.emission.contents = UIColor.yellow
                            //box.pivot = SCNMatrix4MakeTranslation(-Float(0.5*updatedWidth), -Float(0.5*updatedHeight), -Float(0.5*updatedLength))
                            box.pivot = SCNMatrix4MakeTranslation(Float(corners.lbd.x-centerPosition.x), Float(corners.lbd.y-centerPosition.y), Float(corners.lbd.z-centerPosition.z))
                            box.position = corners.lbd
                            
                            print("8pivot: \(box.pivot)")
                            print("8position: \(box.position)")
                        }
                    }
                
               
                if selected == true {
                    currentPoint = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
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
                                //print("centerPosition: \(centerPosition)")
                                //update Corners
                                setCorners()
                                setSpherePosition()
                                
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
                                
                                //update Corners
                                setCorners()
                                setSpherePosition()
                                
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
                    let scaledDirVec = CGPoint(x: dirVector2.x * scalar2, y: dirVector3.y * scalar2)
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
                            
                            //updateCorners
                            setCorners()
                            setSpherePosition()

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
                                
                                //update corners
                                setCorners()
                                setSpherePosition()
                                
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
            }
        }
        else{
            if selected == true{
                insideSphere = nil
                //select:lbd --> pivot:rfh
                if tapped1{
                    tapped1 = false
                    selected = false
                    line1.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner1.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    print("pivot1: \(box.pivot)")
                    print("position1: \(box.position)")
                }
                //select:lfd --> pivot:rbh
                if  tapped2{
                    selected = false
                    tapped2 = false
                    line3.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner2.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    print("pivot2: \(box.pivot)")
                    print("position2: \(box.position)")
                }
                //select:rbd --> pivot:lfh
                if tapped3{
                    selected = false
                    tapped3 = false
                    line2.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner3.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)

                    //print("3pivot: \(box.pivot)")
                    //print("3position: \(box.position)")
                }
                //select:rfd --> pivot:lbh
                if tapped4{
                    selected = false
                    tapped4 = false
                    line4.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner4.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("4pivot: \(box.pivot)")
                    //print("4position: \(box.position)")
                }
                //select:lbh --> pivot:rfd
                if tapped5{
                    selected = false
                    tapped5 = false
                    line4.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner5.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("5pivot: \(box.pivot)")
                    //print("5position: \(box.position)")
                }
                //select:lfh --> pivot:rbd
                if tapped6{
                    selected = false
                    tapped6 = false
                    line2.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner6.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("6pivot: \(box.pivot)")
                    //print("6position: \(box.position)")
                }
                //select:rbh --> pivot:lfd
                if tapped7{
                    selected = false
                    tapped7 = false
                    line3.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner7.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("7pivot: \(box.pivot)")
                    //print("7position: \(box.position)")
                }
                //select:rfh --> pivot:lbd
                if tapped8{
                    selected = false
                    tapped8 = false
                    line1.opacity = 0.01
                    box.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
                    box.geometry?.firstMaterial?.emission.contents = UIColor.systemBlue
                    corner8.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    box.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
                    box.position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
                    //print("8pivot: \(box.pivot)")
                    //print("8position: \(box.position)")
                }
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
        
        if let r2d2 = currentScene?.drawingNode.childNode(withName: "currentr2d2", recursively: false){
            r2d2.removeFromParentNode()
        }
        self.currentScene = nil

        self.currentView = nil
    }
    
}



