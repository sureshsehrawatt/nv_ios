//
//  NvAPIControl.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit

public class NvAPIControl: NSObject {
    public static var pageid = 1;
    func start (act : UIViewController , apiKey: String){
        NSLog("[NetVision NvAPIControl] start called");
        // make sure that RUM front end is disabled till the account authentication is done
        let nvcm = NvCapConfigManager.getInstance(); //getinstance
        //nvcm.getNvControl()._setRumEnabled(false);
        //nvcm.getNvControl()._setAccountAuthenticated(false);
        nvcm.getNvControl()._setApiKey(apiKey: apiKey);
        //long l=Long.parseLong("000000000000000000000");
        //BigInteger bb=BigInteger.valueOf(000000000000000000000);
        //let b : String = formatSID(0) ;
        //NvApplication._setSessId(b);
        
        // Initialize NvCapture Library - starts background service
        NvCapture._init(act: act); // look at this.
 
        // send first data of appStart time.
        var dict:Dictionary<String, String> = Dictionary<String, String>();
        let data = NvMetadata.getAppStart();
        dict["as"] = data;
        NvAPIApm.addNvEvent(evName: "AppStart", prop: dict)
        
        /** To be removed as account login will be done by background process
        NvRequest nvr = new NvRequest();
        AccountLogin acl = new AccountLogin();
        acl._setApiKey(apiKey);
        
        nvr._setReqCode(REQCODE.ACCOUNTLOGIN);
        nvr._setReqData(acl);
        
        NvCapture.getActivityMonitor().addRequest(nvr);
        ***/
    }
    
    func stop(){
        // stop rum front end
       let nvcm : NvCapConfigManager? = NvCapConfigManager.getInstance();
        nvcm!.getNvControl()._setRumEnabled(rumEnabled: false);
        nvcm!.getNvControl()._setRumPausedStopped(rumPausedStopped: true);
        nvcm!.getConfig()._setConfig_url(config_url: "");
        print("Rum Stopped")
        
        // stop Nvcapture library (stops background service etc )
        NvCapture.stopCapture();
        
        // force a restart of new session whenever rum started again
        
        NvApplication._init(app: NvApplication.getApp());
        
    }
    
    func pause(){
        // stop rum front end from sending info to server
        let nvcm = NvCapConfigManager.getInstance();
        nvcm.getNvControl()._setRumEnabled(rumEnabled: false);
        nvcm.getNvControl()._setRumPausedStopped(rumPausedStopped: true);
        print("Rum Paused")
    }
    
    func resume(){
        // start rum front end  sending info to server
        let nvcm = NvCapConfigManager.getInstance();
        nvcm.getNvControl()._setRumEnabled(rumEnabled: true);
        nvcm.getNvControl()._setRumPausedStopped(rumPausedStopped: false);
        print("Rum Resumed")
    }
    
    func isRumEnabled() -> Bool{
        let nvcm = NvCapConfigManager.getInstance();
        return nvcm.getNvControl().isRumEnabled();
    }
    
}
