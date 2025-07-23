//
//  NvApplication.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import UIKit
import CoreTelephony

public class NvApplication : UIResponder, UIApplicationDelegate {

    private static var osVersion: String = UIDevice.current.systemVersion;
    private static var mobileCarrierId: Int = -1;
    private static var applicationId: Int = -1;
    private static var applicationVersionId: Int = -1;
    private static var deviceModel: String = UIDevice.modelName;
    private static var connectionType: String = "unknown";
    private static var carrierName: String = CoreTelephony.CTCarrier().carrierName ?? "";
    private static var sessId : String = formatSID(sid: 0) ;
    private static var pageId  : Int = -1 ;
    static var pageInstance : Int = 0;
    private	static var snapShotInstance : Int = 0;
    private static var app : UIApplication? = nil ;
    private static var lastPageDumpId : Int = 0 ;
    
    private static var appStrTime : Double = 0;
    static var serv : NvBackGroundService? = nil ;
    private static var lastPageDumpTS: Int64 = 0;
    private static var screenWidth : CGFloat = UIScreen.main.applicationFrame.width
    private static var screenHeight : CGFloat = UIScreen.main.applicationFrame.height
    
    private static var browserId : Int = 21;
    private static var storeId : Int = -1;
    private static var terminalId : Int = -1;
    private static var associateId : String = "";
    private static var apiKey : String = "";
    private static var authKey : String = "" ;
    static var MobileAppversion : String = "1.1" ;//public
    static var MonitorPixelDepth : Int = 0;
    static var BrowserLanguage :String = "";
    static var size : Double? = nil;
    static var DeviceType: String? = nil;// \public
    
    
    
    
    enum RadioAccessTechnology: String {
        case cdma = "CTRadioAccessTechnologyCDMA1x"
        case edge = "CTRadioAccessTechnologyEdge"
        case gprs = "CTRadioAccessTechnologyGPRS"
        case hrpd = "CTRadioAccessTechnologyeHRPD"
        case hsdpa = "CTRadioAccessTechnologyHSDPA"
        case hsupa = "CTRadioAccessTechnologyHSUPA"
        case lte = "CTRadioAccessTechnologyLTE"
        case rev0 = "CTRadioAccessTechnologyCDMAEVDORev0"
        case revA = "CTRadioAccessTechnologyCDMAEVDORevA"
        case revB = "CTRadioAccessTechnologyCDMAEVDORevB"
        case wcdma = "CTRadioAccessTechnologyWCDMA"

        var description: String {
            switch self {
            case .gprs, .edge, .cdma:
                return "2G"
            case .lte:
                return "4G"
            case .hrpd, .hsdpa, .hsupa, .rev0, .revA, .revB, .wcdma:
                return "3G"
            }
        }
    }
    
    static func _init ( app: UIApplication ) { // supposed to be an external function
        
        pageId = 0;
        let networkInfo = CoreTelephony.CTTelephonyNetworkInfo()
        let tecnology = RadioAccessTechnology(rawValue: networkInfo.currentRadioAccessTechnology ?? "");
        NvApplication.connectionType = tecnology?.description ?? "";
        NSLog("[NetVision] [NvApplication] connection type is : \(NvApplication.connectionType)");
    }

