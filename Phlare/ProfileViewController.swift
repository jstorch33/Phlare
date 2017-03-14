//
//  ProfileViewController.swift
//  Phlare
//
//  Created by Jack Storch on 3/11/17.
//  Copyright © 2017 Brian Li. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ProfileViewController: UIViewController
{
    
    @IBOutlet weak var PhoneNumber: UITextField!
    
    
    var name = String()
    var id = String()
    let phlareManager = PhlareManager()
    
    var NameAndPhoneNumber = ""
    
    var myName = String()
    var myID = String()
    
    @IBOutlet weak var namelabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var sendPhlareButton: UIButton!
    @IBOutlet weak var tempLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        namelabel.text = name
        image.image = getProfPic(id: id)

        phlareManager.delegate = self
        
        tempLabel.text = myName
        
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    
    }
    
    func getProfPic(id: String) -> UIImage?
    {
        if (id != "")
        {
            let imgURLString = "http://graph.facebook.com/" + id + "/picture?type=large" //type=normal
            let imgURL = NSURL(string: imgURLString)
            let imageData = NSData(contentsOf: imgURL! as URL)
            let image = UIImage(data: imageData! as Data)
            return image
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendPhlarePressed(_ sender: Any)
    {
        NameAndPhoneNumber = PhoneNumber.text! + myName
        phlareManager.sendData(ID_and_Name: myName)   ///COME BACK HERE
    }
    
    func setData(data: String)
    {
        self.tempLabel.text = data
    }
    
    func dismissKeyboard()
    {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}

protocol PhlareManagerDelegate
{
    func connectedDevicesChanged(manager : PhlareManager, connectedDevices: [String])
    func peerData(manager: PhlareManager, userData: String)
}

class PhlareManager: NSObject
{
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    
    var delegate : PhlareManagerDelegate?
    
    private let CommunicationType = "example-data"
    
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name) //identifies your app and the user to nearby devices
    
    private let serviceAdvertiser : MCNearbyServiceAdvertiser //notifies its delegate about invitations from nearby peers
    private let serviceBrowser : MCNearbyServiceBrowser  //Searches for services offered by nearby devices using Wi-Fi, peer-to-peer Wi-Fi, and Bluetooth or Ethernet, provides ability to invite those devices to a Multipeer Connectivity session (MCSession)
    
    override init()
    {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: CommunicationType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: CommunicationType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit
    {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session : MCSession =
        {
            let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
            return session
    }()
    
    func sendData(ID_and_Name: String)
    {
        if session.connectedPeers.count > 0
        {
            do
            {
                try self.session.send(ID_and_Name.data(using: .utf8 )!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error
            {
                NSLog("%@", "Error for sending location: \(error)")
            }
        }
    }
}


extension ProfileViewController : PhlareManagerDelegate
{
    func connectedDevicesChanged(manager: PhlareManager, connectedDevices: [String])
    {
        OperationQueue.main.addOperation
            {
            
        }
    }
    
    func peerData(manager: PhlareManager, userData: String )  //used to be called locationChanged
    {
        OperationQueue.main.addOperation
            {
                self.setData(data:userData)  //used to be called changeLocation
        }
    }
    
}

extension PhlareManager : MCNearbyServiceAdvertiserDelegate
{
    func advertiser2(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error)
    {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

extension PhlareManager : MCNearbyServiceBrowserDelegate
{
    func browser2(_ browser2: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error)
    {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?)
    {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)
    {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

extension PhlareManager : MCSessionDelegate
{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) //you get some data from a peer
    {
        NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        self.delegate?.peerData(manager:self, userData: str) //call peerLocation with the data the peer sent you
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID)
    {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress)
    {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?)
    {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}

