//
//  MarkerBox.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit

/**
 The MarkerBox represents the Box on the ARPen. It simplifies some mathamtics.
 */
class MarkerBox: SCNNode {
    
    private var markerArray: [SCNNode]
    var penTipPositionHistory: [SCNVector3] = []
    var penLength: Double = 12
    
    /**
     * Describes in which landscape orientation the device is currently hold
     * If the device is hold in portrait orientation, the state keeps in the last landscape state
     */
    private var orientationState: DeviceOrientationState = .HomeButtonRight {
        didSet {
            //For each orientation the pen tip has to be calculated
            calculatePenTip(length: penLength)
        }
    }
    
    override convenience init() {
        self.init(length: UserDefaults.standard.double(forKey: UserDefaultsKeys.penLength.rawValue))
    }
    
    init(length: Double) {
        markerArray = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
        penLength = length
        super.init()
        self.name = "MarkerBox"
        
        //Observe device orientation. If orientation changes rotated() is called
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //Make pen tip calculation
        calculatePenTip(length: length)
    }
    
    func updatePenTipCalculations()
    {
        //set current pen length stored in user defaults
        penLength = Double(UserDefaults.standard.float(forKey: UserDefaultsKeys.penLength.rawValue))
        //check current device rotation (which triggers pen tip recalculation)
        rotated()
    }
    
    @objc func rotated(){
        if UIDevice.current.orientation.rawValue == 4 {
            orientationState = .HomeButtonLeft
        } else if UIDevice.current.orientation.rawValue == 3 {
            orientationState = .HomeButtonRight
        }
    }
    
