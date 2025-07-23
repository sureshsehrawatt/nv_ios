//
//  UserActionConfig.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class UserActionConfig: NSObject {
    var enable : Bool;
    var clubThreshold : Int64
    
    override init(){
        self.enable=false;
        self.clubThreshold = 10;
    }
    func isEnable() -> Bool {
        return enable;
    }
     func setEnable(){
        self.enable=true;
    }
     func setclubThreshold ( clubthreshold : Int64 ){
        self.clubThreshold=clubthreshold;
    }
     func getclubThreshold() -> Int64 {
        return clubThreshold;
    }
}
