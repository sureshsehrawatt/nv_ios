//
//  NvAPIApm.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.,
//

import UIKit


let nvapiRum =   NvAPIRum();


public class NvAPIApm: NSObject {
    func startAction(actionName : String, actionData : String ) -> NvAction {
        return NvAction.startAction(actionName: actionName, actionType: NvAction.ActionType.MARK,actionData: actionData);
    }
    
    @objc public static func addNvEvent( evName : String , prop : [String : String]?, force : Bool = false
    ){
        NSLog("[NetVision NvAPIApm] addNvEvent called");
        if (NvCapConfigManager.getInstance().getNvControl().isRumEnabled()){
            print("data will be added to request queue");
            nvapiRum.addNvEvent(evName: evName, prop: prop, force: force);
        }
    }
}