    func calculatePenTip(length: Double){
        let a: Double = length
        var xs, ys, zs, xl, yl, zl, xc, yc: Double
        
        let angle = (35.3).degreesToRadians
        
        xs = ((cos(angle) * a) + 0.005)/sqrt(2)
        ys = xs
        zs = sin(angle) * a
        zs -= 0.02
        xs *= -1
        ys *= -1
        zs *= -1
        
        xl = (cos(angle) * a)/sqrt(2)
        yl = xl
        zl = sin(angle) * a
        zl += 0.02
        xl *= -1
        yl *= -1
        
        // Calculate the translation vector for cardboard marker face
        let markerOffsetFromBottom: Double = 0.01975 // distance from the bottom of the card to the center of the marker
        let cardWidth = 0.085
        let cardHeight = 0.055
        
        xc = 0.75 * cardWidth // assuming marker center is at three-fourths of the card width
        yc = cardHeight - markerOffsetFromBottom // height of the card is 5.5 cm
        
        var i = 0
        for marker in markerArray {
            marker.name = "Marker #\(i+1)"
            marker.childNodes.first?.removeFromParentNode()
            
            let markerFace = MarkerFace(rawValue: i+1) ?? .notExpected
            guard markerFace != .notExpected else {
                fatalError("markerArray shouldn't be longer than 6 elements!")
            }
            
            let point = SCNNode()
            point.name = "Point from #\(i+1)"
            
            //for rotation: for simplicity, take the top rotation as the basis. rotate other markers to fit the top orientation and then apply the same rotation to the pen tip
            let rotationMatrix = SCNMatrix4MakeRotation(-35.3*Float.pi/180, 0.5, -0.5, 0)
            switch (markerFace) {
            case (.back):
                point.position = SCNVector3(xs, ys, zs)
                let rotationToTopMatrix = SCNMatrix4Rotate(SCNMatrix4MakeRotation(-Float.pi/2, 0, 0, 1), -Float.pi/2, 1, 0, 0)
                point.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotationMatrix, rotationToTopMatrix), point.transform)
            case (.top):
                point.position = SCNVector3(xs, ys, zs)
                point.transform = SCNMatrix4Mult(rotationMatrix, point.transform)
            case (.right):
                point.position = SCNVector3(xs, ys, zs)
                let rotationToTopMatrix = SCNMatrix4Rotate(SCNMatrix4MakeRotation(Float.pi/2, 0, 0, 1), Float.pi/2, 0, 1, 0)
                point.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotationMatrix, rotationToTopMatrix), point.transform)
            case (.bottom):
                point.position = SCNVector3(-xl, yl, zl)
                let rotationToTopMatrix = SCNMatrix4MakeRotation(Float.pi, 0, 1, 0)
                point.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotationMatrix, rotationToTopMatrix), point.transform)
            case (.left):
                point.position = SCNVector3(xl, yl, zl)
                let rotationToTopMatrix = SCNMatrix4MakeRotation(-Float.pi/2, 1,0,0)
                point.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotationMatrix, rotationToTopMatrix), point.transform)
            case (.front):
                point.position = SCNVector3(-xl, yl, zl)
                let rotationToTopMatrix = SCNMatrix4Rotate(SCNMatrix4MakeRotation(Float.pi/2, 0, 1, 0), Float.pi/2, 0, 0, 1)
                point.transform = SCNMatrix4Mult(SCNMatrix4Mult(rotationMatrix, rotationToTopMatrix), point.transform)
            case (.cardboard):
                point.position = SCNVector3(-xc, -yc, 0)
                point.eulerAngles = SCNVector3(-Float.pi/2, 0, -Float.pi/4)
            default:
                break
            }
            
            //Invert the coordinates in landscape homebutton left
            if orientationState == .HomeButtonLeft {
                point.position.x *= -1
                point.position.y *= -1
            }
            
            marker.addChildNode(point)
            if !self.childNodes.contains(marker){
                self.addChildNode(marker)
            }
            
            i += 1
        }
    }
    
    /**
     Sets the position and rotation (in euler angles) for a specific ID.
     */
    func set(position: SCNVector3, rotation: SCNVector3, forID id: MarkerFace) {
        self.markerArray[id.rawValue-1].position = position
        self.markerArray[id.rawValue-1].eulerAngles = rotation
        
        //If orientation is Landscape with home button left we have to revert x and y axis and marker orientation
        if orientationState == .HomeButtonLeft {
            self.markerArray[id.rawValue-1].position.x *= -1
            self.markerArray[id.rawValue-1].position.y *= -1
            
            self.markerArray[id.rawValue-1].eulerAngles.x *= -1
            self.markerArray[id.rawValue-1].eulerAngles.y *= -1
        }
    }
    
    /**
     Determine the position of the pin point by ONLY considering the specified IDs
     - parameter ids: A list of marker IDs that are used to determine the position
     */
    func posititonWith(ids: [MarkerFace]) -> SCNNode {
        var node = SCNNode()
        //holds the computed pen tips for each marker -> can be averaged to return pen tip node
        var penTipCandidates = [SCNNode]()
        var penTipPosition = SCNVector3Zero
        var penTipRotation = SCNVector4Zero
        var mutableIds : [MarkerFace] = ids
        
        if mutableIds.count == 3 {
            let allowedDeviation: Float = 1.2 //Don't forget that some markers are not perfectly in the middle of the cube's face!
            
            //Calculate distances
            let distance12 = markerArray[0].position.distance(vector: markerArray[1].position)
            let distance13 = markerArray[0].position.distance(vector: markerArray[2].position)
            let distance23 = markerArray[1].position.distance(vector: markerArray[2].position)
            
            //If distance of one marker to another one deviates too much from the other inter-marker distances, this point is removed from calculation
            if distance12 > allowedDeviation * distance23 && distance13 > allowedDeviation * distance23 {
                //Point 1 offsetted
                mutableIds.remove(at: 0)
            } else if distance12 > allowedDeviation * distance13 && distance23 > allowedDeviation * distance13 {
                //Point 2 offsetted
                mutableIds.remove(at: 1)
            } else if distance13 > 1.3 * distance12 && distance23 > 1.3 * distance12 {
                //Point 3 offsetted
                mutableIds.remove(at: 2)
            }
        }
        
        for id in mutableIds {
            let candidateNode = SCNNode()
            let transform = self.markerArray[id.rawValue-1].childNodes.first!.convertTransform(SCNMatrix4Identity, to: nil)
            
            candidateNode.transform = transform
            penTipCandidates.append(candidateNode)
            penTipPosition += candidateNode.position
            penTipRotation.x += candidateNode.rotation.x
            penTipRotation.y += candidateNode.rotation.y
            penTipRotation.z += candidateNode.rotation.z
            penTipRotation.w += candidateNode.rotation.w
        }
        
        penTipPosition /= Float(mutableIds.count)
        penTipRotation.x /= Float(mutableIds.count)
        penTipRotation.y /= Float(mutableIds.count)
        penTipRotation.z /= Float(mutableIds.count)
        penTipRotation.w /= Float(mutableIds.count)
        
        //Average with past n tip positions
        let n = 1
        for pastPenTip in penTipPositionHistory {
            penTipPosition += pastPenTip
        }
        penTipPosition /= Float(penTipPositionHistory.count + 1)
        penTipPositionHistory.append(penTipPosition)
        
        //Remove latest item if too much items are in penTipPositionHistory
        if penTipPositionHistory.count > n {
            penTipPositionHistory.remove(at: 0)
        }

        node.position = penTipPosition
        node.rotation = penTipRotation
        return node
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private enum DeviceOrientationState {
        case HomeButtonLeft
        case HomeButtonRight
    }

}

/**
 The MarkerFace enum maps the marker-ids from OpenCV to the
 respective faces of the physical marker-box when it is placed in default position.
 Default position: cube placed down with the pen pointing away from you towards top right. (See https://github.com/i10/ARPen/blob/master/Documentation/images/Default_Position.jpg)
 */
enum MarkerFace: Int {
    case back = 1, top, right, bottom, left, front
    case cardboard = 7
    case notExpected = 0
}
