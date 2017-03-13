//
//  ProfileViewController.swift
//  Phlare
//
//  Created by Jack Storch on 3/11/17.
//  Copyright © 2017 Brian Li. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    var name = String()
    var id = String()
    
    @IBOutlet weak var namelabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.namelabel.text = name
        self.image.image = getProfPic(id: id)
    }
    
    func getProfPic(id: String) -> UIImage? {
        if (id != "") {
            var imgURLString = "http://graph.facebook.com/" + id + "/picture?type=large" //type=normal
            var imgURL = NSURL(string: imgURLString)
            var imageData = NSData(contentsOf: imgURL as! URL)
            var image = UIImage(data: imageData as! Data)
            return image
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
