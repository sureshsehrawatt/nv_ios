//
//  NvCapture.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit



@objc public class NvCapture: NSObject {
    private static var nvCapture : NvCapture? = nil; // NvCapture
    
    @objc public static var isCapturing : Bool = false;
    
    private static var nvActivityMonitor : NvActivityLifeCycleMonitor? = nil;//NvActivityLifeCycleMonitor
    
    static func getInstance() -> NvCapture {
        
        if nvCapture == nil {
            nvCapture = NvCapture();// problem 18
        }
        return nvCapture! ;
    }
    
    @objc public static func getActivityMon() -> NvActivityLifeCycleMonitor {
        return NvCapture.nvActivityMonitor!;
    }
    
    static func _init( act: UIViewController ) ->  Bool {
        NSLog("[NetVision NvCapture] _init called");
        // problem 19
        getInstance();
        // note screen size
        //typecasting
        
        var osver : Float = 0.0;
        
        do{
            if (Float.init(UIDevice.current.systemVersion) == nil){
                osver = 10.0;
            }
            else{
                osver = Float.init(UIDevice.current.systemVersion)!
            }
        }
        
        if  osver < Float(9.0)  {
            NvApplication._setScreenWidth(  screenWidth: (UIScreen.main.applicationFrame.width) );
            NvApplication._setScreenHeight(  screenHeight: (UIScreen.main.applicationFrame.height) );
        //for others
        }
        else {
            NvApplication._setScreenWidth( screenWidth: (UIScreen.main.bounds.width) );
            NvApplication._setScreenHeight( screenHeight: (UIScreen.main.bounds.height) );
        }
        NvApplication.setConnType();
        nvActivityMonitor = NvActivityLifeCycleMonitor();
        nvActivityMonitor?.start();
        
        isCapturing = true;
        /*AG NOTES
        
        we are creating an NvActivityLifeCycleMonitor object and setting it to start recording the current proceedings on the app.
        Question : Do we need UIApplication to run it or it can run from anywhere.
        
        if we want we can place this object in UIApplication Class and operate this object via the UIApplication Object.
        
        */
        
        return true;
    }
    @objc public static func stopCapture(){
        // stop activity monitoring through life cycle call backs
        if  nvActivityMonitor != nil {
            
            nvActivityMonitor!.stop();
            
            nvActivityMonitor = nil;
        }
        // stop the background service interacting with the NV Server
        
    }
    
    static func getNvCapture() -> NvCapture {
        return getInstance();
    }
    
    static func getActivityMonitor() -> NvActivityLifeCycleMonitor! {
        if(nvActivityMonitor == nil){
            nvActivityMonitor = NvActivityLifeCycleMonitor()
        }
        return nvActivityMonitor!
    }
    
}
