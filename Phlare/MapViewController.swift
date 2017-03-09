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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet weak var Label: UILabel!
    var LabelText = String()
    // Properties
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var connections: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var myLocation: CLLocationCoordinate2D!
    var othersLocation: CLLocationCoordinate2D?
    
    let locationManager = CLLocationManager()
    let communicationManager = CommunicationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Label.text = LabelText
        
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
        var lat,long: String
        var latCoord, longCoord: Double
        self.tempLabel.text = location
        
        for i in location.characters  //iterate through the string to that the our peer sent us
        {
            if i == "@"
            {
                let index = location.index(location.startIndex, offsetBy: counter)
                lat = location.substring(to:index)
                
                //
                let index2 = location.index(location.startIndex, offsetBy: (counter + 1))
                long = location.substring(from:index2)
                
                print("Long is: " + long)
                print("Lat is: " + lat)
                
                //lat and long are string, so cast them to doubles
                latCoord = (Double(lat))!
                longCoord = (Double(long))!
                
                othersLocation = CLLocationCoordinate2DMake(latCoord, longCoord)
                
                if (othersLocation != nil && bool == false)
                {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = othersLocation!
                    annotation.title = "Peer Location"
                    annotation.subtitle = "Other User"
                    Map.addAnnotation(annotation)
                    bool = true
                    print("made annotation")
                    //TO DO: if they lose connection, we should remove their annotation too
                }
                
                print("hello")
                break
            }
            counter += 1
        }
    }
    
    // called when an annotation is added
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let annotationIdentifier = "AnnotationIdentifier"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as MKAnnotationView?
        
        if annotationView == nil {
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
    
    func addBounceAnimationToView(view: UIView)
    {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale") as CAKeyframeAnimation
        bounceAnimation.values = [ 0.05, 1.1, 0.9, 1]
        
        let timingFunctions = NSMutableArray(capacity: bounceAnimation.values!.count)
        
        for i in 0 ..< bounceAnimation.values!.count {
            timingFunctions.add(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        bounceAnimation.timingFunctions = timingFunctions as NSArray as? [CAMediaTimingFunction]
        bounceAnimation.isRemovedOnCompletion = false
        
        view.layer.add(bounceAnimation, forKey: "bounce")
    }
    
    /* func backgroundThread()
     {
     if (othersLocation != nil)
     {
     let annotation = MKPointAnnotation()
     annotation.coordinate = othersLocation!
     annotation.title = "Peer Location"
     annotation.subtitle = "Other User"
     Map.addAnnotation(annotation)
     print("made annotation")
     }
     }
     */
    
    
    @IBAction func buttonPressed(_ sender: Any)  //if the button is pressed, we call sendLocation so that we send our location (myLocation) to nearby devices
    {
        communicationManager.sendLocation(userLocation: myLocation, myFaceBookID: LabelText)   ///COME BACK HERE
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
    
    
    func sendLocation(userLocation: CLLocationCoordinate2D, myFaceBookID: String) //so we're trying to send our location to nearby devices and our Facebook ID
    {
        //initialize lat and long
        var lat = " "
        var long = " "
        
        //cast your latitude and longitude to strings
        lat = String(userLocation.latitude)
        long = String(userLocation.longitude)
        
        var coordinates: String
        coordinates = lat + "@" + long + myFaceBookID
    
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
    
    func peerLocation(manager: CommunicationManager, userLocation: String )  //used to be called locationChanged
    {
        OperationQueue.main.addOperation
        {
                self.setPeerLocation(location:userLocation)  //used to be called changeLocation
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
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
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
