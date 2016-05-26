//
//  ViewController.swift
//  ActionLabelDemo
//
//  Created by Carlos Alcala on 5/25/16.
//  Copyright © 2016 Carlos Alcala. All rights reserved.
//

import UIKit
import ActionLabel

class ViewController: UIViewController {
    
    let label = ActionLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.customize { label in
            label.text = "Post text #with #multiple #hashtags and some users like @carlosalcala or @twitter. Links are also supported like  http://www.apple.com or http://www.twitter.com/carlosalcala"
            label.numberOfLines = 0
            label.lineSpacing = 6
            
            label.textColor = UIColor(red: 102.0/255, green: 117.0/255, blue: 127.0/255, alpha: 1)
            label.hashtagColor = UIColor(red: 85.0/255, green: 172.0/255, blue: 238.0/255, alpha: 1)
            label.mentionColor = UIColor(red: 238.0/255, green: 85.0/255, blue: 96.0/255, alpha: 1)
            label.URLColor = UIColor(red: 85.0/255, green: 238.0/255, blue: 151.0/255, alpha: 1)
            label.URLSelectedColor = UIColor(red: 82.0/255, green: 190.0/255, blue: 41.0/255, alpha: 1)
            
            label.mentionHandler { self.alert("Mention", message: $0) }
            label.hashtaghandler { self.alert("Hashtag", message: $0) }
            label.linkHandler { self.alert("URL", message: $0.absoluteString) }
        }
        
        self.label.frame = CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 300)
        self.view.addSubview(label)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func alert(title: String, message: String) {
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        vc.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
        presentViewController(vc, animated: true, completion: nil)
    }
    
}


