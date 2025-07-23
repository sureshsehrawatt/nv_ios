//
//  NvCapConfigManager.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit



public class NvCapConfigManager: NSObject {
    private static let TAG = "NvCapConfigManager";
    static let NV_SHARED_PREFERENCE = "nvTrackerSharedPreference";
    private static let NVSPConfigKey = "config";
    static let NVSPConfigMd5 = "configMD5";
    static let NVSPCONFIGMd5Len = 32;
    static let PREFERENCE_KEY = "NvCapture";
    
    private static var instance: NvCapConfigManager? = nil;
    private var nvConfig = NvCapConfig();
    
    
    func _setNvConfig(nvConfig: NvCapConfig ) {
        self.nvConfig = nvConfig
    }
    
    // JSON Library use here
    private var nvControl: NvControl? = nil;
    
    // private static UIApplication app = nil;
    
    var customVar:  String = "";
    
    
    @objc public func getConfig() -> NvCapConfig {
        return nvConfig
    }
    
    @objc public static func getInstance() -> NvCapConfigManager  {
        NSLog("[NetVision NvCapConfigManager] getInstance called");
        if (instance == nil) {
            
            // Create the instance
            //instance = new NvCapConfigManager();
            instance = NvCapConfigManager();
        }
        // Return the instance
        return instance!
    }
    
    func Md5Checksum(string: String) -> String {
        
        /*
        var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
        CC_MD5(data.bytes, CC_LONG(data.length), &digest)
        }
        
        */
        //   var digestHex = ""
        /*
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
        digestHex += String(format: "%02x", digest[index])
        }
        */
        
        return ""
        
    }
    
    
    private override init() {
        super.init()
        nvConfig = loadConfigFromSharedPreferences();
        nvControl = initNvControl();
        
    }
    
    func reloadConfig() {
        nvConfig = loadConfigFromSharedPreferences();
    }
    
    /**
     
     func laodConfigFromNVServer(UIApplication app) {
     Log.e(TAG, "loadConfigFromNVServer Called");
     String configCheckSum = getConfigCheckSum(app);
     NvRequest nvr = new NvRequest();
     ConfigRequest  cr = new ConfigRequest();
     
     nvr._setReqCode(REQCODE.CONFIGREQ);
     nvr._setReqData(cr);
     
     cr._setAuthKey(app.getAuthKey());
     cr._setMd5checksum(configCheckSum);
     
     addRequestInFront(nvr);
     
     }
     
     **/
     
     // TODO: move just kind of function into utils.
    func saveConfigIntoSharedPref( prefString : String) -> Bool {
        //Log.e("","prefString is "+prefString);
        // get md5checksum of string.
        let str : NSMutableString = NSMutableString (string: prefString);
        str.replacingOccurrences(of: "\\s", with: "");
        
        let strng = String(str);
        let configMd5 = String(Md5Checksum(string: strng));
        // TODO: put error message.
        //if (configMd5 != nil) {
        
        //	editor.putString(NVSPConfigMd5, prefString);
        
        //}
        
        let sp = UserDefaults.standard;
        
        sp.setValue(prefString , forKey: NvCapConfigManager.NVSPConfigKey)
        
        sp.setValue(configMd5, forKey: NvCapConfigManager.NVSPConfigMd5)
        
        let didSave = sp.synchronize()
        
        if !didSave {
            //  Couldn't save (I've never seen this happen in real world testing)
            return false;
        }
        return true;
    }
    
    private func loadConfigFromSharedPreferences() -> NvCapConfig {
        NSLog("[NetVision NvCapConfigManager] loadConfigFromSharedPreferences called");
        let sp = UserDefaults.standard;
        NSLog("[NetVision] Load config from SP")
        if sp.object(forKey: NvCapConfigManager.NVSPConfigKey) == nil {
            return NvCapConfig();
        }
        else {
             print("HERE SPCONFIG IS NOT nil");
            var nvConfig = NvCapConfig()
            let string = sp.object(forKey: NvCapConfigManager.NVSPConfigKey) as! NSString as String
            nvConfig = Mapper<NvCapConfig>().map(JSONString: string)!;
            //nvConfig = Mapper<NvCapConfig>().map(string )!
            NSLog("[NetVision] Loaded config!")
            return nvConfig;

        }
        
        /*
        * // TBD - Currently just creating a NvCapConfig inistance and
        * returning that NvCapConfig nvc = new NvCapConfig();
        * nvc._setBeacon_url("http://10.10.60.4/test_rum");
        * nvc._setPagedump_mode(NvCapConfig.PAGEDUMP_COMPRESSED);
        * UserActionConfig ua = new UserActionConfig(); ua._setClubThreshold(1);
        * ua._setEnable(true); nvc._setUa(ua); NvActivityConfig nac = new
        * NvActivityConfig(); nac._setActivityName("MainActivity");
        * nac._setPageId(1); nac._setWebviewActivity(false);
        * List<NvActivityConfig> nacl = new ArrayList<NvActivityConfig>();
        * nacl.add(nac); nac._setActivityName("SecondActivity");
        * nac._setPageId(2); nac._setWebviewActivity(false); nacl.add(nac);
        *
        *
        * nvc._setActList(nacl); return nvc;
        */
//        let nvc = NvCapConfig();
//
//        nvc._setBeacon_url(beacon_url: NvCapConfig.beacon_url);
//        nvc._setPagedump_url(pagedump_url: NvCapConfig.pagedump_url);
////        nvc._setPagedump_url(pagedump_url: NvCapConfig.getPagedump_url(nvc))
//        nvc._setPagedump_mode(pagedump_mode: NvCapConfig.PAGEDUMP_COMPRESSED);
//        let ua = UserActionConfig();
//        ua.setclubThreshold(clubthreshold: 1);
//        ua.setEnable();
//
//
//        nvc._setUa(ua: ua);
//        let nac = NvActivityConfig();
//        nac._setActivityName(activityName: "MainActivity");
//        nac._setPageId(pageId: 1);
//        nac._setWebviewActivity(webviewActivity: false);
//
//        var nacl : [NvActivityConfig] = []
//        nacl.append(nac);
//        nac._setActivityName(activityName: "SecondActivity")
//        nac._setPageId(pageId: 2)
//        nac._setWebviewActivity(webviewActivity: false)
//        nacl.append(nac)
//        nvc._setActList(actList: nacl);
//
//        return nvc;
    }
    
    func getNvControl() -> NvControl {
        return nvControl!;
    }
    
    func _setNvControl(nvControl : NvControl) {
        self.nvControl = nvControl;
    }
    
    func initNvControl() -> NvControl {
        let nvc = NvControl();
        return nvc;
        
       // var v : UIView ;
        
        
    }
    
    func getConfigCheckSum() -> String? {
        let sp = UserDefaults.standard;
        let spConfigMd5 = sp.object(forKey: NvCapConfigManager.NVSPConfigMd5);
        if(spConfigMd5 == nil){
            //NSLog("[NetVision] No config file found")
        }
        return (spConfigMd5 as! String?);
    }
}
