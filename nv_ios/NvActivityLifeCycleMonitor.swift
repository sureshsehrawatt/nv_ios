import UIKit
import CoreLocation
import MobileCoreServices
import Foundation
import MapKit



@objc public class NvActivityLifeCycleMonitor: NSObject //Application.ActivityLifecycleCallbacks
{
    var loadtime : Int64 = 0;
    static var enableresponsereporting = true;
    var starttime : Int64;
    private static let OP_ADD = 0;
    private static let OP_REMOVE = 1;
    typealias ViewGroup = [UIView] ;
    private static let  TAG = "ActivityLifeCycleMonitor";
    private static let  ACTLCACTIONNAME = "_Act_";
    private static var mService : NvBackGroundService? = nil;
    private var mBound = false;
    var autoTxn : NvAutoTransaction? = nil;
    
    var act : UIViewController? = nil;
    private var pendingReq : nvLinkedList<NvRequest>? = nil;
    private var blackoutViewList : nvLinkedList<Int>? = nil;
    private var snapshotid : Int = -1 ;
    
    @objc public override init(){
        starttime = NvTimer.current_timestamp();
    }
    @objc
    public init( vc : UIViewController ){
        self.starttime = NvTimer.current_timestamp();
        super.init()
        
        self.act = vc
    }
    
    func start(){
        NSLog("[NetVision NvActivityLifeCycleMonitor] start called");
        NvActivityLifeCycleMonitor.mService = NvBackGroundService.startService();
        if(NvActivityLifeCycleMonitor.mService == nil){
            //NSLog("[NetVision] Wrong service")
        }
        return
    }
    
    func stop(){
        NSLog("[NetVision NvActivityLifeCycleMonitor] start called");
        if(NvActivityLifeCycleMonitor.mService != nil){
            NvActivityLifeCycleMonitor.mService!.flushAllRequests()
        }
        
        NvBackGroundService.stopService();
        NvActivityLifeCycleMonitor.mService = nil ;
        return
    }
    
    public static func updateCrashFile() {
        if(NvApplication.getSessId() == formatSID(sid: 0)){
            return;
        }
        let chnlId = NvCapConfig.getChannelId()
        let URL = String(NvCapConfigManager.getInstance().getConfig().getBeacon_url()) + "?s=" + NvApplication.getSessId() + "&p=200&m=100"  + "&op=creport" + "&pi=" + String(NvApplication.getpageInstance()) + "&d= \(chnlId)|" + "iOS" + "|" +  String(NvCapConfig.MobileOsVersion) + "|" +
            NvMetadata.APPID + "|" +
            NvMetadata.VERSIONID + "|" +
            NvMetadata.MANUFACTUREID + "|" +
            NvMetadata.MODELID + "|" +
            NvMetadata.CARRIER + "|" +
            NvMetadata.CONNECTION_TYPE + "|" +
            NvMetadata.GEOID + "|" +
            NvMetadata.GEO_LOCID + "|" +
            NvMetadata.APP + "|" +
            NvMetadata.VERSION + "|" +
            NvMetadata.MANUFACTURE + "|" +
            NvMetadata.MODEL + "&lts=" +
            String(NvActivityLifeCycleMonitor.getService().lts) ;
        let preferences = UserDefaults.standard
        let Crashkey = "NvCrashKey"
        preferences.setValue(URL, forKey: Crashkey)

        let file = "NvCrashReport.nvcrash"
    }
    
    
    @objc public func updateHttpMonStat (req_cnt: UInt32, resp_cnt: UInt32, err_cnt : UInt32, avg : Double , hi : UInt32, lo : UInt32, er4x : UInt32, er5x : UInt32, erTO : UInt32, erCF : UInt32, erMisc : UInt32) {
        
        //#TODO : handle all of them to construct a request.
        HttpMonitorStat.average_response_Time = avg;
        HttpMonitorStat.request_count = req_cnt
        HttpMonitorStat.response_count = resp_cnt
        HttpMonitorStat.response_max = hi;
        HttpMonitorStat.response_min = lo;
        HttpMonitorStat.error_count = err_cnt
        HttpMonitorStat.err_4xx = er4x
        HttpMonitorStat.err_5xx = er5x
        HttpMonitorStat.err_misc = erMisc
        HttpMonitorStat.err_conFail = erCF
        HttpMonitorStat.err_timeout  = erTO
        
        return
    }
    
