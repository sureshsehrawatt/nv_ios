//
//  NvSessionInfo.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

public class NvSessionInfo: NSObject {
    private var serv : NvBackGroundService ; // contxt earlier
    // private var	nll: NvLocationListener? ;//nil value
    static var act: UIViewController? = nil ;
    static var versionCode : String = "1" ;
    static var  versionName: String = "";
    static var  browserLang : String = "";
    static var size : Double? = nil ;
    static var devicetype : String = ""
    let monitorpixeldepth = -1
    
    
    init(serv : NvBackGroundService ){
        self.serv = serv;
        
    }
    
    func getObject( act1: UIViewController) {
        NvSessionInfo.act = act1;
        
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String;
        
        NvSessionInfo.versionName = version;
        NvSessionInfo.versionCode = build;
        
        //catch exception
    }
    
    public static func getMobileConfig()
    {
        
        
        //PackageManager manager=serv.getPackageManager();
        //PackageInfo  info=manager.getPackageInfo(serv.getPackageName(), 0);
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String;
        NvSessionInfo.versionCode = version;
        NvSessionInfo.versionName = build;
        // //NSLog("[NetVision] version : %@, build : %@",NvSessionInfo.versionCode, NvSessionInfo.versionName );
        let curr = NSLocale.current as NSLocale;
        
        if(  curr.object(forKey: NSLocale.Key.languageCode) as? String == nil){
            NvSessionInfo.browserLang = "default-english";
        }
        else {
            NvSessionInfo.browserLang = (curr.object(forKey: NSLocale.Key.languageCode)! as? String)!
        }
        ////NSLog("[NetVision] did get Language %@",NvSessionInfo.browserLang);
        
        
        //DisplayMetrics dm1=serv.getResources().getDisplayMetrics();
        let screenwidth : Double = Double (UIScreen.main.bounds.width)
        let screenheight: Double = Double (UIScreen.main.bounds.height)
        
        NvSessionInfo.size = sqrt( screenwidth*screenwidth + screenheight*screenheight );
        
        if( UIDevice.current.userInterfaceIdiom == .pad) {
            NvSessionInfo.devicetype = "iPad";
            
        }
        else if( UIDevice.current.userInterfaceIdiom == .phone){
            NvSessionInfo.devicetype = "iPhone";
        }
        else {
            NvSessionInfo.devicetype = "Unspecified";
        }
        //screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    }
    
    
    
    func _sendSessionInfo(){
        //Log.e("","sendSessionInfo Called");
        
        let location : CLLocation? = LocationManager.currentLocation.physical;
        if(location == nil){
            return;
        }
        print("[NetVision] \(location)")
        // Initialize the location listener in case location is unknown
        sendSessionInfo(loc: location!);
    }
    
    
    
    
    private func getDeviceInfo() -> String {
        // *****AG Notes******
        /*
         use UIDevice class
         */
        
        let DeviceInfo = UIDevice.current;
        
        var s :String = "";
        
        
        s += "|Name:" + DeviceInfo.name;
        s += "|Model:" + DeviceInfo.model;
        s += "|OS Name:" + DeviceInfo.systemName;
        s += "|OS Version:" + DeviceInfo.systemVersion;
        s += "|Identifier\(DeviceInfo.identifierForVendor)";
        
        let screen = UIScreen.main; // problem 21,18
        
        s += "|width:\(screen.bounds.width)"
        s += "|Height:\(screen.bounds.height)"
        s+="|versionNameofApp:" + NvSessionInfo.versionName;
        s+="|versionCodeOfApp:" + NvSessionInfo.versionCode;
        
        
        return s;
        
    }//end getDeviceSuperInfo
    
}

/*---------- Listener class to get coordinates ------------- */


public func sendSessionInfo(loc : CLLocation ){
    LocationManager.defaultlocation = true;
    let sinfo = SessionInfo();
    let linfo = LocationInfo();
    NvSessionInfo.getMobileConfig();
    
    // remove further updates of location
    // get the location and fill in SessionInfo
//    print("[NetVision] in Session Info")
//    linfo._setLatitude(latitude: (LocationManager.currentLocation.physical.coordinate.latitude));
//    linfo._setLongitude(longitude: LocationManager.currentLocation.physical.coordinate.longitude);
//    linfo._setCity(city: Location.city)
//    linfo._setCountryCode(country: Location.country);
//    linfo._setState(state: Location.state);

    print("[NetVision] in Session Info")
    linfo._setLatitude(latitude: LocationData.latitude);
    linfo._setLongitude(longitude: LocationData.longitude);
    linfo._setCity(city: LocationData.city)
    linfo._setCountryCode(country: LocationData.country);
    linfo._setState(state: LocationData.state);
    
    //NSException(name:"name", reason:"reason", userInfo:nil).raise();
    let dinfo = DeviceInfo()
    print("[NetVision] NvSessionInfo.version Code : \(NvSessionInfo.versionCode)" )
    if(Double(NvSessionInfo.versionCode) == nil){
        dinfo._setAPI(aPI: 1)
    }
    else {
        dinfo._setAPI(aPI: Int(Double(NvSessionInfo.versionCode)!));
    }
    print("[NetVision] Processed Device Info")
    
    let di = UIDevice.current;
    
    dinfo._setDevice(device: di.model);
    dinfo._setScreenWidth(screenWidth: Int(UIScreen.main.bounds.width));
    dinfo._setScreenHeight(screenHeight: Int(UIScreen.main.bounds.height));
    dinfo._setVersionname(String: NvSessionInfo.versionName);
    if(Double(NvSessionInfo.versionCode) == nil){
        dinfo._setVersioncode(versioncode: 1);
    }
    else {
        dinfo._setVersioncode(versioncode: Double(NvSessionInfo.versionCode)!);
    }
    
    
    print("[NetVision] version code set")
    
    // create NvRequest and queue it up from sending
    sinfo._setDinfo(dinfo: dinfo)
    sinfo._setLinfo(linfo: linfo)
    
    let nvr = NvRequest();
    nvr._setReqCode(reqCode: NvRequest.REQCODE.SESSIONINFO);
    nvr._setReqData(reqData: sinfo);
    NvPermission.didGetSessionInfo = true;
    NvCapture.getActivityMonitor().addRequest(nvr: nvr,priority: true);
    
}