    static func setConnType() {
        guard let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.google.com") else {
            NvApplication.connectionType = "NO INTERNET"
            return;
        }

        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)

        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        if isReachable {
            if isWWAN {
                let networkInfo = CTTelephonyNetworkInfo()
                var carrierType:[String: String]?;
                if #available(iOS 12.0, *) {
                    carrierType = networkInfo.serviceCurrentRadioAccessTechnology
                } else {
                    
                    // Fallback on earlier versions
                }

                guard let carrierTypeName = carrierType?.first?.value else {
                    NvApplication.connectionType = "UNKNOWN"
                    return;
                }

                switch carrierTypeName {
                case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
                    NvApplication.connectionType = "2G"
                    return;
                case CTRadioAccessTechnologyLTE:
                    NvApplication.connectionType = "4G"
                    return;
                default:
                    NvApplication.connectionType = "3G"
                }
            } else {
                NvApplication.connectionType = "WIFI"
            }
        } else {
            NvApplication.connectionType = "NO INTERNET"
        }
        return;
    }
    
    public static func getAppStrTime() -> Double{
        return NvApplication.appStrTime;
    }
    
    @objc public static func setAppStrTime(time: Double) {
        NSLog("app start time received is %f", time);
        NvApplication.appStrTime = time;
    }
    
    public static func getBrowserId() -> Int{
        return NvApplication.browserId;
    }
    
    public static func setBrowserId(brId : Int){
        NvApplication.browserId = brId;
    }
    
    public static func getOSVersion() -> String {
        return NvApplication.osVersion;
    }
    
    public static func getMobileCarrierId() -> Int {
        return NvApplication.mobileCarrierId;
    }
    
    public static func getApplicationId() -> Int {
        return NvApplication.applicationId;
    }
    
    public static func getConnectionType() -> String {
        return NvApplication.connectionType;
    }
    
    public static func getApplicationVersionId() -> Int {
        return NvApplication.applicationVersionId;
    }
    
    public static func getDeviceModel() -> String {
        return NvApplication.deviceModel;
    }
    
    @objc(getSessId)
    public static func getSessId() -> String {
        return NvApplication.sessId
    }

    static func _setSessId( sessIdentifier : String) {
        if(sessIdentifier == "0"){
            NvApplication.sessId = formatSID(sid: 0)
        }
        else {
            NvApplication.sessId = sessIdentifier;
        }
    }

    @objc(getPageId)
    public static func getPageId() -> Int {
        return NvApplication.pageId;
    }
    
    static func _setPageId(int pageIdentifier : Int) {
        NvApplication.pageId = pageIdentifier;
    }
    
    @objc public static func getpageInstance() -> Int  {
        if(NvApplication.pageInstance == 0){
            return 1;
        }
        return NvApplication.pageInstance;
    }
    
    static func _setpageInstance( pageIns : Int) {
        NvApplication.pageInstance = pageIns;
    }
    static func getLastPageDumpId() -> Int  {
        return NvApplication.lastPageDumpId ;
    }
    
    static func _setLastPageDumpId(lastPageDumpId : Int) {
        NvApplication.lastPageDumpId = lastPageDumpId;
    }
    
    static func getLastPageDumpTS() -> Int64  {
        return NvApplication.lastPageDumpTS;
    }
    
    static func _setLastPageDumpTS(long lastPageDumpTS : Int64) {
        NvApplication.lastPageDumpTS = lastPageDumpTS;
    }
    static func incrementPageInstance(){
        NvApplication.pageInstance += 1;
    }
    @objc(getSnapShotInstance)
    public static func getSnapShotInstance()  -> Int  {
        return snapShotInstance;
    }
    static func incrementSnapShotInstance(){
        snapShotInstance += 1;
         //NSLog("[NetVision] incremented snapshot instance %li",snapShotInstance);
    }
    
    static func _setSnapShotInstance(snapShotInst : Int ) {
        snapShotInstance = snapShotInst;
    }
    
    static func getApp() -> UIApplication {
        return UIApplication.shared
    }
    
    @objc public static func _setApp() {
        self.app = UIApplication.shared
    }
    
    static func getStoreId() -> Int {
        return storeId;
    }
    
    static func _setStoreId(id: Int){
        NvApplication.storeId = id;
    }
    
    static func getTerminalId() -> Int{
        return terminalId;
    }
    
    static func _setTerminalId(id: Int){
        NvApplication.terminalId = id;
    }
    
    static func getAssociateId() -> String {
        return associateId;
    }
    
    static func _setAssociateId(id: String){
        NvApplication.associateId = id;
    }
    
    static func getApiKey() -> String {
        return NvApplication.apiKey ;
    }
    
    static func _setApiKey(apiKey : String) {
        NvApplication.apiKey = apiKey;
    }
    
    static func getAuthKey() -> String {
        return NvApplication.authKey ;
    }
    
    static func _setAuthKey(authKey : String) {
        NvApplication.authKey = authKey;
    }
    
    static func getScreenWidth()  -> CGFloat  {
        return NvApplication.screenWidth ;
    }
    
    static func _setScreenWidth( screenWidth : CGFloat) {
        NvApplication.screenWidth = screenWidth;
    }
    
    static func getScreenHeight() -> CGFloat {
        return NvApplication.screenHeight;
    }
    
    static func _setScreenHeight(screenHeight : CGFloat) {
        NvApplication.screenHeight = screenHeight;
    }
    
}

