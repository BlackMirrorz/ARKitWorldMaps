//
//  ViewController.swift
//  CloudCube
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import UIKit
import ARKit
import MultipeerConnectivity

class ViewController: UIViewController {

    //--------------------
    //MARK: - AR Variables
    //--------------------
    
    @IBOutlet var augmentedRealityView: ARSCNView!
    let augmentedRealitySession = ARSession()
    var configuration = ARWorldTrackingConfiguration()
    @IBOutlet weak var statusLabel: UILabel!
    
    //--------------------------
    //MARK: - Apple Focus Square
    //--------------------------
    
    var focusSquare = FocusSquare()
    var canDisplayFocusSquare = true
    var screenCenter: CGPoint {
        let bounds = self.augmentedRealityView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    let updateQueue = DispatchQueue(label: "blackMirroz")
    
    //--------------
    // MARK: - Model
    //--------------
    var currentAngleY: Float = 0.0
    var modelNode: SCNNode?
    var placementGesture: UITapGestureRecognizer!
    var planeDetected = false
    var modelExists = false
    var colourToUse: UIColor?
    var faceIndex: Int?
    
    @IBOutlet var colourButtons: [UIButton]!
    
    //------------------
    // MARK: - Multipeer
    //------------------
    
    var mapProvider: MCPeerID?
    var cloudSession: ARCloudShare!
    let CLOUD_ANCHOR_ID = "blackMirrorzAnchor"
    @IBOutlet weak var mappingStatusLabel: UILabel!
    @IBOutlet weak var shareButton: UIImageView!
    
    //------------------------
    // MARK: - View Life Cycle
    //------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1. Initialize The Sharing Session
        cloudSession = ARCloudShare(receivedDataHandler: receivedData)
        
        //2. Setup Our Placement Gesture Recognizet
        setupGestures()
        
        colourButtons.forEach { $0.addTarget(self, action: #selector(setFaceColour(_:)), for: .touchUpInside) }

    }
    
    override func viewDidAppear(_ animated: Bool) { setupARSession() }
    

    //----------------------
    // MARK: - Data Handling
    //----------------------
    
    /// Handles The Data Received From Our ARMultipeer Session
    ///
    /// - Parameters:
    ///   - data: Data
    ///   - peer: MCPeerID
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        //1. Try To UnArchive Our Data As An ARWorldMap
        if  let unarchivedMap = try? NSKeyedUnarchiver.unarchivedObject(of: ARWorldMap.classForKeyedUnarchiver(), from: data),
            let worldMap = unarchivedMap as? ARWorldMap {
            
            //2. Now A Map Is Available Restart The Session
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.initialWorldMap = worldMap
            self.augmentedRealityView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            mapProvider = peer
            
        }
        //2. Try To Unarchive Our Data As An ARAnchor
        else if let unarchivedAnchor = try? NSKeyedUnarchiver.unarchivedObject(of: ARAnchor.classForKeyedUnarchiver(), from: data),
            let anchor = unarchivedAnchor as? ARAnchor {
            
            augmentedRealitySession.add(anchor: anchor)
        }
           
        //3. Try To Unarchive Our Data To Adjust The Scale & Or Rotation Of Our Model
        else if let unarchivedData = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data){
            
            if unarchivedData is Float, let unarchivedRotationData = unarchivedData as? Float, let model = modelNode {
                
                model.eulerAngles.y = unarchivedRotationData
                
            }else if unarchivedData is SCNVector3, let unarchivedScaleData = unarchivedData as? SCNVector3, let model = modelNode {
                
                model.scale = unarchivedScaleData
                
            }else if unarchivedData is [Int: UIColor], let colourDictionary = unarchivedData as? [Int: UIColor], let _ = modelNode{
              
                guard let index = colourDictionary.keys.first, let colour = colourDictionary[index] else { return }
                colourToUse = colour
                setFaceColourFromGeometryIndex(index)
                colourToUse = nil
            }
            else {
                print("Unknown Data Recieved From = \(peer)")
                
            }
        }
        
    }
    
    //----------------------------
    // MARK: - Gesture Recongizers
    //----------------------------
    
    /// Adds The Placement Gesture To Our ARSession
    func setupGestures(){
        
        //1. Setup The Placement Gesture Recognizer & Disable It Until An ARPlaneAnchor Has Been Detected
        placementGesture = UITapGestureRecognizer(target: self, action: #selector(placeAnchor(_:)))
        self.view.addGestureRecognizer(placementGesture)
        placementGesture.isEnabled = false
        
        //2. Add A Tap Gesture To Our ImageView To Enable Sharing
        let tapToShareGesture = UITapGestureRecognizer(target: self, action: #selector(shareWorldMap))
        shareButton.addGestureRecognizer(tapToShareGesture)
        
        //3. Add A Rotation Gesture So We Can Rotate Our Model
        let rotationGesture = UIPanGestureRecognizer(target: self, action: #selector(rotateModel(_:)))
        self.view.addGestureRecognizer(rotationGesture)
        
        //3. Add A Scale Gesture So We Can Scale Our Model
        let scaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleModel(_:)))
        self.view.addGestureRecognizer(scaleGesture)
        
        //4. Add A Double Tap Gesture To Colourizer The Face Our Cube
        let tapToColourize = UITapGestureRecognizer(target: self, action: #selector(selectCubeFace(_:)))
        tapToColourize.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapToColourize)
    }
    

    
 
    //-----------------------
    //MARK: - ARSetup & Reset
    //-----------------------

    /// Runs The ARSession
    func setupARSession() {
        
        augmentedRealityView.session = augmentedRealitySession
        configuration.planeDetection = planeDetection(.Horizontal)
        configuration.environmentTexturing = .automatic
        
        augmentedRealityView.debugOptions = debug(.None)
        augmentedRealitySession.run(configuration, options: runOptions(.ResetAndRemove))
       
        augmentedRealityView.delegate = self
        augmentedRealitySession.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    /// Resets The ARSession
    @IBAction func resetSession(){
        
        canDisplayFocusSquare = true
        planeDetected = false
        placementGesture.isEnabled = false
        modelExists = false
        modelNode = nil
        colourToUse = nil
        faceIndex = nil
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = planeDetection(.Horizontal)
        augmentedRealitySession.run(configuration, options: runOptions(.ResetAndRemove))
    }
    

}

