//
//  DOMWatcherEntry.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class DOMWatcherEntry: NSObject {
    
    enum DOMWSType  {
        case ID
    }
    
     var name : String ;
     var sType : DOMWSType =  .ID ;
     var sel : String ;				// id string if 'id' type
     var pageIdList = [Int]() //edit
    override init(){
        self.name = "";
        self.sel = "";
    }
    
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        pageIdList <- map["pageId"];
        sel <- map["sel"]
        sType <- map["sType"]
        name <- map["name"]
        
    }
    
    func getName() -> String {
        return name;
    }
    func _setName(name : String ) {
        self.name = name;
    }
    func getsType() -> DOMWSType? {
        return sType;
    }
    func _setsType(sType: DOMWSType ) {
        self.sType = sType;
    }
    func getSel() -> String {
        return sel;
    }
    func _setSel(sel : String ) {
        self.sel = sel;
    }
    func getPageIdList() -> [Int]  {
        return pageIdList;
    }
    func _setPageIdList(pageIdList: [Int] ) {
        self.pageIdList = pageIdList;
    }
}
