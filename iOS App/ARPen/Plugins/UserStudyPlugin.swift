/*//
//  userStudyPlugin.swift
//  ARPen
//
//  Created by mohammed on 11.08.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

protocol UserStudyPluginDelegate {
    func hideSettings()
    func showSettings()
    func hidePlugins()
    func showPlugins()
}

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class UserStudyPlugin: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    var viewController: ViewController!
    var pluginManager: PluginManager!
    var plugins: [Plugin] = [PinchScalingPlugin(), ScrollScalingPlugin(), DirectPenScalingPlugin()]
    var currentPlugin : Plugin = ScrollScalingPlugin()
    var technique : String = ""
    
    
    var penColor: UIColor = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    //private var previousPoint: SCNVector3?

    private var started :Bool = false
    private var firstInit :Bool = true
    private var stopped :Bool = false
    private var startingMillis :Int64 = 0
    private var stoppingMillis :Int64 = 0
    private var resetMillis :Int64 = 0
    
    private var currentIteration = 0
    private var training :Bool = true
    private var latinSquareID = 0
    private var finished :Bool = false
    
    private var latinSquare = [
        [0, 1, 2, 3, 4, 5],
        [2, 0, 4, 1, 5, 3],
        [1, 3, 0, 5, 2, 4],
        [4, 2, 5, 0, 3, 1],
        [3, 5, 1, 4, 0, 2],
        [5, 4, 3, 2, 1, 0],
    ]
    
    var delegate: UserStudyPluginDelegate?
    
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var pluginLabel: UILabel!
    @IBOutlet weak var instructLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    
    override init() {
        super.init()
    
        self.pluginImage = UIImage.init(named: "UserStudyPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "UserStudyPlugin")
        self.pluginIdentifier = "UserStudy"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
        //nibNameOfCustomUIView = "UserStudyPlugin"
        
        self.currentPoint = CGPoint()
        /** Variables needed within UserStudyPlugin for each of the scaling techniques*/
        //Variables for bounding Box updates
        self.centerPosition = SCNVector3()
        self.updatedWidth = 0
        self.updatedHeight = 0
        self.updatedLength = 0
        self.scaleFactor = 0
        //l = left, r = right, b = back, f = front, d = down, h = high
        self.corners = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))
        self.edges = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0), SCNVector3Make(0, 0, 0))

        //Variables to ensure only one Corner an be selected at a time
        self.selectedCorner = SCNNode()
        self.selected = false
        self.tapped1 = false
        self.tapped2 = false
        self.tapped3 = false
        self.tapped4 = false
        self.tapped5 = false
        self.tapped6 = false
        self.tapped7 = false
        self.tapped8 = false
        
        //Corner Variables for diagonals
        self.next_rfh = SCNVector3()
        self.next_lbd = SCNVector3()
        self.next_lfh = SCNVector3()
        self.next_rbd = SCNVector3()
        self.next_rbh = SCNVector3()
        self.next_lfd = SCNVector3()
        self.next_lbh = SCNVector3()
        self.next_rfd = SCNVector3()
        self.dirVector1 = CGPoint()
        self.dirVector2 = CGPoint()
        self.dirVector3 = CGPoint()
        self.dirVector4 = CGPoint()
        
        //Variables for text
        self.widthIncmStr = ""
        self.heightIncmStr = ""
        self.lengthIncmStr = ""

        //variables for initial bounding Box
        self.originalWidth = 0
        self.originalHeight = 0
        self.originalLength = 0
        self.originalScale = SCNVector3()

        //Variables For USER STUDY TASK
        self.userStudyReps = 0
        //variables for measuring
        self.finalWidth = 0
        self.finalHeight = 0
        self.finalLength = 0

        self.randomValue = ""
        self.target = String()

        self.selectionCounter = 0

        self.startTime = Date()
        self.endTime = Date()
        self.elapsedTime = 0.0
    }
    
    func clearScene(withScene scene: PenScene){
        scene.drawingNode.enumerateChildNodes {(node, pointer) in
            node.removeFromParentNode()
        }
    }
    
    func activateTraining(){
        self.training = true
        self.stopped = false
    }
    
    func prepareNextTechnique(withScene scene: PenScene){
        //save current data
        if let path = recordManager.urlToCSV() {
            print("Stored CSV") // + path.absoluteString
        } else {
            print("Error creating the csv!")
        }
        
        //select next pen
        currentIteration += 1
        if(currentIteration > 5){
            finished = true
            recordManager.setPluginsLocked(locked: false)
            print("Unlock plugins")
            print("Finished")
            DispatchQueue.main.async {
                self.pluginLabel.text = "Finished"
                self.instructLabel.text = "Thank you!"
                self.headingLabel.text = "Finished"
                self.delegate?.showPlugins()
            }
        } else {
            currentPlugin = self.plugins[latinSquare[latinSquareID][currentIteration]]
            print("currentPlugin: \(currentPlugin)")
            currentPlugin.activatePlugin(withScene: scene, andView: self.currentView!)
            
            scene.markerBox.setModel(newmodel: Model.top)
            scene.markerBox.calculatePenTip(length: 0.140)
            
            switch currentPlugin {
            case is PinchScalingPlugin:
                self.technique = "Pinch-Scaling"

            case is ScrollScalingPlugin:
                self.technique = "Scroll-Scaling"

            case is DirectPenScalingPlugin:
                self.technique = "Direct Pen Scaling"
            
            case is PenRayScalingPlugin:
                self.technique = "Pen Ray Scaling"
                
            case is TouchAndPenScalingPlugin:
                self.technique = "Touch and Pen Scaling"
                
            case is PointScalingPlugin:
                self.technique = "Point Scaling"

            default:
                print("No technique active")
            }
            DispatchQueue.main.async {
                self.pluginLabel.text = "\(self.technique)"
                self.instructLabel.text = "For \(self.technique)"
                self.headingLabel.text = "Next: Training"
            }
            //activate training
            activateTraining()
        }
    }
    
    func resetTrial(withScene scene: PenScene){
        print("Reset to last training")
        if(self.training || self.finished){
            self.finished = false
            recordManager.setPluginsLocked(locked: true)
            print("Lock plugins")
            //go back to last training
            if(currentIteration > 0){
                currentIteration -= 1
                scene.markerBox.setModel(newmodel: Model.top)
                scene.markerBox.calculatePenTip(length: 0.140)
                DispatchQueue.main.async {
                    self.pluginLabel.text = "\(self.plugins[self.latinSquare[self.latinSquareID][self.currentIteration]])"
                }
            }
        }
        //go back to current training
        activateTraining()
        self.started = true
        self.startingMillis = Date().millisecondsSince1970
        scene.setPencilPointColor(r: 0.0, g: 0.0, b: 1.0, a: 1)
        clearScene(withScene: scene)
        print("Started training with pen \(plugins[latinSquare[latinSquareID][currentIteration]])")
        switch currentPlugin {
        case is PinchScalingPlugin:
            self.technique = "Pinch-Scaling"

        case is ScrollScalingPlugin:
            self.technique = "Scroll-Scaling"

        case is DirectPenScalingPlugin:
            self.technique = "Direct Pen Scaling"
        
        case is PenRayScalingPlugin:
            self.technique = "Pen Ray Scaling"
            
        case is TouchAndPenScalingPlugin:
            self.technique = "Touch and Pen Scaling"
            
        case is PointScalingPlugin:
            self.technique = "Point Scaling"

        default:
            print("No technique active")
        }
        DispatchQueue.main.async {
            self.headingLabel.text = "Training with: \(self.technique)"
            self.instructLabel.text = ""
            self.delegate?.showSettings()
            self.delegate?.hidePlugins()
        }
        self.resetMillis = 0
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard self.recordManager != nil else {return}
        
        if(self.recordManager.currentActiveUserID == nil){
            scene.setPencilPointColor(r: 1, g: 0, b: 0, a: 1)
            return
        }
        
        /*let reset = buttons[Button.Button2]!
        
        if(reset){
            if(self.resetMillis > 0){
                if((Date().millisecondsSince1970 - self.resetMillis) > 3000){
                    resetTrial(withScene: scene)
                }
            } else {
                self.resetMillis = Date().millisecondsSince1970
            }
        } else {
            self.resetMillis = 0
        }*/
        
        if(self.finished){
            scene.setPencilPointColor(r: 0, g: 1, b: 0, a: 1)
            return
        }
        
        let startStop = buttons[Button.Button3]!
        
        // training and trial are entered by pressing Button3
        if (!self.started && startStop && (Date().millisecondsSince1970 - self.stoppingMillis) > 1000){
        
            self.started = true
            self.startingMillis = Date().millisecondsSince1970
            if(training){
                scene.setPencilPointColor(r: 0.0, g: 0.0, b: 1.0, a: 1)
                switch currentPlugin {
                case is PinchScalingPlugin:
                    self.technique = "Pinch-Scaling"

                case is ScrollScalingPlugin:
                    self.technique = "Scroll-Scaling"

                case is DirectPenScalingPlugin:
                    self.technique = "Direct Pen Scaling"
                
                case is PenRayScalingPlugin:
                    self.technique = "Pen Ray Scaling"
                    
                case is TouchAndPenScalingPlugin:
                    self.technique = "Touch and Pen Scaling"
                    
                case is PointScalingPlugin:
                    self.technique = "Point Scaling"

                default:
                    print("No technique active")
                }
                //clearScene(withScene: scene)
                //currentPlugin.reset()
                print("Started training with  \(self.technique)")
                DispatchQueue.main.async {
                    self.headingLabel.text = "Training with: \(self.technique)"
                }
            } else {
                print("Started trial with  \(self.technique)")
                DispatchQueue.main.async {
                    self.headingLabel.text = ""
                    self.delegate?.hideSettings()
                }
            }
            DispatchQueue.main.async {
                self.instructLabel.text = ""
            }
        }
        
        //print("milli\(Date().millisecondsSince1970 - self.startingMillis)")
        //active training or trial mode, pressed Button3 to stop
        if(self.started && !self.stopped && startStop && (Date().millisecondsSince1970 - self.startingMillis) > 1000){
            self.stoppingMillis = Date().millisecondsSince1970
            if(self.training){
                self.stopped = false //it stays false because now the real trial can begin
                self.training = false
                self.started = false
                self.firstInit = true
                scene.setPencilPointColor(r: 0.8, g: 0.4, b: 0.12157, a: 1)
                //clearScene(withScene: scene)
                print("Finished training with \(self.technique)")
                
                //compute random width/height/length users should scale the object to
                    let randomWidth = String(format: "%.1f",Float.random(in: 3...15))
                    let randomHeight = String(format: "%.1f",Float.random(in: 8...25))
                    let randomLength = String(format: "%.1f",Float.random(in: 3...12))
                    
                    //Vary between width/ height/length
                    let randomTarget = Int.random(in: 1...3)
                    print("randomTarget: \(randomTarget)")
                    if randomTarget == 1{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Width: \(randomWidth)cm"
                        }
                        self.target = "width"
                        self.randomValue = randomWidth
                    }
                    if randomTarget == 2{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Height: \(randomHeight)cm"
                        }
                        self.target = "height"
                        self.randomValue = randomHeight
                    }
                    if randomTarget == 3{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Length: \(randomLength)cm"
                        }
                        self.target = "length"
                        self.randomValue = randomLength
                    }
               
                DispatchQueue.main.async {
                    self.instructLabel.text = "Press the Continue Button to start the Trial"
                    self.headingLabel.text = ""
                }
                currentPlugin.reset()
                
            } else {
                
                    //self.stopped = true
                    //self.started = false
                    scene.setPencilPointColor(r: 0.8, g: 0.73, b: 0.12157, a: 1)
                    currentPlugin.endTime = Date()
                    currentPlugin.elapsedTime = currentPlugin.endTime.timeIntervalSince(currentPlugin.startTime)
                    print("hello world")
                   self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: [
                            "timestamp" : "\(Date().millisecondsSince1970)",
                            "userStudyReps" : "\(currentPlugin.userStudyReps)",
                            "originalWidth": "\(currentPlugin.originalWidth)",
                            "originalHeight": "\(currentPlugin.originalHeight)",
                            "originalLength": "\(currentPlugin.originalLength)",
                            "finalWidthExact" : "\(currentPlugin.updatedWidth)",
                            "finalHeightExact" : "\(currentPlugin.updatedHeight)",
                            "finalLengthExact" : "\(currentPlugin.updatedLength)",
                            "finalWidthRounded" : "\(currentPlugin.widthIncmStr)",
                            "finalHeightRounded" : "\(currentPlugin.heightIncmStr)",
                            "finalLengthRounded" : "\(currentPlugin.lengthIncmStr)",
                            "scaleFactor": "\(currentPlugin.scaleFactor)",
                            "number of scale attempts": "\(currentPlugin.selectionCounter)",
                            "selectedCorner" : "\(String(describing:currentPlugin.selectedCorner.name))",
                            "target side to scale": "\(self.target)",
                            "target size:": "\(self.randomValue)",
                            "task time" : "\(currentPlugin.elapsedTime)"
                        ])
                    print("starttime: \(currentPlugin.startTime)")
                    print("endtime: \(currentPlugin.endTime)")
                    print("timestamp: ", Date().millisecondsSince1970)
                    print("userStudyReps: ", currentPlugin.userStudyReps)
                    print("originalWidthExact :", currentPlugin.originalWidth)
                    print("originalHeightExact: ", currentPlugin.originalHeight)
                    print("originalLengthExact: ", currentPlugin.originalLength)
                    print("finalWidthExact :", currentPlugin.updatedWidth)
                    print("finalHeightExact: ", currentPlugin.updatedHeight)
                    print("finalLengthExact: ", currentPlugin.updatedLength)
                    print("finalWidthRounded: ", currentPlugin.widthIncmStr)
                    print("finalHeightRounded: ", currentPlugin.heightIncmStr)
                    print("finalLengthRounded: ", currentPlugin.lengthIncmStr)
                    print("numberOfSelections: ", currentPlugin.selectionCounter)
                    print("scaleFactor: ", currentPlugin.scaleFactor)
                    print("number of scale attempts: ", currentPlugin.selectionCounter)
                    print("selectedCorner: ", currentPlugin.selectedCorner.name)
                    print("target side to scale", self.target)
                    print("target size:",self.randomValue)
                    print("time: ", currentPlugin.elapsedTime)
                    
                    currentPlugin.reset()
                    
                    //compute random width/height/length users should scale the object to
                    let randomWidth = String(format: "%.1f",Float.random(in: 3...15))
                    let randomHeight = String(format: "%.1f",Float.random(in: 8...25))
                    let randomLength = String(format: "%.1f",Float.random(in: 3...12))
                    
                    
                    //Vary between width/ height/length
                    let randomTarget = Int.random(in: 1...3)
                    print("randomTarget: \(randomTarget)")
                    if randomTarget == 1{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Width: \(randomWidth)cm"
                        }
                        self.target = "width"
                        self.randomValue = randomWidth
                    }
                    if randomTarget == 2{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Height: \(randomHeight)cm"
                        }
                        self.target = "height"
                        self.randomValue = randomHeight
                    }
                    if randomTarget == 3{
                        DispatchQueue.main.async {
                            self.targetLabel.text = "Length: \(randomLength)cm"
                        }
                        self.target = "length"
                        self.randomValue = randomLength
                    }
           
                
                    self.stopped = true
                    self.started = false
                    currentPlugin.deactivatePlugin()
                    prepareNextTechnique(withScene: scene)
                    
                    print("Finished trial with pen \(plugins[latinSquare[latinSquareID][currentIteration]])")
                    DispatchQueue.main.async {
                        self.delegate?.showSettings()
                        
                    }
                
            
            }
        }
       
        
    
        
        /*if (self.started && !self.stopped) {
            if(!self.training){
                if(self.firstInit){
                    scene.setPencilPointColor(r: 0.73, g: 0.12157, b: 0.8, a: 1)
                    self.firstInit = false
                    print("Recording")
                }
                    self.recordManager.addNewRecord(withIdentifier: self.pluginIdentifier, andData: [
                    "timestamp" : "\(Date().millisecondsSince1970)",
                        "userStudyReps" : "\(currentPlugin.userStudyReps)",
                        "originalWidth": "\(currentPlugin.originalWidth)",
                        "originalHeight": "\(currentPlugin.originalHeight)",
                        "originalLength": "\(currentPlugin.originalLength)",
                        "finalWidthExact" : "\(currentPlugin.finalWidth)",
                        "finalHeightExact" : "\(currentPlugin.finalHeight)",
                        "finalLengthExact" : "\(currentPlugin.finalLength)",
                        "finalWidthRounded" : "\(currentPlugin.widthIncmStr)",
                        "finalHeightRounded" : "\(currentPlugin.heightIncmStr)",
                        "finalLengthRounded" : "\(currentPlugin.lengthIncmStr)",
                        "scaleFactor": "\(currentPlugin.scaleFactor)",
                        "number of scale attempts": "\(currentPlugin.selectionCounter)",
                        "selectedCorner" : "\(currentPlugin.selectedCorner.name)",
                        "target side to scale": "\(currentPlugin.target)",
                        "target size:": "\(currentPlugin.randomValue)",
                        "task time" : "\(currentPlugin.elapsedTime)"
                    ])

                print("userStudyReps: ", currentPlugin.userStudyReps)
                print("selection counter: ", currentPlugin.selectionCounter)
                print("finalWidthExact :", currentPlugin.finalWidth)
                print("finalHeightExact: ", currentPlugin.finalHeight)
                print("finalLengthExact: ", currentPlugin.finalLength)
                print("finalLengthExact: ", currentPlugin.finalLength)
                print("finalWidthRounded: ", currentPlugin.widthIncmStr)
                print("finalHeightRounded: ", currentPlugin.heightIncmStr)
                print("finalLengthRounded: ", currentPlugin.lengthIncmStr)
                print("numberOfSelections: ", currentPlugin.selectionCounter)
                print("scaleFactor: ", currentPlugin.scaleFactor)
                print("time: ", currentPlugin.elapsedTime)
                print("selectedCorner: ", currentPlugin.selectedCorner.name)
                print("target side to scale", currentPlugin.target)
                print("target size:", currentPlugin.randomValue)
            }
        } else {
            // for review testing disable the need to log information
            return
        }
        
        guard scene.markerFound else {
            //Don't reset the previous point to avoid disconnected lines if the marker detection failed for some frames
            //self.previousPoint = nil
            return
        }*/
        
        
        
        //self.previousPoint = scene.pencilPoint.position
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView){
        clearScene(withScene: scene)
        self.currentScene = scene
        self.currentView = view
        //The PluginManager instance
        self.pluginManager = PluginManager(scene: scene)
        self.plugins = [PinchScalingPlugin(), PointScalingPlugin(), DirectPenScalingPlugin(), PenRayScalingPlugin(), TouchAndPenScalingPlugin(), ScrollScalingPlugin()]
        self.currentPlugin = self.plugins[self.latinSquare[self.latinSquareID][0]]
  
        self.started = false
        self.firstInit = true
        self.stopped = false
        self.finished = false
        
        scene.setPencilPointColor(r: 0.8, g: 0.73, b: 0.12157, a: 1)
        
        if(self.recordManager != nil && self.recordManager.currentActiveUserID != nil){
            
            latinSquareID = self.recordManager.currentActiveUserID! % 6
            let id = self.recordManager.currentActiveUserID!
            print("User with id " + String(id) + " to latinSquareID " + String(latinSquareID))
            print(latinSquare[latinSquareID])
            
            scene.markerBox.setModel(newmodel: Model.top)
            scene.markerBox.calculatePenTip(length: 0.140)
            
            activateTraining()
            currentIteration = 0
            
            switch currentPlugin {
            case is PinchScalingPlugin:
                self.technique = "Pinch-Scaling"

            case is ScrollScalingPlugin:
                self.technique = "Scroll-Scaling"

            case is DirectPenScalingPlugin:
                self.technique = "Direct Pen Scaling"
            
            case is PenRayScalingPlugin:
                self.technique = "Pen Ray Scaling"
                
            case is TouchAndPenScalingPlugin:
                self.technique = "Touch and Pen Scaling"
                
            case is PointScalingPlugin:
                self.technique = "Point Scaling"

            default:
                print("No technique active")
            }
            
            self.pluginLabel.text = "\(technique)"
            
            self.targetLabel.text = ""
            
            self.instructLabel.text = "For \(technique)"

            self.headingLabel.text = "Next: Training"

            recordManager.setPluginsLocked(locked: true)
            self.delegate?.hidePlugins()
            print("Lock plugins")
        } else {
            self.instructLabel.text = "User ID missing!"
            
            self.pluginLabel.text = ""
            
            self.targetLabel.text = ""

            self.headingLabel.text = ""
        }
        
        print("currentPlugin: \(currentPlugin)")
        currentPlugin.activatePlugin(withScene: scene, andView: view)
    }
    
    override func deactivatePlugin() {
        currentPlugin.deactivatePlugin()
    }
}
*/
