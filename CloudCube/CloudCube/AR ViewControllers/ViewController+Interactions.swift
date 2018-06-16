//
//  ViewController+Interactions.swift
//  CloudCube
//
//  Created by Josh Robbins on 16/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

extension ViewController{
    
    //-----------------------------------
    // MARK: - World Map & Anchor Sharing
    //-----------------------------------
    
    /// Shares An ARWorldMap With Any Connected Users
    @IBAction func shareWorldMap(){
        
        //1. Attempt To Get The World Map From Our ARSession
        augmentedRealitySession.getCurrentWorldMap { worldMap, error in
            
            guard let mapToShare = worldMap else { print("Error: \(error!.localizedDescription)"); return }
            
            //2. We Have A Valid ARWorldMap So Send It To Any Peers
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: mapToShare, requiringSecureCoding: true) else { fatalError("Can't Encode Map") }
            self.cloudSession.sendDataToUsers(data)
        }
    }
    
    //-------------------------
    // MARK: - Anchor Placement
    //-------------------------
    
    /// Allows The User To Create An ARAnchor
    ///
    /// - Parameter gesture: UITapGestureRecognizer
    @IBAction func placeAnchor(_ gesture: UITapGestureRecognizer){
        
        //1. Get The Current Touch Location
        let currentTouchLocation = gesture.location(in: self.augmentedRealityView)
        
        //2. Perform An ARSCNHitTest For Any Existing Or Perceived Horizontal Planes
        guard let hitTest = self.augmentedRealityView.hitTest(currentTouchLocation, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]).first else { return }
        
        //3. Create Our Anchor & Add It To The Scene
        let validAnchor = ARAnchor(name: CLOUD_ANCHOR_ID, transform: hitTest.worldTransform)
        self.augmentedRealitySession.add(anchor: validAnchor)
        
        //4. Share The Angle, Rotation & Scale With Peers
        guard let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: validAnchor, requiringSecureCoding: true) else { fatalError("Can't Encode Anchor") }
        self.cloudSession.sendDataToUsers(anchorData)
        
    }
    
    //---------------------------------
    // MARK: - Model Scaling & Rotation
    //---------------------------------
    
    /// Rotates The Model On It's YAxis
    ///
    /// - Parameter gesture: UIPanGestureRecognizer
    @objc func rotateModel(_ gesture: UIPanGestureRecognizer) {
        
        guard let modelNode = modelNode else { return }
        
        let translation = gesture.translation(in: gesture.view!)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        newAngleY += currentAngleY
        
        modelNode.eulerAngles.y = newAngleY
        
        if(gesture.state == .ended) { currentAngleY = newAngleY }
        
        //2. Send It To Any Connected Users
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: newAngleY, requiringSecureCoding: true){
            
            cloudSession.sendDataToUsers(data)
        }
        
    }
    
    /// Scales The Model
    ///
    /// - Parameter gesture: UIPinchGestureRecognizer
    @objc func scaleModel(_ gesture: UIPinchGestureRecognizer) {
        
        guard let nodeToScale = modelNode else { return }
        
        if gesture.state == .changed {
            
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.z))
            let scaleVector = SCNVector3(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            nodeToScale.scale = scaleVector
            
            //2. Send It To Any Connected Users
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: scaleVector, requiringSecureCoding: true){
                
                cloudSession.sendDataToUsers(data)
            }
            
            gesture.scale = 1
            
        }
        if gesture.state == .ended { }
        
    }
    
    //-----------------------
    // MARK: - Cube Colouring
    //-----------------------
    
    /// Sets The Current Face Of The Cube
    ///
    /// - Parameter gesture: UITapGestureRecognizer
    @IBAction func selectCubeFace(_ gesture: UITapGestureRecognizer){
        
        //1. Get The Current Touch Location
        let currentTouchLocation = gesture.location(in: self.augmentedRealityView)
        
        //2. Perform An SCNHitTest
        guard let hitTest = self.augmentedRealityView.hitTest(currentTouchLocation, options: nil).first else { return }
        
        if let index = BoxFaces(rawValue:  hitTest.geometryIndex){
            
            print("User Has Hit \(index)")
            
            //2. Stores The Face Index
            faceIndex = hitTest.geometryIndex
            
            //3. Sets The Face Colour
            setFaceColourFromGeometryIndex(hitTest.geometryIndex)
 
        }
    }
    
    /// Replaces The SCNMaterial For The FaceIndex Of The Cube
    ///
    /// - Parameter index: Int
    func setFaceColourFromGeometryIndex(_ index: Int){
        
        if let validModel = modelNode, let validColour = colourToUse{
            
            let material = SCNMaterial()
            material.diffuse.contents = validColour
            validModel.geometry?.replaceMaterial(at: index, with: material)
            sendColourData()
            colourToUse = nil
            faceIndex = nil
        }
    }
    
    /// Sets The Face Colour Of The Cube
    ///
    /// - Parameter sender: UIButton
    @objc func setFaceColour(_ sender: UIButton){
        
        colourToUse = UIColor(cgColor: sender.layer.borderColor!)
        
        if let validIndex = faceIndex { setFaceColourFromGeometryIndex(validIndex) }
    }
    
    /// Sends The Colour Data
    func sendColourData(){
        
        var colourData = [Int: UIColor]()
        guard let validFaceIndex = faceIndex, let validColour = colourToUse else { return }
        colourData[validFaceIndex] = validColour
        
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: colourData, requiringSecureCoding: true){
            cloudSession.sendDataToUsers(data)
        }
    }
}
