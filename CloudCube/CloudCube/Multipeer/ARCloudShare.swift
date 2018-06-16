//
//  ARCloudShare.swift
//  CloudCube
//
//  Created by Josh Robbins on 15/06/2018.
//  Copyright © 2018 BlackMirrorz. All rights reserved.
//

import Foundation
import MultipeerConnectivity

//--------------------------
// MARK: - MCSessionDelegate
//--------------------------

extension ARCloudShare: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedDataHandler(data, peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This Service Does Not Send Or Receive Streams")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This Service Does Not Send Or Receive Resources")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This Service Does Not Send Or Receive Resources")
    }
    
}

//---------------------------------------
// MARK: - MCNearbyServiceBrowserDelegate
//---------------------------------------

extension ARCloudShare: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        
        //Invite A New User To The Session
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
    
}

//------------------------------------------
// MARK: - MCNearbyServiceAdvertiserDelegate
//------------------------------------------

extension ARCloudShare: MCNearbyServiceAdvertiserDelegate {
    
    //----------------------------------------------------------
    // MARK: - Allows The User To Accept The Invitation To Share
    //----------------------------------------------------------
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        //Allow The User To Accept The Invitation & Join The Twunkl Session
        invitationHandler(true, self.session)
    }
    
}

class ARCloudShare: NSObject{
    
    static let serviceType = "arcloud-share"
    
    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    var session: MCSession!
    var serviceAdvertiser: MCNearbyServiceAdvertiser!
    var serviceBrowser: MCNearbyServiceBrowser!
    let receivedDataHandler: (Data, MCPeerID) -> Void
    
    //-----------------------
    // MARK: - Initialization
    //-----------------------
    
    init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void ) {
        
        self.receivedDataHandler = receivedDataHandler
        
        super.init()
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: ARCloudShare.serviceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: ARCloudShare.serviceType)
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
    }
    
    //---------------------
    // MARK: - Data Sending
    //---------------------
    
    func sendDataToUsers(_ data: Data) {
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Error Sending Data To Users: \(error.localizedDescription)")
        }
    }
    
    //----------------------
    // MARK: - Peer Tracking
    //----------------------
    
    var connectedPeers: [MCPeerID] { return session.connectedPeers }
}
