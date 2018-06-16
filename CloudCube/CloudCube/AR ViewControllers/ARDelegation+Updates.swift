//
//  ARDelegation+Updates.swift
//  CloudCube
//
//  Created by Josh Robbins on 16/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import ARKit

//--------------------------
// MARK: - ARSessionDelegate
//--------------------------

extension ViewController: ARSessionDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async { self.updateFocusSquare() }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
       
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
             shareButton.isUserInteractionEnabled = false
        case .extending:
             shareButton.isUserInteractionEnabled = !cloudSession.connectedPeers.isEmpty
        case .mapped:
             shareButton.isUserInteractionEnabled = !cloudSession.connectedPeers.isEmpty
        }
        
        if canShowControls{
           mappingStatusLabel.text = frame.worldMappingStatus.description
        }
       
        updateUserSessionInformationFor(frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        //1. Update The Seesion Information
        updateUserSessionInformationFor(session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func sessionWasInterrupted(_ session: ARSession) { statusLabel.text = "Session Was Interrupted" }
    
    func sessionInterruptionEnded(_ session: ARSession) { statusLabel.text = "Session Resumed" }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
        statusLabel.text = "AR Session Failed"
        resetSession()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool { return true }
}

//--------------------------
// MARK: - ARSCNViewDelegate
//--------------------------

extension ViewController: ARSCNViewDelegate{
        
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        //1. If Our ARAnchor Matches Our Anchor Name & We Havent Placed Our Cube Then Display It
        if anchor.name == CLOUD_ANCHOR_ID{
            
            if !modelExists{
                modelNode = Box(colours: [.red, .green, .blue, .purple, .orange, .cyan], images: nil)
                canDisplayFocusSquare = false
                node.addChildNode(modelNode!)
                modelExists = true
        
            }
           
        }
    }
}

//----------------------------
// MARK: - User Status Updates
//----------------------------

extension ViewController{
    
    /// Updates The User Regarding The Tracking State Of The ARSession & Whether They Are Connected To Any Peers
    ///
    /// - Parameters:
    ///   - frame: ARFrame
    ///   - trackingState: ARCamera.TrackingState
    func updateUserSessionInformationFor(_ frame: ARFrame, trackingState: ARCamera.TrackingState){
        
        let displayMessage: String
        
        //1. Adjust The Information Based On The Tracking State
        switch trackingState {
        case .normal where frame.anchors.isEmpty && cloudSession.connectedPeers.isEmpty:
            
            displayMessage = "Please Move Around To Map The Environment Or Wait To Join A Shared Session."
            
        case .normal where !cloudSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = cloudSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            displayMessage = "You Are Connected With \(peerNames)."
            
        case .notAvailable:
            displayMessage = "Tracking Unavailable"
            
        case .limited(.excessiveMotion):
            displayMessage = "Please Slow Your Movement"
            
        case .limited(.insufficientFeatures):
            displayMessage = "Try To Point At A Flat Surface"
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            displayMessage = "Receiving ARMap From \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            displayMessage = "Resuming ARSession"
            
        case .limited(.initializing):
            displayMessage = "Initializing"
            
        default:
            
            displayMessage = ""
            
        }
        
        if canShowControls{
            //2. Update The Display Message Or Hide If Neccessary
            statusLabel.text = displayMessage
            statusLabel.isHidden = displayMessage.isEmpty
        }
    
    }

}

//------------------
//MARK: Focus Square
//------------------

extension ViewController{
    
    func updateFocusSquare() {
        
        //1. If Our Model Has Been Placed Hide The Focus Square
        if !canDisplayFocusSquare {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
        }
        
        if let camera = self.augmentedRealitySession.currentFrame?.camera,
            case .normal = camera.trackingState,
            let result = self.augmentedRealityView.smartHitTest(screenCenter) {
            updateQueue.async {
                
                if self.canDisplayFocusSquare{
                    self.augmentedRealityView.scene.rootNode.addChildNode(self.focusSquare)
                    self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
                    
                    
                    //2. Only Allow Placement Of Our Cube If We Have Detected An ARPlaneAnchor
                    if !self.focusSquare.isOpen{
                        self.planeDetected = true
                        self.placementGesture.isEnabled = true
                    }else{
                        self.planeDetected = false
                        self.placementGesture.isEnabled = false
                    }
                }
            }
            
        } else {
            
            updateQueue.async {
                
                if self.canDisplayFocusSquare{
                    self.focusSquare.state = .initializing
                    self.augmentedRealityView.pointOfView?.addChildNode(self.focusSquare)
                }
            }
        }
    }
}



