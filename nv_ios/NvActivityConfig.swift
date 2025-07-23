//
//  NvActivityConfig.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class NvActivityConfig: NSObject {
    var activityName : String = "" ;   // ends with string of activity name
    var	pageId : Int = -1;		// pageId being used by the server for self page/activity
    var webviewActivity : Bool = false ;  // if self is an activity that uses webviewt show content
    var url = [String]()             // url pattern(s) to define page in webview
    
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        pageId <- map["pageId"];
        activityName <- map["id"]
        webviewActivity <- map["webviewActivity"]
        url <- map["url"]
    }
    
    override init(){
        webviewActivity = false;
    }
    
    func getActivityName() -> String  {
        return activityName;
    }
    func _setActivityName(activityName : String ) {
        self.activityName = activityName;
    }
    func getPageId() -> Int {
        return pageId;
    }
    func _setPageId(pageId : Int) {
        self.pageId = pageId;
    }
    func isWebviewActivity() -> Bool{
        return webviewActivity;
    }
    func _setWebviewActivity(webviewActivity : Bool ) {
        self.webviewActivity = webviewActivity;
    }
    func getUrl() -> [String] {
        return url;
    }
    func _setUrl(url : [String] ) {
        self.url = url;
    }
}