public extension UIDevice {
  static let modelName: String = {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    func mapToDevice(identifier: String) -> String {
      #if os(iOS)
      switch identifier {
      case "iPod5,1":                                 return "iPod_Touch_5"
      case "iPod7,1":                                 return "iPod_Touch_6"
      case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone_4"
      case "iPhone4,1":                               return "iPhone_4s"
      case "iPhone5,1", "iPhone5,2":                  return "iPhone_5"
      case "iPhone5,3", "iPhone5,4":                  return "iPhone_5c"
      case "iPhone6,1", "iPhone6,2":                  return "iPhone_5s"
      case "iPhone7,2":                               return "iPhone_6"
      case "iPhone7,1":                               return "iPhone_6_Plus"
      case "iPhone8,1":                               return "iPhone_6s"
      case "iPhone8,2":                               return "iPhone_6s_Plus"
      case "iPhone9,1", "iPhone9,3":                  return "iPhone_7"
      case "iPhone9,2", "iPhone9,4":                  return "iPhone_7_Plus"
      case "iPhone8,4":                               return "iPhone_SE"
      case "iPhone10,1", "iPhone10,4":                return "iPhone_8"
      case "iPhone10,2", "iPhone10,5":                return "iPhone_8_Plus"
      case "iPhone10,3", "iPhone10,6":                return "iPhone_X"
      case "iPhone11,2":                              return "iPhone_XS"
      case "iPhone11,4", "iPhone11,6":                return "iPhone_XS_Max"
      case "iPhone11,8":                              return "iPhone_XR"
      case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad_2"
      case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad_3"
      case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad_4"
      case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad_Air"
      case "iPad5,3", "iPad5,4":                      return "iPad_Air_2"
      case "iPad6,11", "iPad6,12":                    return "iPad_5"
      case "iPad7,5", "iPad7,6":                      return "iPad_6"
      case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad_Mini"
      case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad_Mini_2"
      case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad_Mini_3"
      case "iPad5,1", "iPad5,2":                      return "iPad_Mini_4"
      case "iPad6,3", "iPad6,4":                      return "iPad_Pro_(9.7-inch)"
      case "iPad6,7", "iPad6,8":                      return "iPad_Pro_(12.9-inch)"
      case "iPad7,1", "iPad7,2":                      return "iPad_Pro_(12.9-inch)_(2nd generation)"
      case "iPad7,3", "iPad7,4":                      return "iPad_Pro(10.5-inch)"
      case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad_Pro(11-inch)"
      case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad_Pro(12.9-inch)_(3rd generation)"
      case "AppleTV5,3":                              return "Apple_TV"
      case "AppleTV6,2":                              return "Apple_TV_4K"
      case "AudioAccessory1,1":                       return "HomePod"
      case "i386", "x86_64":                          return "Simulator_\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
      default:                                        return identifier
      }
      #elseif os(tvOS)
      switch identifier {
      case "AppleTV5,3": return "Apple_TV_4"
      case "AppleTV6,2": return "Apple_TV_4K"
      case "i386", "x86_64": return "Simulator_\(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
      default: return identifier
      }
      #endif
    }
    
    return mapToDevice(identifier: identifier)
  }()
}
