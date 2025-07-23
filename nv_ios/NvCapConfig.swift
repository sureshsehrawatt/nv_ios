//
//  NvCapConfig.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class NvCapConfig: NSObject, Mappable {
    
    convenience required public init?(map: Map) {
        self.init()
    }
    
    static let PAGEDUMP_DISABLE = 0;
    static let PAGEDUMP_NORMAL = 1;
    static let PAGEDUMP_COMPRESSED = 2;
    static var CAV_RUM_SERVICE_AUTH_URL = "";
    static var BrowserId = 21;
    public static var channelId = 0;
    public static var rootViewController = "";
    static var ScreenResolution = -1;
    static var AccessType = -1;
    static var MonitorColorDepth = -1;
    static var Platform = "iOS";
    static var UserAgent = "";
    static var BrowserPlugin = "";
    static var BrowserCname = "";
    static var DoNotTrack = 0;
    static var FF1 = -1;
    static var FFS1 = "";
    static var MobileOsVersion = UIDevice.current.systemVersion; // find version and stuff
    static var protocolversion = 200;
    static var messageversion = 0;
    static var viewId = "";
    static var eventName = "";
    static var screenID = "";
    static var flushTimeOut = 60;
    static var lts = -1;
    
    var autoTxn = NvAutoTransactionConfig()
    var ver : String;
    static var beacon_url : String = "";                  // base url
    static var pagedump_url : String = "";
    var config_url : String = "";			// url to get the configuration from server
    var site_domain : String;					// site domain with which mobile app is interfacing - can they be more than 1
    var pagedump_url : String = "";
    var actList : [NvActivityConfig] = []		// activity config list toidentify the pageId from activity(activity+url pattern if webview in activity)
    var ua = UserActionConfig() ;
    var	domW = DOMWatcher();
    var	pagedump_mode : Int ;
    var log_level : Int ;
    var cmList : [CustomMetric] = [] ;		// custom metric list
    var blIdList : [NvBlackListId] = [] ;
    var pendingPIThreshold = 5;
    var captureCrossDomain = false;
    var captureRCStiming = true;
    var isBlackList = true;
    var domain : [String] = []
    var captureHeader = true;
    var capturePostData = true;
    var captureResponse = true;
    
    override init() {
        // TODO Auto-generated constructor stub
        self.ver = "1.1";
        self.site_domain = "" ;
        self.pagedump_url = "" ;
        self.pagedump_mode = 1;
        self.log_level = 0;
    }
    
    @objc public static func setAuthURL(url : String){
        CAV_RUM_SERVICE_AUTH_URL = url;
    }
    @objc public static func getAuthURL() -> String{
        return CAV_RUM_SERVICE_AUTH_URL;
    }
    @objc public static func setRootViewController(rvc : String) {
        rootViewController = rvc;
    }
    @objc public static func getRootViewController() -> String {
        return rootViewController;
    }
    @objc public static func setChannelId(channel : Int) {
        channelId = channel;
    }
    public static func getChannelId() -> String {
        return String(channelId);
    }
    
    func getVer() -> String {
        return ver;
    }
    func funct(ver : String) { // NOTE : name changed from func to funct
        self.ver = ver;
    }
    func getBeacon_url() -> String {
        return NvCapConfig.beacon_url;
    }
    @objc public static func setBeaconURL(beacon_url : String ) {
        NvCapConfig.beacon_url = beacon_url;
    }
    func _setBeacon_url(beacon_url : String ) {
        NvCapConfig.beacon_url = beacon_url;
    }

    func getSite_domain() -> String {
        return site_domain;
    }
    
    func _setSite_domain(site_domain : String ) {
        self.site_domain = site_domain;
    }
    func getPagedump_url() -> String {
        return pagedump_url;
    }
    @objc public static func setPageDumpURL(pageDump_url : String ) {
        NvCapConfig.pagedump_url = pageDump_url;
    }
    func _setPagedump_url(pagedump_url : String) {
        self.pagedump_url = pagedump_url;
    }
    func getActList() -> [NvActivityConfig] {
        return actList;
    }
    func _setActList(actList : [NvActivityConfig] ) {
        self.actList = actList;
    }
    func getUa() -> UserActionConfig {
        return ua;
    }
    func _setUa( ua : UserActionConfig) {
        self.ua = ua;
    }
    @objc public func getAutoTxn() ->  NvAutoTransactionConfig {
        return autoTxn;
    }
    func _setAutoTxn( autoTxn: NvAutoTransactionConfig ) {
        self.autoTxn = autoTxn;
    }
    func getDomW() ->  DOMWatcher {
        return domW;
    }
    func _setDomW( domW: DOMWatcher ) {
        self.domW = domW;
    }
    func getPagedump_mode() -> Int {
        return pagedump_mode;
    }
    func _setPagedump_mode(pagedump_mode : Int) {
        self.pagedump_mode = pagedump_mode;
    }
    func getLog_level() -> Int{
        return log_level;
    }
    func _setLog_level(log_level : Int) {
        self.log_level = log_level;
    }
    func getCmList() -> [CustomMetric] {
        return cmList;
    }
    func _setCmList(cmList : [CustomMetric]) {
        self.cmList = cmList;
    }
    func getBlIdList() -> [NvBlackListId] {
        return blIdList;
    }
    func _setBlIdList(blIdList : [NvBlackListId] ) {
        self.blIdList = blIdList;
    }
    func getConfig_url() -> String {
        return config_url ;
    }
    func _setConfig_url (config_url : String ) {
        self.config_url = config_url;
    }
}
