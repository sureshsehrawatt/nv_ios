//
//  CustomMetric.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//


//AG MARK//

import UIKit

public class CustomMetric: NSObject {
    enum CustomMetricType {
        case VIEW
        case COOKIE
    }
    var cmID : Int = 0
    var name : String = "";
    var cmt : CustomMetricType = .VIEW ;
    var type : String = "" ;
    var viewId : Int = -1 ;      // id in string format
    var pageId: Int = -1;		// on which page
    var valueMatchPattern : String = "";   // pattern to match on value of the view/cookie - null if full value string is to be used
    var	groupIndex : Int = 0;     // after applying match pattern which group to be used as value, -1 means use default value 1
    var v : String ;//"0";
    
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        pageId <- map["pageId"]
        viewId <- map["viewid"]
        valueMatchPattern <- map["valueMatchPattern"]
        groupIndex <- map["groupIndex"]
        v <- map["v"]
    }
    
    override init(){
        v = "0";
        
    }
    func getType() -> String {
        return type;
    }
    func _setType (type: String ) {
        self.type = type;
    }
    //TODO: add getter and_setter for type, and cmid.
    func getName() -> String {
        return name;
    }
    func _setName( name : String) {
        self.name = name;
    }
    func getViewId() -> Int {
        return viewId;
    }
    func _setViewId(viewId : Int ) {
        self.viewId = viewId;
    }
    func getCmt() -> CustomMetricType {
        return cmt;
    }
    func _setCmt(cmt : CustomMetricType ) {
        self.cmt = cmt;
    }
    func getPageId() -> Int {
        return pageId;
    }
    func _setPageId(pageId : Int) {
        self.pageId = pageId;
    }
    func getGroupIndex() -> Int {
        return groupIndex;
    }
    func _setGroupIndex(groupIndex : Int) {
        self.groupIndex = groupIndex;
    }
    func getValueMatchPattern() -> String {
        return valueMatchPattern;
    }
    func _setValueMatchPattern(valueMatchPattern : String ) {
        self.valueMatchPattern = valueMatchPattern;
    }
   
    static func matchPattern (  text : String , regex : String ) -> Bool {
        var valid = false;
        do {
            let Regex = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, text.utf16.count)
            let matchRange = Regex.rangeOfFirstMatch(in: text, options: .reportProgress, range: range)
            valid = matchRange.location != NSNotFound
            
        }
        catch {
            //NSLog("[NetVision] false regex");
            
        }
        
        return valid;
        
    }

}
