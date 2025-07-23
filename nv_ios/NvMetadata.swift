//
//  NvMetadata.swift
//  iOSNetVision
//
//  Created by compass-362 on 03/11/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation
import CoreTelephony;
import UIKit

@objc public class NvMetadata : NSObject {
    
    
    public static var APP = "app";
    public static var APPID = "APPID";
    public static var SCREEN = "-1";
    
    public static var OS = "os";
    
    public static var CONNECTION_TYPE = "conType";
    public static var GEO_MAP = "geoMap" ;
    public static var CARRIER = "carrier"
    public static var METADATA = "NVLocationMetaData"
    public static var GEO_LOCID = "-1" ;
    public static var GEOID = "0" ;
    public static var ACCESSTYPE = "-1" ;
    static var GEO_URL = "URL";
    public static var VERSIONID = "VID";
    public static var VERSION = "versions";
    public var infodictionary : NSDictionary = NSDictionary();
    private static var appStart = "0";
    public static var MANUFACTURE = "Apple"
    public static var MANUFACTUREID = "2"
    let carrierdic : NSDictionary;
    let geoMapDic : NSDictionary;
    let contypeDic : NSDictionary;
    let screenDic : NSDictionary;
    public static var MODEL = "Default";
    public static var MODELID = "Default";
    
    let bundle = Bundle.main
    
    public override init() {
        
        NvMetadata.MODEL = UIDevice.current.model;
        NvMetadata.MODELID = UIDevice.current.model;
        
        let path = bundle.path(forResource: "metadatainfo", ofType: "json") ?? ""
        NSLog("value of path is %@", path);
        var content : String = "";
        do {
            content = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        }
        catch {
        }
        let infodata = content.data(using: String.Encoding.utf8)
        do {
            infodictionary = try JSONSerialization.jsonObject(with: infodata!, options: JSONSerialization.ReadingOptions.allowFragments ) as! NSDictionary;
        }
        catch {
        }
        
        //#1 Code for Retrieving Screen Id
        
        do {
            
            screenDic = (infodictionary["screen"] as? NSDictionary)!
            carrierdic = (infodictionary["carrier"] as? NSDictionary)!
            contypeDic =  (infodictionary["conType"] as? NSDictionary)!
            geoMapDic =  (infodictionary["geoMap"] as? NSDictionary)!
            
        }
        catch {
            return;
        }
        
        let keys = screenDic.allKeys;
        let scLen : NSInteger = Int(UIScreen.main.bounds.height);
        var scWid : NSInteger = Int(UIScreen.main.bounds.width);
        for key in keys {
            if( key as! String == "-1"){
                continue;
            }
            let value = screenDic.object(forKey: key) as! NSString
            let dimensions = value.components(separatedBy: "x");
            let len = NSInteger.init(dimensions[0])!
            let wid = NSInteger.init(dimensions[1])!
            
            if len == scLen && wid == scWid {
                NvMetadata.SCREEN = key as! String;
                break;
            }
            
        }
        
        if( NvMetadata.SCREEN == "-1") {
            //not found dimension
            scWid = scWid << 16;
            scWid = scWid | scLen;
            
            NvMetadata.SCREEN = String(scWid);
        }
        
        //#2 CODE for retrieving appName, version, version Name , app Id
        
        let appName = Bundle.main.infoDictionary!["CFBundleName"] as! String
        let appversion = Int ((((Bundle .main .object(forInfoDictionaryKey: "CFBundleShortVersionString")) as AnyObject).doubleValue)!)
        
        let appDic = infodictionary["app"] as! NSDictionary;
        
        let appKeys = appDic.allKeys;
        
        
        var name = "";
        var app_id = -1;
        var version = "";
        var version_Id = -1;
        var appname = ""
        var appinfo = false;
        for key in appKeys {
            
            let value = appDic.object(forKey: key) as! NSDictionary
            let keys2 = value.allKeys;
            for k in keys2 {
                if( k as! String == "name" || !appinfo ) {
                    name = value.object(forKey: k) as! NSString as String
                    if( name != appName) {
                        
                        break;
                    }
                    else{
                        appinfo = true;
                        appname = name;
                        app_id = Int.init(key as! String)!
                    }
                }
                else{
                    let versionDic = value.object(forKey: k) as! NSDictionary;
                    let keys3 = versionDic.allKeys
                    for ki in keys3 {
                        version_Id = -1;
                        if appversion == Int.init(ki as! String) {
                            version_Id = appversion;
                            version = (versionDic.object(forKey: ki) as! NSDictionary).value(forKey: "name") as! String;
                            break;
                        }
                    }
                }
            }
            
        }
        if(app_id == -1){
            version_Id = -1;
        }
        
        if(version == ""){
            let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject
            
            //Then just cast the object as a String, but be careful, you may want to double check for nil
            version = nsObject as! String
        }
        NvMetadata.VERSION = version;
        
        NvMetadata.VERSIONID = String(version_Id)
        NvMetadata.APP = appName;
        NvMetadata.APPID = String(app_id)
        
    }
    
