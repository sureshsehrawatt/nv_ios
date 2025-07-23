//
//  NvAPIRum.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit


public class NvAPIRum: NSObject {
    
    
    func addNvEvent(evName: String, prop: [String: String]?, force: Bool = false ){
        
        let nvr = NvRequest();
        let er = EventRequest();
        nvr._setReqCode(reqCode: NvRequest.REQCODE.APIEVENT);
        nvr._setReqData(reqData: er);
        er._setSessionId(sessionId: NvApplication.getSessId())
        er._setEvName(String: evName);
        er._setProp(prop: prop);
//        if(!NvApplication.getSessId().elementsEqual("000000000000000000000")) {
//            if(evName == "PageStart" /*||*/) {
//                NvCapture.getActivityMonitor().addEventRequest(nvr: nvr, force: true);
//            } else {
//                NvCapture.getActivityMonitor().addEventRequest(nvr: nvr);
//            }
//        }
        if(NvApplication.getSessId().elementsEqual("000000000000000000000")) {
            NvCapture.getActivityMonitor()?.addRequest(nvr: nvr);
        }
        else {
            NvCapture.getActivityMonitor().addEventRequest(nvr: nvr, force: force);
        }
    }
    
    func addUserAction( act: UIViewController ,view : UIView ,actionName: String , actionData : String ){
//        print("at.. addUserAction")
        let ua = NvUserAction();
        ua.logUserAction(act: act, v: view ,  actionName: actionName,  actionData: actionData);
    }
    
    public func markSensitive( viewId: Int){
        var nalcm : NvActivityLifeCycleMonitor ;
        nalcm = NvCapture.getActivityMonitor();
        nalcm.addToBlackoutList(viewId: viewId);
    }
    
    public func unmarkSensitive(viewId : Int){
        var nalcm : NvActivityLifeCycleMonitor ;
        nalcm = NvCapture.getActivityMonitor();
        nalcm.removeFromBlackoutList(viewId: viewId);
    }
    
    
}
