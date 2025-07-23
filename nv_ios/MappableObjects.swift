
//  File.swift
//  NetVision
//
//  Created by compass-362 on 20/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation
import UIKit

extension NvRequest : Mappable {
    // Mappable
    public func mapping(map: Map) {
        ts <- map["ts"]
        status <- map["Status"]
        reqCode <- map["reqCode"]
        var reqdata : String? = nil;
        reqdata <- map["reqData"]
        
        if(reqdata != nil){
        reqData = Mapper<ReqData>().map(JSONString: reqdata!)!
        }
        // call object mapper again
    }
}

extension ActivityTiming : Mappable {
    public func mapping(map: Map) {
        pageInstance <- map["pageInstance"]
        actName <- map["actName"]
        lifeEvent <- map["lifeEvent"]
        ts <- map["ts"]
    }
}

extension NvCapConfig {
    // Mappable
    public func mapping(map: Map) {
        NvCapConfig.beacon_url <- map["beacon_url"]
        NetVision.setHttpReqBeacon(NvCapConfig.beacon_url);
        NvCapConfig.channelId <- map["channelId"]
        config_url <- map["config_url"]
        ua <- map["ua"] ;
        pagedump_mode <- map["pagedump_mode"]
        pendingPIThreshold <- map["pending_queue_instance_diff"]
        NvBackGroundService.setPendingPIThreshold(pi: pendingPIThreshold);
        log_level <- map["log_level"]
        if(map["flushTimeOut"] != nil){
            NvCapConfig.flushTimeOut <- map["flushTimeOut"]
        }
        let dict = map.JSON;
        if(ua == nil){
            ua = UserActionConfig()
        }
        var d : [NSDictionary] = [];

        do {
            try d = dict["actList"] as! [NSDictionary]
        } catch {
             d = [];
        }
        
        while(d.count > 0){
            
            let actdict = d.first!
            
            let ele = NvActivityConfig()
                    
            ele.pageId = actdict["pageId"] as! Int
            ele.activityName = actdict["activityName"] as! String
            //Fixme : check if webViewActivity is marked as compulsory else add condition.
            if(actdict["webviewActivity"] != nil){
                ele.webviewActivity = actdict["webviewActivity"] as! Bool
            }
            else{
                ele.webviewActivity = false;
            }
            actList.append(ele)
            
            d.removeFirst()
        }
        
        // autoTransaction config mapping.
        autoTxn.enable <- map["autoTxn.enable"];
        if dict["autoTxn"] != nil{
            let autoTxn1 = dict["autoTxn"] as! NSDictionary;
            if autoTxn1["filter"] != nil{
                let filter = autoTxn1["filter"] as! NSDictionary;
                autoTxn.getAutoTxnFilter().mode = filter["mode"] as! String;
                var entries = filter["entries"] as! [NSDictionary];
                while(entries.count > 0) {
                    let entri = entries.first!;
                    let ele = FilterEntries();
                    if(entri["t"] != nil){
                        ele.text = entri["t"] as! String;
                    }
                    if(entri["i"] != nil){
                        ele.tag = entri["i"] as! Int;
                    }
                    if(entri["pi"] != nil)
                    {
//                        var list = [AnyObject]()
//                        list = entri["pi"] as! Array<AnyObject> ;
                        let data = entri["pi"] as! String;
                        var list = data.split(separator: ",");
                        while list.count > 0{
                            let dat = list.first!;
//                            ele.pageIndex.append(dat as! Int);
                            ele.pageIndex.append((dat as! NSString).integerValue);
                            list.removeFirst();
                        }
                    }
                    autoTxn.getAutoTxnFilter().filterEntries.append(ele);
                    entries.removeFirst();
                }
            }
        }

        var e : [NSDictionary] = [];
        
        if dict["cmList"] != nil {
            try e = dict["cmList"] as! [NSDictionary]
        }
    
        
        while(e.count > 0){
            
            let cmdict = e.first!
            
            let ele = CustomMetric()
            var pageId,viewId,valueMatchPattern,groupIndex,cmID,type,name   : AnyObject
//            ele.pageId = Int(cmdict["pageId"] as! String)!
           // ele.pageId = 1
            pageId = cmdict["pageId"] as AnyObject
            if pageId is Int{
                ele.pageId = pageId as! Int
            }
            //Need to change input
            //ele.viewId = 3
            
            viewId = cmdict["viewId"] as AnyObject
            if viewId is Int{
                ele.viewId = viewId as! Int
            }
//            ele.viewId = Int(cmdict["viewId"] as! String)!
//            ele.viewId = cmdict["viewId"] as! String
            valueMatchPattern = cmdict["valueMatchPattern"] as AnyObject
            if valueMatchPattern is String{
                ele.valueMatchPattern = valueMatchPattern as! String
            }
//            ele.valueMatchPattern = cmdict["valueMatchPattern"] as! String
            groupIndex = cmdict["groupIndex"] as AnyObject
            if groupIndex is Int{
                ele.groupIndex = groupIndex as! Int
            }
//            ele.groupIndex  = cmdict["groupIndex"] as! Int
            cmID = cmdict["cmID"] as AnyObject
            if cmID is Int{
                ele.cmID = cmID as! Int
            }
            
//            ele.cmID = Int(cmdict["cmID"] as! String)!
            type = cmdict["type"] as AnyObject
            if type is String{
                ele.type = type as! String
            }
            
//            ele.type = cmdict["type"] as! String
            name = cmdict["name"] as AnyObject
            if name is String{
                ele.name = name as! String
            }
//            ele.name = cmdict["name"] as! String
            if pageId is Int && viewId is Int && valueMatchPattern is String && groupIndex is Int && cmID is Int && type is String && name is String{
                cmList.append(ele)
            }
            
            e.removeFirst()
        }
        
        
        
        var f : [NSDictionary] = [];
        
        if(dict["blIdList"] != nil){
            f = dict["blIdList"] as! [NSDictionary]
        }
        
        
        while(f.count > 0){
            
            let bldict = f.first!
            
            let ele = NvBlackListId()
            var pageId : AnyObject
                pageId = bldict["pageId"] as AnyObject
            if pageId is Int{
                ele.pageId = pageId as! Int
            }
           // ele.pageId = bldict["pageId"] as! Int
            //ele.id = Int(bldict["id"] as! String)!
            var id : AnyObject
            id = bldict["id"] as AnyObject
            if id is Int{
                ele.id = id as! Int
            }
            if pageId is Int && id is Int{
                blIdList.append(ele)
            }
            f.removeFirst()
        }
        
        domW.enable <- map["domW.enable"]
        
        var g = NSDictionary();
        var domDictionary : [NSDictionary] = [];
        if(dict["domW"] != nil){
            g = dict["domW"] as! NSDictionary
            if( g["domWList"] != nil) {
                domDictionary = g["domWList"] as! [NSDictionary]
            }
        }
        
        while(domDictionary.count > 0){
            
            let domdict = domDictionary.first!
            
            let ele = DOMWatcherEntry();
            ele.name = domdict["name"] as! NSString as String ;
                
            ele.sel = domdict["sel"] as! NSString as String;
            ele.pageIdList = domdict["pageIdList"] as! [Int];
            
            domW.domWList.append(ele);
            
            domDictionary.removeFirst()
        }
        
        var h = NSDictionary();
        var j = NSDictionary();
        if(dict["monConfig"] != nil) {
            h = dict["monConfig"] as! NSDictionary;
            if h["captureCrossDomain"] != nil{
                self.captureCrossDomain = h["captureCrossDomain"] as! Bool
            }
            if h["captureRSCtiming"] != nil{
                self.captureRCStiming = h["captureRSCtiming"] as! Bool
            }
            
            if( h["filter"] != nil ){
                j = h["filter"] as! NSDictionary
            }
            if( h["captureHeader"] != nil ){
                self.captureHeader = h["captureHeader"] as! Bool;
            }
            if( h["capturePostData"] != nil ){
                self.capturePostData = h["capturePostData"] as! Bool
            }
            if( h["captureResponse"] != nil ){
                self.captureResponse = h["captureResponse"] as! Bool
            }
        }
        
        /* #TODO :  uncomment when config file is corrected
        
        if ( (h["mode"] as! NSString ) != "whiteList" ){
        self.isBlackList = true;
        }
        else {
        self.isBlackList = false
        }
        
        */
        
        // #TODO : this is redundant delete once corrected
        if(j["mode"] != nil){
            if ( (j["mode"] as! NSString ) != "whiteList" ){
                self.isBlackList = true;
            }
            else {
                self.isBlackList = false
            }
        }
        else {
                self.isBlackList = true
        }
        if (j["domain"] != nil){
            //FIXME: Niket - 125560 - Previously Domain was being captured as a String now it is captured as Array Of String.
            let d = j["domain"] as! [String]
            for dmn in d {
                self.domain.append(dmn as! String)
            }
            //self.domain.append((j["domain"] as! String));
        }
    }
}
