//
//  NvPageDump.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit



public class NvPageDump : NSObject {
    private static var timer: Timer = Timer();
    private static var capureIt:Bool = false;
    private static var view : UIView = UIView();
    private static var name : String = "";
    private static var force: Bool = false;
    private static var lastLayOutTimestamp: Int64 = 0;
    override init(){}
    private static let PAGEDUMP_MIN_INTERVAL = 10000; // 10 secs minimum interval between two page dumps of same page
    //On viewDidAppear app may do some network request, and on completion of these request proper display is appeared (reference bug: 68123)
    @objc private static var incompleteHttpRequestCount = 0;
    static var rootView : UIView? = nil ;

    @objc public static func setLastLayoutTimestamp(time: Int64) {
        NvPageDump.lastLayOutTimestamp = time;
    }

    @objc(incrementHttpRequestCount)
    public static func incrementHttpRequestCount(){
        // if any HTTP request is sent to server then cancel the timer(i.e, now is not the time to capture PageDump)
        incompleteHttpRequestCount += 1;
        timer.invalidate();
    }

    
    @objc(decrementHttpRequestCount)
    public static func decrementHttpRequestCount(){
        incompleteHttpRequestCount -= 1;

        if(incompleteHttpRequestCount == 0 && capureIt){
            capureIt = false;
            timer.invalidate();
            if #available(iOS 10.0, *) {
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                    self.savePageDump(view: view, Name: name, force: force);
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

    @objc(savePageDumpWithView:Name:force:)
    public static func savePageDump( view : UIView , Name : String , force : Bool) {
        let name = Name;
        if !force && (incompleteHttpRequestCount != 0) {
            NSLog("[NetVision][NvPageDump] data buffered for pagedump capturing");
            capureIt = true;
            NvPageDump.view = view;
            NvPageDump.name = name;
            NvPageDump.force = force;
            return;
        }
        let lastPgDmpTS = NvApplication.getLastPageDumpTS()
        if force || (NvApplication.getpageInstance() != NvApplication.getLastPageDumpId()) || ((NvTimer.current_timestamp() - lastPgDmpTS) > NvPageDump.PAGEDUMP_MIN_INTERVAL) || ((NvPageDump.lastLayOutTimestamp - lastPgDmpTS) > 500) {

            uploadPageDump(rootView: view, Name: name);
            
            NvApplication.incrementSnapShotInstance();

            NvApplication._setLastPageDumpId(lastPageDumpId: NvApplication.getpageInstance());
            NvApplication._setLastPageDumpTS(long: NvTimer.current_timestamp());
            return;
        } else {
        }
        return;
    }
    
    private static func uploadPageDump(rootView: UIView , Name: String? ){
        var name = Name
        if UIScreen.main.bounds.height == 0 && UIScreen.main.bounds.width == 0 {
        }
        else{
            if  name == nil {
                name = rootView.description
            }
            if  name == nil {
                name = "NV"
            }
            let nvcm = NvCapConfigManager.getInstance();// problem 21
            
            if (nvcm.getConfig().getPagedump_mode() == NvCapConfig.PAGEDUMP_DISABLE) {
                return;
            }
            let nvr = NvRequest() ;
            nvr._setReqCode(reqCode: NvRequest.REQCODE.PAGEDUMP);
            let pdd = PageDumpData();
            nvr._setReqData(reqData: pdd);
            pdd._setScreenName(screenName: name!);
            let pInst = NvApplication.getpageInstance();
            pdd._setSessionId(sessionId: NvApplication.getSessId());            pdd._setPageId(pageId: NvApplication.getPageId());            pdd._setPageInstance(pageInstance: pInst);
            pdd._setSnapShotInstance(snapShotInstance: NvApplication.getSnapShotInstance());
            pdd._settimestamp( timestamp: NvTimer.current_timestamp());
            
            var bm : UIImage? ;
            bm = takeScreenshot(view: rootView);
            if bm == nil {
                return;
            }
            bm = blackOutBlackListView(RootView: rootView, Image: bm!);
            bm = bm?.resizeWith(percentage: 1.0)
            bm?.compress(quality: 0.3)
            pdd._setBmap(bmap: bm);
            pdd._setCaptureFlag(captureFlag: 1);   // to be used in service to check if compression needs to be done
            nvr._setReqData(reqData: pdd);
            NvCapture.getActivityMonitor().addRequest(nvr: nvr);
        }
        return;
    }
    
    
    //**MAKE CHANGES IN THIS FUNCTION AS ON 7/7/2016**
    
    
    private static func blackOutBlackListView(RootView : UIView , Image : UIImage ) -> UIImage {
        
        //get list of black list views.
        var image = Image
        let blackListViews = NvCapConfigManager.getInstance().getConfig().getBlIdList();
        let sensitiveList = NvCapture.getActivityMonitor()?.getBlackoutViewList();
        if blackListViews.count == 0 && (sensitiveList == nil || sensitiveList!.isEmpty()){
            return image;
        }
            
        else{
        }
        
        var view: UIView? ;
        var blEntry : NvBlackListId;
        let n = blackListViews.count
        
        var i : Int = 0
        // iterating over sensitive marked from config.
        while i < n {
            
            blEntry = blackListViews[i]
            i += 1

            if blEntry.getPageId() != -1 && (NvApplication.getPageId() != blEntry.getPageId()) {
                    continue;
            }
            view = RootView.viewWithTag(blEntry.id)
            if view == nil
            {
                continue;
            }

            var height, width, top, left: Int;

            let coord = view!.convert(view!.bounds.origin, to: nil)
            
            height = Int ((view?.bounds.size.height)!) ;
            width = Int ((view?.bounds.size.width)!) ;
            
            top = Int (coord.y);
            left = Int (coord.x);

            image = BlackListImage(image: image, x: left , y: top , h: height, w: width);
        }
        // iterating over sensitive marked from api
        
        
        if(sensitiveList != nil && !(sensitiveList?.isEmpty())!){
            var info = sensitiveList?.getNext(fromTop: true);
            var view: UIView? ;
            while(info != nil){
                view = RootView.viewWithTag(info!);
                if(view == nil){
                    info = sensitiveList?.getNext();
                    continue;
                }
                var height, width, top, left: Int;
                let coord = view!.convert(view!.bounds.origin, to: nil)
                height = Int ((view?.bounds.size.height)!) ;
                width = Int ((view?.bounds.size.width)!) ;
                
                top = Int (coord.y);
                left = Int (coord.x);
                image = BlackListImage(image: image, x: left , y: top , h: height, w: width);
                info = sensitiveList?.getNext();
            }
        }
        return image;
    }
    
}
