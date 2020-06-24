//
//  BoxModel.swift
//  ARPen
//
//  Created by
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class BoxModelNode : SCNNode {
    
    // observing the position of SCNNode to recalculate corners instead of making an outside code call the function everytime
    override var position : SCNVector3 {
        didSet {
            self.setCorners()
        }
    }
    
    //create random scale factor for model
    let randomScaleFactor : Float = Float.random(in: 0.2...0.3)
    
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))

    
    required init(withPosition thePosition : SCNVector3, andDimension theDimension : Float) {

        super.init()
        self.position = thePosition
        let boxGeometry = SCNBox.init(width: CGFloat(randomScaleFactor), height: CGFloat(randomScaleFactor), length: CGFloat(randomScaleFactor), chamferRadius: 0.0)
        self.geometry = boxGeometry
        self.name = "modelBoxNode"
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        self.opacity = 0.5
        
        self.setCorners()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.setCorners()
    }
    
    private func setCorners() {
        let halfDimension = self.randomScaleFactor/2
        let thePosition = self.position
        
        self.corners.lbd = SCNVector3Make(thePosition.x - halfDimension, thePosition.y - halfDimension, thePosition.z - halfDimension)
        self.corners.lfd = SCNVector3Make(thePosition.x - halfDimension, thePosition.y - halfDimension, thePosition.z + halfDimension)
        self.corners.rbd = SCNVector3Make(thePosition.x + halfDimension, thePosition.y - halfDimension, thePosition.z - halfDimension)
        self.corners.rfd = SCNVector3Make(thePosition.x + halfDimension, thePosition.y - halfDimension, thePosition.z + halfDimension)
        self.corners.lbh = SCNVector3Make(thePosition.x - halfDimension, thePosition.y + halfDimension, thePosition.z - halfDimension)
        self.corners.lfh = SCNVector3Make(thePosition.x - halfDimension, thePosition.y + halfDimension, thePosition.z + halfDimension)
        self.corners.rbh = SCNVector3Make(thePosition.x + halfDimension, thePosition.y + halfDimension, thePosition.z - halfDimension)
        self.corners.rfh = SCNVector3Make(thePosition.x + halfDimension, thePosition.y + halfDimension, thePosition.z + halfDimension)
    }
}
