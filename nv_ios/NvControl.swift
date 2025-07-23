//
//  NvControl.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit

public class NvControl: NSObject {
    
    private var apiKey : String = "";
    private var rumEnabled : Bool = true;
    private var accountAuthenticated : Bool = false;
    private var rumPausedStopped : Bool = false;
    
    override init(){
        rumEnabled = true;
        
        //_setAccountAuthenticated(false);
    }
    
    func isRumEnabled() -> Bool {
        return rumEnabled;
    }
    
    func _setRumEnabled(rumEnabled : Bool) {
        self.rumEnabled = rumEnabled;
    }
    
    func isRumPausedStopped() -> Bool{
        return rumPausedStopped
    }
    
    func _setRumPausedStopped(rumPausedStopped : Bool){
        self.rumPausedStopped = rumPausedStopped
    }
    
    func getApiKey() -> String {
        return apiKey;
    }
    
    func _setApiKey(apiKey :String) {
        self.apiKey = apiKey;
    }
    
    func isAccountAuthenticated() -> Bool {
        return accountAuthenticated;
    }
    
    func _setAccountAuthenticated(accountAuthenticated: Bool) {
        self.accountAuthenticated = accountAuthenticated;
    }
}
