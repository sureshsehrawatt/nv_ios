//
//  NvWebViewHandler.swift
//  NV_F4
//
//  Created by netstorm on 26/11/19.
//  Copyright © 2019 Cavisson. All rights reserved.
//

import Foundation
import WebKit


@objc public class NvWebViewHandler:UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private static var instance: NvWebViewHandler? = nil;
    public var activeWebViews: Array<WKWebView> = [WKWebView()];

    @objc public static func getInstance() -> NvWebViewHandler{
        if (instance == nil) {
            instance = NvWebViewHandler();
        }
        return instance!;
    }


    @objc public func clearData( ) {
        activeWebViews = Array();
    }

    @objc public func syncWebView(data:[String]) {
        var jsCode:String = " CAVNV.utils.androidSyncBridge({";
        for d in data{
            switch(d){
            case "sid":
                jsCode += "'sid':'\(NvApplication.getSessId())',"
                break;
            case "pi":
                let pInst = NvApplication.getpageInstance();
                jsCode += "'pageInstance':\(pInst),"
                break;
            case "snapshotInstance":
                jsCode += "'snapshotInstance':\(NvApplication.getSnapShotInstance()-1),"
                break;
            case "lts":
                jsCode += "'lts':\(NvApplication.getLastPageDumpTS()),"
                break;
            default:
                break;
            }
        }
        // remove extra comma.
        let upperBound = String.Index.init(encodedOffset: jsCode.count-1)
        jsCode = String(jsCode[..<upperBound]) + "});"
        // trigger update to all webViews
        for view in activeWebViews {
            view.evaluateJavaScript( jsCode, completionHandler: { result, error in
                if let userAgent = result as? String {
                    print(userAgent)
                    self.syncNative(data: self.convertToDictionary(from: userAgent)!)
                }
                if let err = error as? String {
                    print(err)
                }
            });
        }
    }

    func syncNative(data:[String: Any]) {
        NSLog("[NetVision][NvWebViewHandler] perform updation of data in webView")
        print(type(of: data));
        var returnData:[String] = Array();
        for k in data{
            switch(k.key) {
            case "sid":
                // check for latest value
                NvApplication._setSessId(sessIdentifier:(k.value as? String)!)
                print("[NetVision][NvWebViewHandler] got sid and value is : %s", k.value);
                break;
            case "pi":
                // check for latest value
                var pi = NvApplication.getpageInstance();
                if(pi < ((k.value as! NSString).intValue)){
                    NvApplication._setpageInstance( pageIns : (Int((k.value as! NSString).intValue)))
                }
                else {
                    returnData.append("pi");
                }
                break;
            case "snapshotInstance":
                // check for latest value
                var si = NvApplication.getSnapShotInstance()
                if(si < (k.value as! NSString).intValue){
                    NvApplication._setSnapShotInstance(snapShotInst: (Int((k.value as! NSString).intValue )))
                }
                else {
                    returnData.append("snapshotInstance");
                }
                break;
            case "lts":
                var service = NvActivityLifeCycleMonitor.getService();
                var lts = service.lts;
                if(lts < Int64((k.value as! NSString).intValue)){
                    service.lts = Int64((k.value as! NSString).intValue);
                }
                else {
                    returnData.append("lts");
                }
                break;
            default:
                print("inside default");
            }
        }
        if(returnData.count > 0){
            syncWebView(data: returnData);
        }
        var service = NvActivityLifeCycleMonitor.getService();
        if service != nil {
            service.enableSesssionInfoReq();
        }
    }

    // this listener has to be called on view which is currently visible.
    //FIXME: return is not handled properly.
    
    @objc(addWebViewListenerWithView:)
    public func  addWebViewListener(view : UIView) {
        var root = view;
        NSLog("[NetVision][NvWebViewHandler] adding listener to webView for type of view as \(NSStringFromClass(view.classForCoder))")
        
        for viw in view.subviews {
            addWebViewListener(view: viw);
        }
        if( NSStringFromClass(view.classForCoder).elementsEqual("UIView") ) {return};
        var webViewArr:[WKWebView] = [WKWebView]();
        let classForCoder = NSStringFromClass(view.classForCoder);
//        if(classForCoder.elementsEqual("UIWebView") || classForCoder.elementsEqual("WKWebView")){
        // Ticket No - 109787 - App was crashing - Error - Could not cast value of type 'UIWebView to 'WkWebView.'
        // Check for UiWebView is removed.
        if(classForCoder.elementsEqual("WKWebView")){
            NSLog("[NetVision][NvWebViewHandler] webView listener is set")
            let viw: WKWebView = (view as? WKWebView)!;
            viw.navigationDelegate = self;
            viw.configuration.userContentController.add(self, name: "appNativeSync");
            webViewArr.append(viw);
        }
        if(activeWebViews != nil){
            activeWebViews = activeWebViews + webViewArr;
        }
        else{
            activeWebViews = webViewArr;
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        NSLog("[NetVision][NvWebViewHandler] performing updation")
        if (message.name.elementsEqual("appNativeSync")) {
             print(message.body);
            let j = message.body as? String;
            switch(j){
            case "initialize":
                let data = ["sid","pi","snapshotInstance","lts"];
                syncWebView(data: data);
                break;
            case "canSendTiming":
                if(NvActivityLifeCycleMonitor.getService().canSendTiming()){
                    triggerWebViewTiming();
                }
                break;
            default:
                //FIXME: add opCode for that
                syncNative(data: convertToDictionary(from: j!)!);
            }
        }
    }

    func triggerWebViewTiming() {
        for view in activeWebViews {
            view.evaluateJavaScript( "if(!!CAVNV) CAVNV.utils.trigerSendBeacon(true)", completionHandler: { result, error in
                if let err = error as? String {
                    print(err)
                }
            });
        }
    }
    
    
    func convertToDictionary(from text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return nil }
        let anyResult = try? JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
}