    public func sendHttpMonStat() {
        let nvr : NvRequest = NvRequest();
        nvr._setReqCode(reqCode: .MONSTAT)
        addRequest(nvr: nvr)
    }
    
    public func ishostBlackListed(host : String ) -> Bool {
        let nvcm = NvCapConfigManager.getInstance();
        let config = nvcm.getConfig();
        if(config.isBlackList){
            
            let hosts = config.domain;
            
            for domain in hosts {
                if host == domain {
                    return true;
                }
            }
            return false;
        }
        else{
            return !(ishostWhiteListed(host: host, config: config))
        }
        
        
    }
    public func ishostWhiteListed(host : String, config : NvCapConfig) -> Bool {
        let hosts = config.domain;
        
        for domain in hosts {
            if host == domain {
                return true;
            }
        }
        return false;
    }

    @objc public func formHttpLog(request : NSURLRequest, response : HTTPURLResponse, data : NSData?, responsetime: Double){
        let httpLog : HttpLogRequest = HttpLogRequest();
        let nvhttpLogRequest : NvRequest = NvRequest();
        var url : NSURL;
        if(response.url != nil){
            url = response.url! as NSURL;
        }
        else {
            url = request.url! as NSURL;
        }
        if(url.path == nil){
        //NSLog("[NetVision][formHttpLog] %@ path nil",url);
        }
        if( request.url?.host == nil ){
            //NSLog("[NetVision][formHttpLog] %@ URL with nil host: ",url);
            return;
        }
        if ishostBlackListed (host: (request.url?.host)!) {
            //NSLog("[NetVision][formHttpLog] Host is blacklisted for %@ ", url)
            return;
        }
        if url.absoluteString != nil {
            httpLog.encodedurl = (url.absoluteString)!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        httpLog.responsetime = Int64.init(responsetime * 1000);
        httpLog.statuscode = response.statusCode;
        httpLog.method = request.httpMethod!;
        if(data != nil){
            httpLog.bytetransferred = (data?.length)!;
        }
        else {
            httpLog.bytetransferred = 0;
        }
    
        var jsonData : NSData? = nil;
        var arr = [String]()

        for (key, value) in response.allHeaderFields {
            arr.append("\(key):\(value)")
        }
        do {
        //header, timing, content-Type ,post data
            jsonData = try JSONSerialization.data(withJSONObject: response.allHeaderFields, options: JSONSerialization.WritingOptions(rawValue: 0) ) as NSData;
        }
        catch {
        //NSLog("[NetVision][formHttpLog] Http headers not parsed as jsonstring")
        }

        let headers = NSString.init(data: jsonData! as Data, encoding: String.Encoding.utf8.rawValue)
        //let headers = NSString.init(data: jsonData, encoding: String.Encoding.utf8.rawValue)
        var respText : NSString = NSString();
        if(data != nil && NvActivityLifeCycleMonitor.enableresponsereporting){
            respText = NSString.init(data: data! as Data, encoding: String.Encoding.utf8.rawValue)!
        }
        else {
            respText = "";
        }
        if(respText != nil){
        //NSLog("[NetVision] [formHttpLog] respText : %@",respText);
        }
        var jsonDic = [NSObject : AnyObject]();
        var key : NSString = "queryString";
        do{
            try jsonDic[key] = url.absoluteString as! NSString ;
        }
        catch {
        //NSLog("[NetVision][formHttpLog] URL is not convertible to String");
        }
        key = "postdata";
        jsonDic[key] = "" as AnyObject;
        key = "responseText";
        jsonDic[key] = respText;
        key = "timing";
        jsonDic[key] = "" as AnyObject;
        key = "headers";
        jsonDic[key] = arr as AnyObject;
        key = "url"
        
        jsonDic[key] = request.url?.absoluteString as AnyObject
        
        let headerdict = getDictionaryfromString(jsonText: headers as! String);
        var content_length : Int?;
        var XcavNV :String?;
        var correlationID : String?;
        if(headerdict != nil){
            let cont_lenString = headerdict!["Content-Length"]
            if( (cont_lenString as? String) == nil){
                content_length = 0;
            }
            else{
                content_length = Int(cont_lenString as! String)
            }
            XcavNV = headerdict!["X-CavNV"] as? String
            correlationID = headerdict!["X-CorrelationId"] as? String
        
        if(correlationID != nil){
            httpLog.CorrelationID = correlationID!
        }
        if(XcavNV != nil){
            httpLog.XCavNV = XcavNV!
        }
        }
        else{
            content_length = 0;
        }
        httpLog.bytetransferred = content_length!
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: jsonDic, options: JSONSerialization.WritingOptions(rawValue: 0) ) as NSData;
        }
        catch {
        //NSLog("[NetVision][formHttpLog] Http headers not parsed as jsonstring")
        }
        let jsonString = NSString.init(data: jsonData! as Data, encoding: String.Encoding.utf8.rawValue);
        
        
        
