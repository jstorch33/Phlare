//
//  MapViewController.swift
//  Phlare
//
//  Created by Jack Storch on 2/20/17.
//  Copyright © 2017 Brian Li. All rights reserved.
//
//
//  MapViewController.swift
//  Phlare
//
//  Created by Jack Storch on 2/20/17.
//  Copyright © 2017 Brian Li. All rights reserved.
//
import UIKit
import MapKit
import CoreLocation
import MultipeerConnectivity
import FBSDKLoginKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet weak var Label: UILabel!
    var LabelText = String()  //label at the bottom with your own facebook data
    var id = "no ID"
    var name = "nothing"
    
    // Properties
    @IBOutlet weak var tempLabel: UILabel!  //coordinates label at the top
    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var connections: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var myFacebookName = "No Facebook Name Recieved"
    var myFacebookID = "No Facebook ID Recieved"
    
    var myLocation: CLLocationCoordinate2D!
    var othersLocation: CLLocationCoordinate2D?
    
    let locationManager = CLLocationManager()
    let communicationManager = CommunicationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Label.text = LabelText
        
        //for loop that parses the facebook ID and facebook ID
        var my_counter = 0
        for i in LabelText.characters  //parse the string that holds our facebookID and name
        {
            if i == "*"
            {
                let index1 = LabelText.index(LabelText.startIndex, offsetBy: my_counter)
                myFacebookID = LabelText.substring(to:index1)
                
                let index2 = LabelText.index(LabelText.startIndex, offsetBy: my_counter + 1)
                myFacebookName = LabelText.substring(from:index2)
            }
            my_counter += 1
        }
        
        communicationManager.delegate = self
        Map.delegate = self
        Map.mapType = MKMapType.standard
        self.locationManager.requestAlwaysAuthorization()  //asks user to use location services
        
        self.locationManager.requestWhenInUseAuthorization() //does the same thing as above, don't really need both
        
        if CLLocationManager.locationServicesEnabled()   //if the user allowed location services
        {
            myLocation = locationManager.location?.coordinate
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()  //will update users location if more accurate location is determined
            self.Map.showsUserLocation = true        //displays user's location on map
        }
        
        //   var timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: Selector("backgroundThread"), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Location Delegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations.last
        
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpanMake(0.001, 0.001))
        
        self.Map.setRegion(region, animated: true)
        
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("Error:" + error.localizedDescription)
    }
    
    func setPeerLocation(location: String)
    {
        var bool = false
        var counter = 0
        var lat = ""
        var long = ""
        var facebook_ID = ""
        var facebook_name = ""
        var atIndex = 0
        var ampersandIndex = 0
        var latCoord, longCoord: Double
        self.tempLabel.text = location
        print("Hockey: " + self.tempLabel.text!)
        
        for i in location.characters  //iterate through the string that the our peer sent us
        {
            //location contains peer's latitude, longitude, facebook ID, facebook name
            //these fields are seperated by @, #, and * respectively
            if i == "@"
            {
                let index = location.index(location.startIndex, offsetBy: counter)
                lat = location.substring(to:index)
                
                atIndex = counter
            }
            else if i == "#"
            {
                ampersandIndex = counter
                //this gets the long coordinate
                long = location[location.index(location.startIndex, offsetBy: atIndex + 1)...location.index(location.startIndex, offsetBy: counter - 1)]   //counter will be the ampersand index
                
                print("Long is: " + long)
                print("Lat is: " + lat)
                
                //lat and long are string, so cast them to doubles
                latCoord = (Double(lat))!
                longCoord = (Double(long))!
                
                othersLocation = CLLocationCoordinate2DMake(latCoord, longCoord)
            }
            else if i == "*"
            {
                facebook_ID = location[location.index(location.startIndex, offsetBy: ampersandIndex + 1)...location.index(location.startIndex, offsetBy: counter - 1)]
                print("Other User facebook id is the following: " + facebook_ID)
                
                let name_index = location.index(location.startIndex, offsetBy: (counter + 1)) //index fb name starts at
                facebook_name = location.substring(from: name_index) //will go until the end of the string
                
                print("Other user facebook name is the following: " + facebook_name)
                self.id = facebook_ID
                self.name = facebook_name
            }
            //print("boiii" + self.id)
            //print("boiii" + self.name)
            counter += 1
        }
        
        if (othersLocation != nil && bool == false)
        {
            let annotation = MKPointAnnotation()
            annotation.coordinate = othersLocation!
            //annotation.title = "Peer Location"
            annotation.title = facebook_name + "'s Location"
           // annotation.subtitle = "Other User"
            Map.addAnnotation(annotation)
            bool = true
            print("made annotation")
            
            //TO DO: if they lose connection, we should remove their annotation too
        }
    }
    
    // called when an annotation is added
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as MKAnnotationView?
        
        if annotationView == nil
        {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView!.canShowCallout = true
            annotationView!.tintColor = UIColor.purple
            annotationView!.image = UIImage(named: "burn")
        }
        else {
            annotationView!.annotation = annotation
        }
        self.addBounceAnimationToView(view: annotationView!)
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "toProfile", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if(segue.identifier == "toProfile")
        {
            let DestViewController : ProfileViewController = segue.destination as! ProfileViewController
            DestViewController.id = self.id
            DestViewController.name = self.name
            DestViewController.myName = self.myFacebookName
            DestViewController.myID = self.myFacebookID
        }
        else if(segue.identifier == "ShowMyProfile")
        {
            let DestViewController : UserViewController = segue.destination as! UserViewController
            DestViewController.NameLabelText = self.myFacebookName
            DestViewController.IDLabelText = self.myFacebookID
            print("This is the value of mystring in prepareforsegue: \(self.myFacebookName)")
        }
    
    }
    
    func addBounceAnimationToView(view: UIView)
    {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale") as CAKeyframeAnimation
        bounceAnimation.values = [ 0.05, 1.1, 0.9, 1]
        
        let timingFunctions = NSMutableArray(capacity: bounceAnimation.values!.count)
        
        for i in 0 ..< bounceAnimation.values!.count
        {
            timingFunctions.add(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        bounceAnimation.timingFunctions = timingFunctions as NSArray as? [CAMediaTimingFunction]
        bounceAnimation.isRemovedOnCompletion = false
        
        view.layer.add(bounceAnimation, forKey: "bounce")
    }
    
    @IBAction func buttonPressed(_ sender: Any)  //if the button is pressed, we call sendLocation so that we send our location (myLocation) to nearby devices
    {
        communicationManager.sendLocation(userLocation: myLocation, ID_and_Name: Label.text!)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        self.Label.text = "Loading..."
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start
            {
                (connection, result, err) in
                if err != nil
                {
                    print("fail:", err)
                    return
                }
                
                guard let data = result as? [String:Any] else { return }
                let fbid = data["id"]
                let username = data["name"]
                print("Your Facebook ID is: \(fbid!)")
                print("Your UserName is: \(username!)")
                
                self.myFacebookID = fbid! as! String
                self.myFacebookName = username! as! String
                
            
                //self.Label.text = self.myFacebookID + "*" + self.myFacebookName
        }
    }
}


protocol CommunicationManagerDelegate
{
    func connectedDevicesChanged(manager : CommunicationManager, connectedDevices: [String])
    func peerLocation(manager: CommunicationManager, userLocation: String)
}

class CommunicationManager : NSObject
{
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    
    var delegate : CommunicationManagerDelegate?
    
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
    
    
    func sendLocation(userLocation: CLLocationCoordinate2D, ID_and_Name: String) //so we're trying to send our location to nearby devices and our Facebook ID
    {
        //initialize lat and long
        var lat = " "
        var long = " "
        
        //cast your latitude and longitude to strings
        lat = String(userLocation.latitude)
        long = String(userLocation.longitude)
        
        var coordinates: String
        coordinates = lat + "@" + long + "#" + ID_and_Name   //ID and name are seperated with "*" (done in viewcontroller)
        
        if session.connectedPeers.count > 0
        {
            do
            {
                //send the string of your coordinates to all of your connected peers
                try self.session.send(coordinates.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error
            {
                NSLog("%@", "Error for sending location: \(error)")
            }
        }
    }
}

extension MapViewController : CommunicationManagerDelegate
{
    func connectedDevicesChanged(manager: CommunicationManager, connectedDevices: [String])
    {
        OperationQueue.main.addOperation
            {
                self.connections.text = "Connections: \(connectedDevices)"
        }
    }
    
    func peerLocation(manager: CommunicationManager, userLocation: String )
    {
        OperationQueue.main.addOperation
        {
                self.setPeerLocation(location:userLocation)
        }
    }
}

extension CommunicationManager : MCNearbyServiceAdvertiserDelegate
{
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error)
    {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        //cast your ID and Display name to a string
        let ID = String(describing: MCPeerID(displayName: UIDevice.current.name))
        var ID_Display_Name = ""
        
        //cast the peer's ID and display name to a string
        var Peer_ID = String(describing: peerID)
        var Peer_ID_Display_Name = ""
        
        var counter1 = 0;
        var counter2 = 0;
        
        //parse you ID string to find your display name
       for i in ID.characters
        {
            if i == "="
            {
                let index = ID.index(ID.startIndex, offsetBy: counter1 + 2)
                ID_Display_Name = ID.substring(from:index)
            }
            counter1 += 1
        }
        
        //parse the peer's ID to find his display name
        for i in Peer_ID.characters
        {
            if i == "="
            {
                let index = Peer_ID.index(Peer_ID.startIndex, offsetBy: counter2 + 2)
                Peer_ID_Display_Name = Peer_ID.substring(from:index)
            }
            counter2 += 1
        }

        //if you and the peer that is trying to connect have the same display name, its most likely your own device trying to connect...so just dont accept the invitation to connect
        if ID_Display_Name != Peer_ID_Display_Name
        {
            NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
            invitationHandler(true, self.session)
        }
        
    }
}

extension CommunicationManager : MCNearbyServiceBrowserDelegate
{
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error)
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

extension CommunicationManager : MCSessionDelegate
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
        self.delegate?.peerLocation(manager:self, userLocation: str) //call peerLocation with the data the peer sent you
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
