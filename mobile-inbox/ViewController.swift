//
//  ViewController.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/22/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import UIKit
import Alamofire
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("[OpenIAM]: app is running")
        let client = AuthCookieClient(server: "http://lnx1.openiamdemo.com")
        client.login(username: "Administrator", password: "passwd$11") {
            response in
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

