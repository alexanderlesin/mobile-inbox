//
//  AuthCookieClient.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/22/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AuthCookieClient: RestHelper, RestProtocol {
    
    // MARK: - Members
    let server: String!
    var loginPath: String = "/idp/login.html"
    var refreshPath: String = "/selfservice/myInfo.html"
    
    // MARK: - Initialization
    init(server: String!, loginPath: String? = nil, refreshPath: String? = nil)
    {
        self.server = server
        
        if loginPath != nil {
            self.loginPath = loginPath!
        }
        
        if refreshPath != nil {
            self.refreshPath = refreshPath!
        }
    }
    
    // MARK: - Login
    func login(username: String, password: String, completionHandler: @escaping (RestResponse) -> Void) {
        let parameters: Parameters = ["login": username,
                                      "password": password]
        
        RestHelper.restCall(server + loginPath, method: .post, parameters: parameters) {
            response in
            print("[OpenIAM Login]: Return Value from Server")
            print(response)
            
            if response.error != nil {
                print("[OpenIAM Login]: Login failed")
            }
            
            if response.json?["userId"] == nil || response.json?["error"] == true {
                let message = response.json?["errorList"][0]["message"]
                print("[OpenIAM Login]: \(message ?? "Unknow Error")")
                completionHandler(response)
                return;
            }
            
            print("[OpenIAM Login]: Successfully Login")
            completionHandler(response)
        }
    }
}