        httpLog.jsonString = (jsonString as! String).addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
        nvhttpLogRequest._setReqData(reqData: httpLog);
        nvhttpLogRequest._setReqCode(reqCode: .HTTPLOG);
        addRequest(nvr: nvhttpLogRequest);
        // increment httpReqCount
    }
    
    public func getDictionaryfromString(jsonText : String) -> NSDictionary? {
        var dictonary:NSDictionary?
        
        if let data = jsonText.data(using: String.Encoding.utf8) {
            
            do {
                dictonary =  try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as! NSDictionary
            }
            catch let error as NSError {
                print(error)
            }
        }
        return dictonary;
    }

    @objc(getSnapShotInstance)
    func getSnapShotInstance() -> Int{
        return NvApplication.getSnapShotInstance();
    }
    
    @objc(onActivityCreatedWithActivity:)
    public func onActivityCreated( activity : UIViewController) {
        // FIXME: Why we calling NvCap.start here ?
        logActivityAction(act: activity, stage: .START, event: .CREATE, start_time: NvTimer.current_timestamp());
    }
    @objc(onActivityDestroyedWithActivity:)
    public func onActivityDestroyed(activity : UIViewController) {
        logActivityAction(act: activity, stage: .END, event: .DESTROY, start_time: NvTimer.current_timestamp());
    }
    @objc(onActivityPausedWithActivity:)
    public func onActivityPaused(activity : UIViewController) {
        logActivityAction(act: activity, stage: .INTERMEDIATE, event: .PAUSE, start_time: NvTimer.current_timestamp());
        self.sendAllHttpLogs()
        NvActivityLifeCycleMonitor.mService?.flushUserActionRecord(forceFlag: true)
        self.sendHttpMonStat()
        NvActivityLifeCycleMonitor.mService?.flushAllQueues();
    }
    
    public func setupDOMWatcher(act : UIViewController) {
        let view = act.view;
        let config = NvCapConfigManager.getInstance().getConfig();
        let domwList = config.getDomW().getDomWList();
        
        for domw in domwList {
            let pages = domw.getPageIdList();
            for page in pages {
                if page == NvApplication.getPageId() {
                    setupDOMWatcherin(view: view!);
                }
            }
        }
        
    }
    
    public func setupCustomMetric (act : UIViewController ) {
        let cmList = NvCapConfigManager.getInstance().getConfig().getCmList();
        let view = act.view;
        for cm in cmList {
            if cm.getPageId() == NvApplication.getPageId() {
                let v = view?.viewWithTag(Int(cm.getViewId()));
                if(v != nil){
                    if ( v is UITextField ) {
                        let textField = v as! UITextField ;
                        textField.addTarget(self, action: Selector("CustomMetricDetectedin:"), for: UIControl.Event.editingDidEnd)
                    }
                }
            }
        }
    }
    
    public func CustomMetricDetectedin ( sender : UITextField ) {
        let cmList = NvCapConfigManager.getInstance().getConfig().getCmList();
        for cm in cmList {
            if cm.getPageId() == NvApplication.getPageId() {
                let matchPattern = cm.getValueMatchPattern()
                //TODO : Match Pattern Here
                
                if sender.text != nil {
                    if CustomMetric.matchPattern(text: sender.text!, regex: matchPattern) {
                        NvUserAction.logCustomMetric(cm: cm , value: sender.text!);
                    }
                }
                
            }
        }
    }
    
    public func setupDOMWatcherin(view : UIView) {
        let subviews = view.subviews;
        if(subviews.count > 0){
            for subview in subviews {
                setupDOMWatcherin(view: subview);
            }
        }
        if view is UITextField {
            let textfield = view as! UITextField
            textfield.addTarget(self, action: Selector("textFieldEdited:"), for: UIControl.Event.editingDidEnd)
            
        }
        else if view is UITextView {
            let textview = view as! UITextView
            //TODO : See ho wo detect changes in UITextView
            
        }

    }
    
    public func setupTextFieldWatcher (view : UIView) {
        let subviews = view.subviews;
        if(subviews.count > 0){
            for subview in subviews {
                setupTextFieldWatcher(view: subview);
            }
        }
        if view is UITextField {
            let textfield = view as! UITextField
            textfield.addTarget(self, action: Selector("textFieldTapped:"),for: UIControl.Event.touchUpInside)
            
        }
        else if view is UITextView {
            let textview = view as! UITextView
            
            
        }
    }
    
    
    public func textFieldEdited( sender : UITextField){
        let root = NvUtils.getRootView( view: sender)
        NvPageDump.savePageDump(view: root, Name: "text Field Updated", force: true);
        NSLog("[NetVision][NvActivityLifeCycleMonitor] capturing page dump because of click");
    }
    
    public func textFieldTapped (sender : UITextField, act : UIViewController) {
        
        let event = sender.convert(sender.center, to: nil);
        TouchGesture(event: event);
    }
    
    public func SetupTextFieldWatcher(activity : UIViewController){
        
    }
    @objc(onViewDidAppearWithAct:)
    public func onViewDidAppear(act : UIViewController) {
        logActivityAction(act: act, stage: .INTERMEDIATE, event: .VIEWDIDAPPEAR, start_time: NvTimer.current_timestamp());
        //NSLog("value of memory consumed is : %f",memoryFootprint()!);
    }

    @objc(onViewDidLoadWithAct:)
    public func onViewDidLoad(act : UIViewController) {
        logActivityAction(act: act, stage: .INTERMEDIATE, event: .VIEWDIDLOAD, start_time: NvTimer.current_timestamp());
    }

    @objc(onViewWillDisappearWithAct:)
    public func onViewWillDisappear(act : UIViewController) {
        logActivityAction(act: act, stage: .INTERMEDIATE, event: .VIEWWILLDISAPPEAR, start_time: NvTimer.current_timestamp());
    }
    
    @objc(onViewDidLayoutSubviewsWithAct:)
    public func onViewDidLayoutSubviews(act : UIViewController) {
        logActivityAction(act: act, stage: .INTERMEDIATE, event: .VIEWDIDLAYOUTSUBVIEWS, start_time: NvTimer.current_timestamp());
    }
    
    @objc(onActivityResumedWithActivity:)
    public func onActivityResumed(activity : UIViewController) {
        NvActivityLifeCycleMonitor.updateCrashFile()
        logActivityAction(act: activity, stage: .INTERMEDIATE, event: .RESUME, start_time: NvTimer.current_timestamp());
       }
    @objc(onActivitySaveInstanceStateWithActivity:)
    public func onActivitySaveInstanceState(activity : UIViewController) {
        if( NvTimer.current_timestamp() - starttime > 1000){
            //sendLoadTime;
        }
        else{
            loadtime = NvTimer.current_timestamp() - starttime;
        }
    }
    @objc(onActivityStartedWithActivity:)
    public func onActivityStarted(activity : UIViewController) {
        logActivityAction(act: activity, stage: .INTERMEDIATE, event: .START , start_time: NvTimer.current_timestamp());
        setupDOMWatcher(act: activity);
        setupCustomMetric(act: activity);
        SetupTextFieldWatcher(activity: activity);

    }
    
    func memoryFootprint() -> Float? {
        // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        // complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard
            kr == KERN_SUCCESS,
            count >= TASK_VM_INFO_REV1_COUNT
            else { return nil }

        let usedBytes = Float(info.phys_footprint)
        return usedBytes
    }
    
    func sendAllHttpLogs(){
 //       NvActivityLifeCycleMonitor.mService?.flushHTTPLogRecord(force: true);
    }
    
    private func _setDomWatcher(activity : UIViewController)
    {
        //get configuration.
        //We are sure that we always get config.
        let config = NvCapConfigManager.getInstance().getConfig();
        //get list of domwatcher list.
        let dw : DOMWatcher = config.getDomW()
        if(dw.getEnable() == false)
        {
            return;
        }
        let dwList = dw.getDomWList();
        
        //TODO: should we should skip if pageid is -1?
        let curPageId = NvApplication.getPageId();
        var validPage = false;
        var view : UIView? ;
        let len = dwList.count

        for i  : Int in 0..<len{

            validPage = false;

            view = nil ;
            //Check if current current entry is applied on current page.
            let entry = dwList[i]
            
            let pageList = entry.getPageIdList();
            let plen = pageList.count
            
            
            for j : Int in 0..<plen{
                
                let pageid = pageList[j]
                
                if(pageid == -1 ||  curPageId == pageid ){
                    validPage = true;
                    break;
                }
            }
            if (!validPage) {continue;}

            //get view by id if type is id.
            if(entry.getsType() == DOMWatcherEntry.DOMWSType.ID){

                view = activity.view;
            }

            if (view == nil) {
                continue;
            }

            if (snapshotid == -1) {
                snapshotid = 1;
                // Updating snapshotid
                NvApplication._setSnapShotInstance(snapShotInst: snapshotid);
            }
            else{
                NvApplication.incrementSnapShotInstance();
            }
        }
    }

    private func logActivityAction( act : UIViewController , stage : NvAction.STAGE , event : ActivityTiming.ACTIVITYLIFEEVENT , start_time : Int64){
        
        if (NvCapConfigManager.getInstance().getNvControl().isRumEnabled()){

            let actTime: ActivityTiming = ActivityTiming();

            actTime._setActName(actName: "actName_iOS")
            actTime._setLifeEvent(lifeEvent: event);
            actTime._setPageInstance(pageInstance: NvApplication.getpageInstance());
            actTime._setTs(ts: NvTimer.current_timestamp());

            var hardactionData : String ;
            var levent = "";
            
            if(event == .CREATE){
                levent = "CREATE"
            }
            else if ( event == .START){
                levent = "START"
            }
            else if ( event == .RESUME){
                levent = "RESUME"
            }
            else if ( event == .PAUSE){
                levent = "PAUSE"
            }
            else if ( event == .STOP){
                levent = "STOP"
            }
            else if ( event == .DESTROY){
                levent = "DESTROY"
            }
            else if ( event == .VIEWDIDLOAD){
                levent = "VIEWDIDLOAD"
            }
            else if ( event == .VIEWDIDAPPEAR){
                levent = "VIEWDIDAPPEAR"
            }
            else if ( event == .VIEWWILLDISAPPEAR){
                levent = "VIEWWILLDISAPPEAR"
            }
            else if ( event == .VIEWDIDLAYOUTSUBVIEWS){
                levent = "VIEWDIDLAYOUTSUBVIEWS"
            }
            let actName = (act.nibName != nil) ? act.nibName : "UIViewController";
            levent = "\"\(levent)\""+"|"+actName! ;
            
            hardactionData = "{\"actName\":\"";
              hardactionData = hardactionData + actTime.getActName() + "\"" + ",\"lifeEvent\":";
               hardactionData = hardactionData + levent + ",\"ts\":" + String(actTime.getTs());
            
            hardactionData = hardactionData + ",\"pageInstance\":" + String(actTime.getPageInstance()) + "}";
            var name = "";
            if( stage.hashValue == 0){
                name = "START";
            }
            else if ( stage.hashValue == 1){
                name = "END";
            }
            else {
                name = "INTERMEDIATE";
            }
            
            hardactionData = "{\"name\":\"" + name + "\",\"startTime\":" + String(actTime.getTs()) + ",\"data\":" + hardactionData ;
            
            
            hardactionData = hardactionData + "}"
            
            let nva =  NvAction( name: NvActivityLifeCycleMonitor.ACTLCACTIONNAME);
            nva._setType(type: .USERTIMING)
            nva._setStage(stage: stage);
            nva._setActionData(data: hardactionData);
            nva._setViewName(viewName: actName!);
            nva.acttiming = actTime;
            let nvr = NvRequest();
            nvr._setReqCode(reqCode: NvRequest.REQCODE.APIACTION);
            nvr._setReqData(reqData: nva);
            addTimingRequest(nvr: nvr);

        }

        return;

    }
    
    private func removeFocusChangeListener(act : UIViewController){

    }
    
    private func _setFocusChangeListener( act : UIViewController){
        
        if (!NvCapConfigManager.getInstance().getNvControl().isRumEnabled()) {return;}
        
        var rootView =  act.view!;
        
        while( rootView.superview != nil){
            rootView = rootView.superview! ;
        }
    }
    
    // FIXME: where this has called. This is the reason first sessionInfo request discarded.
    private func performPendingTasks(){
        // if there are any pending requests forward them to the background service for processing
        if(pendingReq == nil){
            return;
        }
        
        
        while (pendingReq!.size() != 0){
            let nvr = pendingReq?.ElementAtTop();
            pendingReq?.pop();
            if(NvActivityLifeCycleMonitor.mService != nil){
                NvActivityLifeCycleMonitor.mService!.addnvRequest(nvr: nvr!);
            }
            
        }
        
        
        
        // upload pagedump of the activity at the start of activity
	       
        
        _ = NvUtils.getRootView(view: self.act!.view);
    }
    
    @objc(setActivityWithAct:)
    public func setActivity( act : String){
        let actlist = NvCapConfigManager.getInstance().getConfig().getActList();
        let n = actlist.count;
        var i = 0;
        while( i < n){
            let ac = actlist[i];
            i += 1;
            print("act : "+act);
            print("ac.getActivityName() : "+ac.getActivityName());
            if act.elementsEqual(ac.getActivityName()) {
                NvApplication._setPageId(int: ac.getPageId());
                print("act: pageId set")
                // activity name matched
                if (ac.isWebviewActivity()){
                    // activity is primarily UIWebView based and hence pageid is guided by URL in UIWebView and not by activity name
                    // TBD
                }
            }
        }
    }
    
    @objc(_setNvPageContextWithAct:)
    public func _setNvPageContext( act : UIViewController){
        if (NvCapConfigManager.getInstance().getNvControl().isRumEnabled()){
            NvApplication._setpageInstance(pageIns: NvApplication.pageInstance + 1);
        }
        NSLog("[NetVision][NvUIViewController] page instance changed new value is \(NvApplication.getpageInstance())");
        NvApplication._setSnapShotInstance(snapShotInst: 0);
        // send all nvrq active queue to pending queue.
        if NvActivityLifeCycleMonitor.mService == nil {
            print("mservice is nil")
        }else{
            NvActivityLifeCycleMonitor.getService().updateActiveReqQueue();
        }
    }

    @objc(onActivityStoppedWithActivity:)
    public func onActivityStopped(activity : UIViewController) {
        logActivityAction(act: activity, stage: .INTERMEDIATE, event: .STOP, start_time: NvTimer.current_timestamp());
    }

    static func getService() -> NvBackGroundService {
        return mService!
    }
    
    @objc public func SwipeGesture(event : CGPoint) {
//        print("at.. @objc public func SwipeGesture(event : CGPoint) {")
        processUserAction( uet: .SWIPE , ev: event)
    }

    @objc(setActWithAct:)
    public func setAct(act: UIViewController){
        self.act = act;
    }
    
    @objc(TouchGestureWithEvent:)
    public func TouchGesture(event : CGPoint) {
//        print("at.. public func TouchGesture(event : CGPoint) {")
        processUserAction( uet: .TOUCHEND , ev: event)
    }

    @objc public func LongPressGesture(event : CGPoint) {
//        print("at.. @objc public func LongPressGesture(event : CGPoint) {")
        processUserAction( uet: .LONGPRESS , ev: event)
    }

    @objc public func RotationGesture(event : CGPoint) {
//        print("at.. @objc public func RotationGesture(event : CGPoint) {")
        processUserAction( uet: .ROTATE , ev: event)
    }

    @objc public func PinchGesture(event : CGPoint) {
//        print("at.. @objc public func PinchGesture(event : CGPoint) {")
        processUserAction( uet: .PINCH , ev: event)
    }

    @objc public func PanGesture(event : CGPoint) {
//        print("at.. @objc public func PanGesture(event : CGPoint) {")
        processUserAction( uet: .PAN , ev: event)
    }

    @objc public func setAutoTxn(autoTxn : NvAutoTransaction){
//        print("at.. @objc public func setAutoTxn(autoTxn : NvAutoTransaction){")
        self.autoTxn = autoTxn;
    }

    func processUserAction(uet : UAEVENTTYPE.UAEVENTTYPE , ev : CGPoint ) {
        // take pagedump of the screen when user has touched the screen
        if (!NvCapConfigManager.getInstance().getNvControl().isRumEnabled()) {
            return;
        }
        // traverse view hierarchy to log the touch event on appropriate view
        let nvua = NvUserAction();
        let rootact = NvUtils.getRootViewController();
        nvua.traverseViewHierarchy(act: rootact! ,uet:  uet, ev:  ev, autoTxn: autoTxn);
        //calling pagedump request
        var view = self.act!.view
        view =  NvUtils.getRootView(view: view!);
    }
    
    public func processTouchEvent( ev : CGPoint ){
        if (!NvCapConfigManager.getInstance().getNvControl().isRumEnabled()) {return;}
        
    }

    func addEventRequest(nvr: NvRequest, force: Bool = false)
    {
        if(NvActivityLifeCycleMonitor.mService != nil){
            NvActivityLifeCycleMonitor.mService!.addEventRequest(nvr: nvr, force: force);
        }
        
    }

    @objc public func flushAllQueue()
    {
        if(NvActivityLifeCycleMonitor.mService != nil){
            NvActivityLifeCycleMonitor.mService!.flushAllQueues();
        }
        
    }

    @objc public func flushAllRequests()
    {
        //self.flushAllQueue();
        if(NvActivityLifeCycleMonitor.mService != nil){
            NvActivityLifeCycleMonitor.mService!.flushAllRequests();
        }
        
    }

    func addTimingRequest( nvr: NvRequest) {
        if(NvActivityLifeCycleMonitor.mService != nil){
            NvActivityLifeCycleMonitor.mService!.addTimeRequest(nvr: nvr);
        }
        
    }

    func addRequest( nvr : NvRequest , priority : Bool = false){
        if( NvActivityLifeCycleMonitor.mService == nil && pendingReq != nil){
            // service connection not yet established
            // add the request to pendingReq queue to be sent to service when connection gets established
            
            pendingReq!.push_bottom(ele: nvr);
        }
        switch(nvr.reqCode) {
        case .USERACTION:
            if(NvActivityLifeCycleMonitor.mService != nil){
//                print("at.. if(NvActivityLifeCycleMonitor.mService != nil){")
                NvActivityLifeCycleMonitor.mService!.processUserActionRequest(nvr: nvr);
            }
            break;
        case .APIEVENT:
            if(NvActivityLifeCycleMonitor.mService != nil){
                NvActivityLifeCycleMonitor.mService!.processEventRequest(nvr: nvr);
            }
            
            break;
        case .APIACTION:
            if(NvActivityLifeCycleMonitor.mService != nil){
                NvActivityLifeCycleMonitor.mService!.processActionRequest(nvr: nvr);
            }
            
            break;
        case .HTTPLOG:
            if NvActivityLifeCycleMonitor.mService != nil {
                NvActivityLifeCycleMonitor.mService!.processHTTPLogRequest(nvr: nvr);
            }
            break;
        default:
            NSLog("[NetVision][NvActivityLifeCycleMonitor] adding request of type \(nvr.reqCode)")
            if(priority){
                if NvActivityLifeCycleMonitor.mService != nil {
                    NvActivityLifeCycleMonitor.mService!.addRequestInFront(nvr: nvr)
                }
            }
            else{
                if NvActivityLifeCycleMonitor.mService != nil {
                    NvActivityLifeCycleMonitor.mService!.addnvRequest(nvr: nvr);
                }
                
            }
        }
        return;
    }

    func getBlackoutViewList() -> nvLinkedList<Int>? {
        return blackoutViewList;
    }

    public func addToBlackoutList(viewId : Int){
        if (blackoutViewList == nil){
            blackoutViewList =  nvLinkedList<Int>();
        }
        var found = false;
        var blnode = blackoutViewList?.NodeAtTop();
        if(blnode != nil){
            while(blnode != nil && (blackoutViewList?.hasNext(node: blnode!)) != nil){
            
                let id = blnode?.val;
                if (viewId == id)
                {found = true; break;}
                blnode = blnode?.link;
            }
            if (!found){
                blackoutViewList?.push_bottom(ele: viewId) ;
            }
        }
        else {
            blackoutViewList?.push_bottom(ele: viewId);
        }
    }

    public func removeFromBlackoutList( viewId : Int ){
        if (blackoutViewList == nil){
            return;
        }
        var blnode = blackoutViewList?.NodeAtTop();
        while(blnode != nil && (blackoutViewList?.hasNext(node: blnode!)) != nil){
            let id = blnode?.val;
            if (viewId == Int(id!)) {
                blackoutViewList!.remove(node: &blnode);
                break;
            }
            blnode = blnode?.link;
        }
    }

    private func getActivityLifeCycleActName( act : UIViewController) -> String {
        var retr : UIView;
        retr = act.view;
        //var ret = (type(of: retr)).title ;
        var ret = act.nibName ;
        
        if ( !(act.view.description == "")){
            ret = act.view.accessibilityIdentifier! ;
            
        }
        
        return ret! ;
    }

    @objc public func setWebViewSyncVariable(wvh : NvWebViewHandler){
        if NvActivityLifeCycleMonitor.mService != nil {
            NvActivityLifeCycleMonitor.mService!._setWebViewHandler(wvh:wvh);
        }
    }

    @objc public func manageJavaScriptBridge( act : UIViewController, op : Int){
        if(act.view == nil){ return; }
        var webViewHandler = NvWebViewHandler.getInstance();
        var view = act.view!;
        webViewHandler.addWebViewListener(view: view);
    }
		 	
}

public class HttpMonitorStat {
    public static var request_count : UInt32 = 0
    public static var response_count : UInt32 = 0
    public static var error_count : UInt32 = 0
    public static var average_response_Time : Double = 0.00;
    public static var response_max : UInt32 = 0;
    public static var response_min : UInt32 = 1000000;
    public static var err_4xx : UInt32 = 0
    public static var err_5xx : UInt32 = 0
    public static var err_timeout : UInt32 = 0
    public static var err_conFail : UInt32 = 0
    public static var err_misc : UInt32 = 0
}
