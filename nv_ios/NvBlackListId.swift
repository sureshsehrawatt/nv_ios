//
//  NvBlackListId.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class NvBlackListId: NSObject , Mappable{
    
    var pageId : Int ;
    var id : Int ;
    
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        pageId <- map["pageId"];
        id <- map["id"]
    }
    
    func getPageId() -> Int {
        return pageId;
    }
    
    func _setPageId(pageId : Int) {
        self.pageId = pageId;
    }
    
    func getId() -> Int {
        return id;
    }
    
    func _setId(id : Int ) {
        self.id = id;
    }
    
    override init() { //
        pageId = 0;
        id = -1;
    }
    
    func toString() -> String {
        var str : String;
        str = "pageId is ";
        str += String ( pageId ) ;
        return  str + "Id  is " + String(id);
    }
    
    
}
