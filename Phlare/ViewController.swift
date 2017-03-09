//
//  ViewController.swift
//  Phlare
//
//  Created by Brian Li on 2/13/17.
//  Copyright © 2017 Brian Li. All rights reserved.
//

import UIKit
import FBSDKLoginKit


class ViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate
{

    var myString = ""
    
    // MARK: Properties
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //facebook login button
        let loginButton = FBSDKLoginButton()
        loginButton.alpha = 0.95
        loginButton.frame = CGRect(x: 200, y: 200, width: 200, height: 50)
        loginButton.center = self.view.center
        view.addSubview(loginButton)
        loginButton.delegate = self
        
        // background image
        backgroundImage.image = #imageLiteral(resourceName: "background")
        
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!)
    {
        if error != nil
        {
            print("Something went wrong...\(error)")
            return
        }
        print("Successfully logged in Facebook")
        
        
        
        //var result
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
            
            self.myString = fbid! as! String
            print(result!)
        }
        
        self.performSegue(withIdentifier: "showMap", sender: self)
    }

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!)
    {
        print("Successfully logged out of Facebook")
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let DestViewController : MapViewController = segue.destination as! MapViewController
        DestViewController.LabelText = myString
    }
}

