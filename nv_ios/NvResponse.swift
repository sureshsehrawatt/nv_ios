//
//  NvResponse.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit

public class NvResponse : NSObject, Mappable {
    
    required public init?(map: Map) {
        super.init()
        mapping(map: map)
    }
    override init(){
        
    }
    public func mapping(map: Map) {
        code <- map["code"]
        errString <- map["errString"]
        SID <- map["SID"]
        geoId <- (map["geoId"], TransformOf<Int64, NSNumber>(fromJSON: { $0?.int64Value }, toJSON: { $0.map { NSNumber(value: $0) } }))
        accessType <- (map["accesstype"], TransformOf<Int64, NSNumber>(fromJSON: { $0?.int64Value }, toJSON: { $0.map { NSNumber(value: $0) } }))
        locationId <- (map["location_id"], TransformOf<Int64, NSNumber>(fromJSON: { $0?.int64Value }, toJSON: { $0.map { NSNumber(value: $0) } }))
        lts <- (map["lts"], TransformOf<Int64, NSNumber>(fromJSON: { $0?.int64Value }, toJSON: { $0.map { NSNumber(value: $0) } }))
    }
    enum NvResponseCode {
        case SUCCESS
        case UNAUTHENTICATED_REQUEST
    }
    var code : NvResponseCode? = .SUCCESS;  // 0 means success response, otherwise error code
    var errString : String = ""; // Error message in case of error at server end
    var lts : Int64 = 0;        //last time stamp
    var ltsstring : String = "";
    //setting accessType, geoId and locationId.
    var geoId : Int64 = 0;
    var locationId : Int64 = 0;
    var accessType : Int64 = 0;
    
    var SID : String = "" ;
    func getSID() -> String {
        return SID;
    }
    
    func _setGeoId( gID : Int64) {
        geoId = gID;
    }
    
    func getGeoId() -> Int64 {
        return geoId
    }

    func _setLocationId( lID : Int64) {
        locationId = lID;
    }
    
    func getLocationId() -> Int64 {
        return locationId
    }
    
    func _setAccessType( accType : Int64 ) {
        accessType = accType;
    }
    
    func getAccessType() -> Int64 {
        return accessType
    }
    
    func _setSID( sID : String) {
        SID = sID;
    }
    
    func getCode() -> NvResponseCode {
        return code!
    }
    
    
    func _setCode(code: NvResponseCode?) {
        self.code = code
    }
    
    
    func getErrString() -> String {
        return errString;
    }
    
    func _setErrString (errString : String) {
        self.errString = errString;
    }
    
}

public class ConfigResponse : NvResponse {
    
    var config : String = "" ;
    func getConfig() -> String {
        return config;
    }
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        config <- map["config"]
    }
    
    func _setConfig(config : String) {
        self.config = config;
    }
    override init(){
        super.init();
    }
    
    required public init?(_ map: Map) {
      super.init();
        mapping(map: map)
    }
    
    required public init?(map: Map) {
        super.init();
        mapping(map: map)
    }
}


public class AuthResponse : NvResponse {
    
    var config_url : String = "";
    
    func getConfig_url() -> String {
        return config_url;
    }
    
    func _setConfig_url(config_url : String) {
        self.config_url = config_url;
    }
    
    required public init?(_ map: Map) {
        super.init();
        mapping(map: map)
    }
    override init(){
        super.init();
    }
    
    required public init?(map: Map) {
        super.init();
        mapping(map: map)
    }
    
    override public func mapping(map: Map) {
        //super.mapping(map)
        config_url <- map["config_url"]
    }
    
}

public class PagedumpResponse : NvResponse {
    
    
    var ETAG : String? = "";
    
    func getETAG()->String? {
        return ETAG ;
    }
    
    func _setETAG(eTAG: String?) {
        ETAG = eTAG;
    }
    
    required public init?(_ map: Map) {
        super.init();
        mapping(map: map)
    }
    override init(){
        super.init();
    }
    
    required public init?(map: Map) {
        super.init();
        mapping(map: map)
    }
    override public func mapping(map: Map) {
        super.mapping(map: map)
        ETAG <- map["ETAG"]
    }
    
}

public class UserActionResponse : NvResponse {
    
    required public init?(_ map: Map) {
        super.init();
        mapping(map: map)
    }
    override init(){
        super.init();
    }
    
    required public init?(map: Map) {
        super.init();
        mapping(map: map)
    }
    override public func mapping(map: Map) {
        super.mapping(map: map)
    }
}

