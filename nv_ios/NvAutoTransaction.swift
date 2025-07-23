//
//  NvAtuoTransaction.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
import UIKit

public class FilterEntries: NSObject {
    var pageIndex: [Int];
    var text: String?;
    var tag: Int?;
    
    public override init(){
//        print("at.. FilterEntries")
        pageIndex = [Int]();
    }
    
    func getPageIndex() -> [Int]{
        return self.pageIndex;
    }
    
    func getText() -> String?{
        return self.text;
    }
    
    func getTag() -> Int?{
        return self.tag;
    }
}

public class NvTxnFilter: NSObject {
    var mode : String;
    var filterEntries : [FilterEntries];

    override public init() {
//        print("at.. NvTxnFilter")
        mode = "";
        filterEntries = [FilterEntries]();
    }

    func setMode(mod:String){
        self.mode = mod;
    }

    func getMode() -> String{
        return self.mode;
    }
    
    func getFilterEntries() -> [FilterEntries] {
        return filterEntries;
    }
}

public class NvAutoTransactionConfig: NSObject {
    var enable: Bool;
    var autoTxnFilter: NvTxnFilter;

    @objc public func isEnable() -> Bool {
        return self.enable;
    }

    func getAutoTxnFilter() -> NvTxnFilter  {
        return autoTxnFilter;
    }

    func setAutoTxnFilter(autoTxnFilter: NvTxnFilter) {
        self.autoTxnFilter = autoTxnFilter;
    }

    override init() {
//        print("at.. init()")
        enable = false;
        autoTxnFilter = NvTxnFilter();
    }
}

@objc public class NvAutoTransaction: NSObject {

    static var httpReqCount: Int = 0;
    var actionList : [String: NvAction];
    var nvatc: NvAutoTransactionConfig;
    static var txnStart: Bool = false;
    var key: String;
    static var instance: NvAutoTransaction?;
    static var timer: Timer? = nil;
    
    @objc (initWithVc:)
    public init(vc: String) {
//        print("at.. init(vc: String)")
  //      super.init();
        nvatc = NvCapConfigManager.getInstance().getConfig().getAutoTxn();
        actionList = [String: NvAction]();
        key = vc;
    }

    @objc public static func setInstance(inst: NvAutoTransaction) {
        NvAutoTransaction.instance = inst;
    }
    
    public func getAutoTxnConfig() -> NvAutoTransactionConfig{
        return nvatc;
    }
    
    @objc(incrementHttpRequestCount)
    public static func incrementHttpRequestCount(){
        httpReqCount += 1;
    }
    
    
    @objc public func checkSetAutoTxn(a: String, b: String, v:UIView) {
        if(self.getAutoTxnConfig().isEnable()){
            let filter = self.getAutoTxnConfig().getAutoTxnFilter();
            let filterEntries = filter.getFilterEntries();
            if filter.getMode().elementsEqual("blacklist") {
                for entry in filterEntries{
                    for pgId in entry.getPageIndex() {
                        if( pgId == -1 || pgId == NvApplication.getPageId() ) {
                            // apply rules
                            // if none of rule matches then trigger startOfTransaction.
                            if(entry.tag != nil && entry.getTag()! == v.tag || entry.getText() != nil && a.elementsEqual(entry.getText()!)){
                                return;
                            }
                        }
                    }
                }
                if #available(iOS 10.0, *) {
                    self.startAutoTxn(name: b+"_"+a)
                } else {
                    // Fallback on earlier versions
                };
            }
            else if filter.getMode().elementsEqual("whitelist") {
            outerLoop: for entry in filterEntries{
                for pgId in entry.getPageIndex() {
                    if( pgId == -1 || pgId == NvApplication.getPageId() ) {
                        // apply rules
                        //if rule matches then trigger startOfTransaction.
                        if(entry.tag != nil && entry.getTag()! == v.tag || entry.getText() != nil && a.elementsEqual(entry.getText()!)) {
                            if #available(iOS 10.0, *) {
                                self.startAutoTxn(name: b+"_"+a)
                            } else {
                                // Fallback on earlier versions
                            };
                            break outerLoop;
                        }
                    }
                }
            }
            } else {
                //if mode does not exist then start transaction
                if #available(iOS 10.0, *) {
                    self.startAutoTxn(name: b+"_"+a)
                } else {
                    // Fallback on earlier versions
                };
            }
        }
    }

    @objc(decrementHttpRequestCount)
    public static func decrementHttpRequestCount(){
//        print("at.. decrementHttpRequestCount")
        httpReqCount -= 1;
        if(httpReqCount == 0 && txnStart/* && flag to check if we need to trigger timer*/){
            //set a timer of 300 ms
            if #available(iOS 10.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                    if NvAutoTransaction.httpReqCount == 0 {
                        //trigger end autoTransaction for all the nvAutoTransaction instances
                        NvAutoTransaction.instance!.endAutoTxn();
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    @objc(resetAutoTxn)
    public func resetAutoTxn() {
        if (NvAutoTransaction.timer != nil)
        {
            NvAutoTransaction.timer!.invalidate();
        }
        NvAutoTransaction.timer = nil;
        actionList = [String: NvAction]();
        NvAutoTransaction.txnStart = false;
    }

    @objc(resetTimer)
    public func resetTimer(){
        if(NvAutoTransaction.timer != nil) {
            NvAutoTransaction.timer!.invalidate();
            if #available(iOS 10.0, *) {
                NvAutoTransaction.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                    if NvAutoTransaction.httpReqCount == 0 {
                        //trigger end autoTransaction for all the nvAutoTransaction instances
                        self.endAutoTxn();
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

//    @objc(checkStartWithName:)
//    public func checkStart(name: String) -> Bool {
//        //if name exist in list initiate auto Transaction.
//        nvatc = NvCapConfigManager.getInstance().getConfig().getAutoTxn();
//        if(nvatc.isEnable()){
//            // check if name exist in list then start transaction.
//            for dat in nvatc.getAutoTxnList(){
//                if(dat.getControllerName().elementsEqual(name)){
//                    key = name;
//     //               self.tagList = dat.getTagList();
//                    return true;
//                }
//            }
//        }
//        return false;
//    }
    
    @available(iOS 10.0, *)
    public func startAutoTxn(name: String) {
        var nvAct: NvAction = NvAction.startTransaction(actionName: key+"_"+name, actionData:"");
        // set nvAction instance in actionList.
        actionList[key+"_"+name] = nvAct;
        NvAutoTransaction.txnStart = true;
        if NvAutoTransaction.timer == nil && NvAutoTransaction.httpReqCount == 0{
            NvAutoTransaction.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                // once timer ends check for httprequestCount and if request count is 0, then triger endTransaction.
                if NvAutoTransaction.httpReqCount == 0 {
                    self.endAutoTxn();
                }
            }
        }
    }

    func endAutoTxn() {
        //FIXME:
        for nvAct in actionList{
            (nvAct.value as? NvAction)?.endTransaction();
            actionList.removeValue(forKey: nvAct.key as! String);
        }
        NvAutoTransaction.txnStart = false;
        NvAutoTransaction.timer = nil
    }
}
