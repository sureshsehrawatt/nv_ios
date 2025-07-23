//
//  DOMWatcher.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class DOMWatcher: NSObject {
    var enable : Bool ;
    var domWList = [DOMWatcherEntry]() ;

    override init ()  {
        enable = false;
    }
    
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        enable <- map["enable"];
        var dwlist : [DOMWatcherEntry] = [DOMWatcherEntry]()  ;
        dwlist <- map["domWList"];
        
    }
    
    
    func getDomWList() -> [DOMWatcherEntry] {
        return domWList;
    }

    func getEnable() -> Bool {
        return enable;
    }
}