    static func getAppStart() -> String{
        return NvMetadata.appStart
    }
    
    @objc public static func setAppStart(time : String){
        NvMetadata.appStart = time;
    }
    
    func update_Location() {
        print("GeoDebug: ",NvMetadata.GEOID);
        var pathcsv : String = "" ;
        let geoKeys = geoMapDic.allKeys;
        for key in geoKeys {
            let info = (geoMapDic.object(forKey: key) as! NSDictionary );
            
            if ((info["name"] as! NSString) as String) == Location.country {
                
                //Bug 94997 :- Currently, GEOID handling is only implemented for the '0' case. In the present scenario, we are setting GEOID as a hardcoded value.
                //NvMetadata.GEOID = key as! NSString as String
                NvMetadata.GEOID = "0"
                
                NvMetadata.METADATA = ((info["metadata"] as! String).components(separatedBy: "."))[0];
                break;
            }
        }
        var pcsv : String? = bundle.path(forResource: NvMetadata.METADATA, ofType: "csv")
        var content : String = "";
        if ( pcsv != nil ) {
            pathcsv = pcsv!
            
        }
        else {
            do {
                pathcsv = bundle.path(forResource: "NVLocationMetaData", ofType: "csv")!
                content = try String(contentsOfFile: pathcsv, encoding: String.Encoding.utf8)
            }
            catch{
            }
            let locations = content.components(separatedBy: NSCharacterSet.newlines)
            for location in locations {
                if(location == nil || location.count == 0) { return; }
                let locInfo = location.components(separatedBy: ",")
                if( locInfo[1] == LocationData.country){
                    NvMetadata.GEO_LOCID = locInfo[0]
                    break;
                }
            }
            print("GeoDebug: End1! ",NvMetadata.GEOID);
            return;
        }
        
        do {
            content = try String(contentsOfFile: pathcsv, encoding: String.Encoding.utf8)
        }
        catch {
        }
        
        let locations = content.components(separatedBy: NSCharacterSet.newlines)
        
        for location in locations {
            if(location == nil || location.count == 0) { return; }
            let locInfo = location.components(separatedBy: ",")
            
            if( locInfo[1] == Location.country){
                if (locInfo[2] == Location.state || locInfo[1] == ""){
                    NvMetadata.GEO_LOCID = locInfo[0];
                    break;
                }
            }
        }
        print("GeoDebug: End! ",NvMetadata.GEOID);
    }
    
    func update_conntype() {
        let cellNet : CTTelephonyNetworkInfo = CTTelephonyNetworkInfo();
        let phoneCarrier = cellNet.subscriberCellularProvider;
        if(phoneCarrier == nil){
            NSLog("[NetVision] no carrier detected");
        }
        else {
            NSLog("[NetVision] CTCarrier : %@",phoneCarrier!.description);
        }
        
        let carrKeys = carrierdic.allKeys;
        let conKeys = contypeDic.allKeys;
        var carrier = "-1";
        if(phoneCarrier != nil && phoneCarrier!.carrierName != nil) {
            let carr = phoneCarrier!.carrierName!.lowercased();
            for key in carrKeys {
                carrier = (carrierdic.object(forKey: key) as! NSDictionary).value(forKey: "name") as! String;
                if(carrier.elementsEqual(carr)){
                    carrier = key as! String;
                    break;
                }
            }
        }
        NvMetadata.CARRIER = carrier
        var conn = "-1";
        for key in conKeys {
            carrier = (contypeDic.object(forKey: key) as! NSDictionary).value(forKey: "name") as! String;
            if( NvApplication.getConnectionType() == nil){
                break;
            }
            if(carrier.elementsEqual(NvApplication.getConnectionType())){
                conn = key as! String;
                break;
            }
        }
        NvMetadata.CONNECTION_TYPE = conn;
    }
}
