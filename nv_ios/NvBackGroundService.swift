import UIKit;
import Foundation;



public class NvBackGroundService : NvServerAPI {
    private static let TAG = "NvBackGroundService";
    var url = "";
    // Binder given to clients
    //private let IBinder mBinder =   ServiceBinder();
    private static var NvService : NvBackGroundService? = nil
    private var nvrq = nvLinkedList<NvRequest>() ;
    private var pend_Srv_Req = nvLinkedList<NvRequest>();
    private var pend_Srv_Req_Thrd : ThreadQueue? = nil
    private var notExecutingPending : Bool = true;
    var nvAutoTxnList: [NvAutoTransaction] = [NvAutoTransaction]();
    var wvh : NvWebViewHandler?;
    var nvmd : NvMetadata = NvMetadata();
    
    //These are nvLinked of messages for different -2 kind of request.
    var userActionQueue : nvLinkedList < NvRequest > = nvLinkedList < NvRequest >()
    var ActionTiming = nvLinkedList < Int64 > ();
    var eventTiming = nvLinkedList < Int64 > ();
    var userTiming = nvLinkedList < Int64 > ();
    var httpLogQueue : nvLinkedList < NvRequest > = nvLinkedList < NvRequest >()
    var eventQueue : Array <NvRequest> = Array <NvRequest>();
    //var eventQueue : nvLinkedList < NvRequest > = nvLinkedList < NvRequest >()
    var timingDataQueue : nvLinkedList < NvRequest > = nvLinkedList < NvRequest >();
    var lastUQFlushTime : Int64 = 0;     // last time when user actions were flushed
    var lastEQFlushTime : Int64 = 0 ;     // last time when Event actions were flushed
    var lastTDflushTime : Int64 = 0 ;		// last time when timing data was flushed
    var lastHLflushTime : Int64 = 0 ;
    var timer : NvTimer? = nil;
    var flushAll : ThreadQueue? = nil;
    static private var pendingPIThreshold = 5;
    var canSendSessionInfoOrPagedump : Bool = true;
    private static var actionstarttime : Int64 = 0;
    public var lts : Int64 = -1 ;
    private var userActionRecordThresholdValue : Int64 = 10;  // default value can not be smaller than 1
    private var eventRecordThresholdValue : Int64 = 5;  // default value is five
    let metadata : NvMetadata = NvMetadata()
    
    override private init(){
        NSLog("[NetVision NvBackGroundService] init called");
        super.init();
        self.nvrq = nvLinkedList<NvRequest>();
        
        let nvcm = NvCapConfigManager.getInstance();
        userActionRecordThresholdValue = nvcm.getConfig().getUa().getclubThreshold();
        loadConfigFromServer(nvcm: nvcm);
        NvHWMonitor.shared()?.start();
        // init a timer and flush data after every one minute.
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.flushAllRequests), userInfo: nil, repeats: true);
        //[Timer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(flushAllRequests) userInfo:nil repeats:true]
    }
    
    static func stopService(){
        NvService = nil
        return;
    }
    
    static func startService() -> NvBackGroundService? {
        NSLog("[NetVision NvBackGroundService] startService called");
        if(NvService == nil){
            NvService = NvBackGroundService()
        }
        return NvService ;
    }
    
    
    func addInAutoTxnList(nvTxn: NvAutoTransaction){
        self.nvAutoTxnList.append(nvTxn);
    }
    
    static func setPendingPIThreshold(pi: Int) {
        pendingPIThreshold = pi;
    }
    
    static func getPendingPIThreshold() -> Int {
        return pendingPIThreshold;
    }
    
    @objc func flushAllRequests() {
        NSLog("[NetVision][NvBackGroundService] flushAllRequests triggered");
        self.flushAllQueues();
        if(flushAll == nil && !NvApplication.getSessId().elementsEqual("000000000000000000000")){
            flushAll = ThreadQueue();
            flushAll?.GlobalBackgroundQueue.async {
                self.sendPenend_Srv_Req_Data();
                while (!self.nvrq.isEmpty()){
                    self.processQueue()
                }
                self.flushAll = nil;
                //FIXME: here it might cause memory leak.
            }
        }
    }
    
    func updateActiveReqQueue() -> Bool {
        if(!NvApplication.getSessId().elementsEqual("000000000000000000000")){
            if(self.pend_Srv_Req_Thrd == nil){
                self.pend_Srv_Req_Thrd = ThreadQueue()
            }
            self.pend_Srv_Req_Thrd!.GlobalBackgroundQueue.async(){
                // update data in active queue.
                if(!self.nvrq.isEmpty()){
                    var nvr : NvRequest? = self.nvrq.getNext(fromTop: true);
                    while(nvr != nil){
                        if(nvr!.reqCode == .READYFORSERVER)
                        {
                            self.pend_Srv_Req.push_bottom(ele: nvr!);
                            nvr = self.nvrq.getNext(deleteCurrent: true);
                        } else {
                            nvr = self.nvrq.getNext();
                        }
                    }
                }
            }
            return true;
        }
        return false;
    }
    
    func sendPenend_Srv_Req_Data(){
        if notExecutingPending && !pend_Srv_Req.isEmpty() {
            if(self.pend_Srv_Req_Thrd == nil){
                self.pend_Srv_Req_Thrd = ThreadQueue()
            }
            self.pend_Srv_Req_Thrd!.GlobalBackgroundQueue.async(){
                // update data in active queue.
                self.notExecutingPending = false;
                var nvr : NvRequest? = self.pend_Srv_Req.getNext(fromTop: true);
                while(nvr != nil){
                    // check for pageInstance diff
                    let pi = nvr?.getReqData().getPageInstance()
                    if(NvApplication.getpageInstance() - pi! <= NvBackGroundService.getPendingPIThreshold()) {
                        self.SendToServer(nvr: nvr!);
                    }
                    nvr = self.pend_Srv_Req.getNext( deleteCurrent: true);
                }
                self.notExecutingPending = true;
            }
        }
    }
    
    func addnvRequest(nvr : NvRequest) -> Bool {
        nvr.status = .PENDING;
        let lockQueue = DispatchQueue(label: "com.test.LockQueue")
        if(lockQueue == nil){
        }
        lockQueue.sync() {
            self.nvrq.push_bottom(ele: nvr);
            self.processQueue();
        }
        return true;
    }

    func addTimeRequest(nvr : NvRequest) {
                self.timingDataQueue.push_bottom(ele: nvr);
    }
    
    internal func addRequestInFront(nvr : NvRequest) -> Bool {
        NSLog("[NetVision NvBackGroundService] addRequestInFront called");
        nvr.status = .PENDING;
        let lockQueue = DispatchQueue(label: "com.test.LockQueue")
        lockQueue.sync() {
            
            if(nvr.reqCode == NvRequest.REQCODE.ACCOUNTLOGIN || nvr.reqCode == .CONFIGREQ ){  // name
                var tmp : NvRequest? = nil
                // If nvrq is not empty and on top it has request which is in SERVICING state then add new request just after SERVICING one.
                if(self.nvrq.size() > 0){
                    tmp = self.nvrq.ElementAtTop();
                    if(tmp?.status == .SERVICING){
                        self.nvrq.pop();
                        self.nvrq.push_top(ele: nvr);
                        if(tmp!.reqCode == .ACCOUNTLOGIN || tmp!.reqCode == .CONFIGREQ)
                        {
                            self.nvrq.push_top(ele: tmp!);
                        }
                        else {
                            self.nvrq.push_bottom(ele: tmp!);
                        }
                    }
                    else{
                        self.nvrq.push_top(ele: nvr)
                    }
                }
                else {
                    self.nvrq.push_top(ele: nvr)
                }
            }
                // Check if new request is SESSIONINFO and request on top of queue is neither CONFIG or ACCOUNTLOGIN then add SESSIONINFO on top.
            else if (nvr.reqCode == .SESSIONINFO && self.nvrq.size() > 0) {
      
                if(self.nvrq.ElementAtTop()?.getReqCode() == .CONFIGREQ || self.nvrq.ElementAtTop()?.getReqCode() == .ACCOUNTLOGIN ){
                    var tmp:NvRequest = self.nvrq.ElementAtTop()!;
                    self.nvrq.pop();
                    self.nvrq.push_top(ele: nvr)
                    self.nvrq.push_top(ele: tmp);
                }
                else{
                    self.nvrq.push_top(ele: nvr);
                }
            }
            else {
                //else push after config and accountlogin.
                if(NvApplication.getSessId().elementsEqual("000000000000000000000")){
                    self.nvrq.push_bottom(ele: nvr);
                }
                self.nvrq.push_top(ele: nvr)
            }
            self.processQueue();
        }
        return true;
    }
    func deleteRequest( nvr : NvRequest? ) -> Bool {
        // it will delete only from the head
        let lockQueue = DispatchQueue(label: "com.test.LockQueue");
        lockQueue.sync() {
            
            let qnvr = self.nvrq.ElementAtTop();
            if (qnvr != nil){
                if (nvr != nil){
                    if (qnvr!.ts == nvr!.ts){
                        self.nvrq.pop();
                    }
                }
                else {
                    self.nvrq.pop();
                }
            }
        }
        return true;
    }
    
    func canSendTiming() -> Bool {
        let lockQueue = DispatchQueue(label: "com.test.LockQueue");
            if(self.nvrq != nil && !self.nvrq.isEmpty()) {
            lockQueue.sync(){
                var nvr:NvRequest = nvrq.ElementAtTop()!;
                if(!(nvr != nil && nvr.getStatus() == .SERVICING && (nvr.getReqCode() == .SESSIONINFO || nvr.getReqCode() == .PAGEDUMP))){
                    canSendSessionInfoOrPagedump = false;
                }
            }
        }
        else {
            canSendSessionInfoOrPagedump = false;
        }
        return !canSendSessionInfoOrPagedump;
    }
    
    func enableSesssionInfoReq() {
        canSendSessionInfoOrPagedump = true;
        self.processQueue();
    }

    private func processPageDumpRequest( nvr : NvRequest ) {
        func handleResponse(serv : NvBackGroundService , hrw : HttpResponseWrapper ) {
            var nvr : PagedumpResponse? = Mapper<PagedumpResponse>().map(JSONString: hrw.getResponseString());
            if(nvr == nil){
                return;
            }
            let check = (responseCommonProcessing( hrw: hrw, nvr: nvr!))
            let npdr = nvr ;
            if (check != nil){
                
                processCallBack( nr: npdr!);
                processPagedumpResponse( npdr: npdr!)
                nvrq.pop();
                processQueue();
                
            }
            else {
                processQueue();
            }
        }
        
        let nvconfig = NvCapConfigManager.getInstance().getConfig();
        
        let pdd = (nvr.getReqData()) as! PageDumpData
        let compressionMode = (pdd.getCaptureFlag() == NvCapConfig.PAGEDUMP_COMPRESSED);
        var JpegImage : NSData = (pdd.getBmap()?.compress(quality: 0.5))!;
        if(compressionMode){
            JpegImage = (pdd.getBmap()?.compress())!;
        }
        
        let len = JpegImage.length
        
        var image = [UInt8](repeating : 0, count : len)
        
        JpegImage.getBytes(&image , length: JpegImage.length )
        
        var pageInstance : Int = 0;
        var snapshotInstance : Int = 0;
        
        if(NvApplication.getSessId() == pdd.getSessionId()){
            NSLog("[NetVision][NvBackGroundService] pageInstance value should be \(pdd.getPageInstance())")
            pageInstance = pdd.getPageInstance();
            snapshotInstance = pdd.getSnapShotInstance();
        }
        else {
            pageInstance = NvApplication.getpageInstance()
            snapshotInstance = NvApplication.getSnapShotInstance();
        }
        let url  = "\(nvconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=200&m=0&op=pagedump&pi=\(pageInstance)&d=\(pdd.getCaptureFlag())%7C\(snapshotInstance)&lts=\(lts)" ;
        let pagedumpcallback =   NvHttpClientResponseCallback()
        
        let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: NSURL(string: url)! , ldata: image, callback: pagedumpcallback);

        let tq = ThreadQueue();

        tq.GlobalUtilityQueue.async() {
            var hrw : HttpResponseWrapper ;
            var status : Bool ;
            (hrw,status) = nvc.doInBackground();
            if ( status == false) {
                return ;
            }
            tq.GlobalMainQueue.async() {
                handleResponse(serv: self, hrw: hrw);
            }
        }
        return;
    }

    func flushUserActionRecord ( forceFlag : Bool) {
        func handleResponse(serv : NvBackGroundService , hrw : HttpResponseWrapper) {
            var nvresp : NvResponse? = nil;

            nvresp = Mapper<NvResponse>().map(JSONString: hrw.getResponseString())!
            if(nvresp == nil){
            }
            let nr = (responseCommonProcessing( hrw: hrw, nvr : nvresp! )) as NvResponse?;
            if (nr != nil){
                processCallBack( nr: nvresp!);
                if(nvrq.size()>0){
                    processQueue();
                }
            }
            else {
                processQueue();
            }
        }
        if(!NvApplication.getSessId().elementsEqual("000000000000000000000") && (forceFlag || userActionQueue.size() >= userActionRecordThresholdValue) )
        {
            if(userActionQueue.size() == 0) {return;}
            var ptr = userActionQueue.NodeAtTop();
            var (userActionPostData, prevPageInstance) = stringifyUserAction(nvr: (ptr?.val)!) ;
            userActionQueue.pop();
            
            while(userActionQueue.size()>0){
                ptr = userActionQueue.NodeAtTop();
                let (userActionData, pageInst) = stringifyUserAction(nvr: (ptr?.val)!) ;
                if(prevPageInstance == pageInst){
                    userActionPostData += "\n"+userActionData;
                }
                else{
                    break;
                }
                userActionQueue.pop();
            }
            
            let nvcconfig = NvCapConfigManager.getInstance().getConfig();
            
            let url =   "\(nvcconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(UserActionData.messageversion)&op=useraction&pi=\(prevPageInstance)&pid=\(NvApplication.getPageId())&lts=\(lts)" ;
            
            let userActioncallback =   NvHttpClientResponseCallback() ;
            //override
            var postData : [UInt8]
            postData = Array(userActionPostData.utf8);
            let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: NSURL(string: url)!, ldata: postData, callback: userActioncallback);
            let tq = ThreadQueue();
            let rfc = ReadyForServer();
            rfc.setNvClient(nvc: nvc);
            rfc.setCallBack(cB: handleResponse(serv:hrw:));
            rfc._setReqCode(reqCode: .READYFORSERVER);
//            if(NvApplication.getSessId().elementsEqual("000000000000000000000")) {
            self.addnvRequest(nvr: rfc);
//            }
//            else {
//                self.addRequestInFront(nvr: rfc);
//            }
            
//            tq.GlobalUtilityQueue.async() {
//                var hrw : HttpResponseWrapper ; var status : Bool ;
//                (hrw,status) = nvc.doInBackground();
//                if ( status == false) {
//                    return ;
//                }
//                tq.GlobalMainQueue.async() {
//                    handleResponse(serv: self, hrw: hrw);
//
//                }
//            }
            lastUQFlushTime = NvTimer.current_timestamp();
            
        }
    }
    
    func processCallBack( nr : NvResponse){
        //getting sessionid from NvResponse
        
//        let sessid = nr.getSID();
//        let csessId = NvApplication.getSessId();
        lts = nr.lts;
        if(wvh != nil){
            wvh!.syncWebView(data: ["lts"]);
        }
        self.processQueue();
        
    }
    
    internal func flushEventRecord( forceFlag : Bool ) {
        
        if ( !NvApplication.getSessId().elementsEqual("000000000000000000000") && (forceFlag || eventQueue.count >= eventRecordThresholdValue) )
        {
            print("[NetVision][NvBackGroundService] entered inside flushEventRecord");
            if(eventQueue.isEmpty)
            { return ; }
            //TODO: check here if sid or pageindex not _set then don't send the data.
//            var eventPostData: String = "";
//            var prevPageInst: Int = 0;
//            var ptr = eventQueue.last;
//            let er = (ptr?.val)!.getReqData() as! EventRequest ;
            // log prior pageStartData(i.e, pageStart request of a viewWillAppear) only when next pageInstance is higher than current pageInstance b/c we have to wait for viewDidAppear pageStart request.
//            if(er.getPageInstance()-1 == NvBackGroundService.evReqLastPageStart && NvBackGroundService.priorPageStartData.count > 0) {
//                NSLog("[NetVision][NvBackGroundService] this is prior(i.e, viewWillAppear) page start request for page instance %lu", er.getPageInstance());
//                eventPostData += NvBackGroundService.priorPageStartData;
//                prevPageInst = er.getPageInstance()-1;
//                NvBackGroundService.priorPageStartData = "";
//            }
//            else {
            var (eventPostData, prevPageInst) = stringifyEventRequest(nvr: (eventQueue.last)!);
            eventQueue.popLast();
            while(eventQueue.count>0){
                let (eventDat, pageInst) = stringifyEventRequest(nvr: (eventQueue.last)!);
                if(prevPageInst == pageInst){
                    eventPostData += eventDat;
                }
                else{
                    break;
                }
                print("[NetVision][NvBackGroundService] event post data is : %s",eventPostData);
                eventQueue.popLast();
            }
            var postData : [UInt8];
            if(eventPostData.count <= 0){ return; }
            postData = Array(eventPostData.utf8);
            //create UserAction url.
            //format: <beaconUrl>?s=<sid>&op=useraction
            let nvcconfig = NvCapConfigManager.getInstance().getConfig();
            
            let url =   "\(nvcconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(EventRequest.messageversion)&op=el&pi=\(prevPageInst)&pid=\(NvApplication.getPageId())&lts=\(lts)";
            
            let eventcallback =   NvHttpClientResponseCallback()
            
            
            
            //override
            func handleResponse(serv : NvBackGroundService, hrw : HttpResponseWrapper) {
                
                var nvresp : NvResponse? = nil;
                nvresp = Mapper<NvResponse>().map(JSONString: hrw.getResponseString())!
                if(nvresp == nil){
                    ////NSLog("[NetVision] Mapping response unsuccessful");
                }
                
                let nr = responseCommonProcessing( hrw: hrw, nvr : nvresp! ) as NvResponse?
                if (nr != nil){
                    processCallBack( nr: nvresp!);
                    processQueue();
                }
                else
                {processQueue();}
            }
            NSLog("[NetVision][NvBackGroundService] post data generated for event request for pageInstance %lu is %@", prevPageInst, eventPostData);
            let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: NSURL(string: url)!, ldata: postData, callback: eventcallback);
//            let tq = ThreadQueue();

            let rfc = ReadyForServer();
            rfc.setNvClient(nvc: nvc);
            rfc.setCallBack(cB: handleResponse(serv:hrw:));
            rfc._setReqCode(reqCode: .READYFORSERVER);
            if( NvApplication.getSessId().elementsEqual("000000000000000000000") ) {
                self.addnvRequest(nvr: rfc);
            }
            else {
                self.addRequestInFront(nvr: rfc);
            }
//            tq.GlobalUtilityQueue.async() {
//                var hrw : HttpResponseWrapper ;
//                var status : Bool ;
//                (hrw,status) = nvc.doInBackground();
//                if ( status == false) {
//                    return ;
//                }
//                tq.GlobalMainQueue.async() {
//
//                    handleResponse(serv: self, hrw: hrw);
//
//                }
//            }
            lastEQFlushTime = NvTimer.current_timestamp();
        }
    }
    
    func stringifyTimingRequest(nvr : NvRequest ) -> (String, Int) {
        let action = nvr.getReqData() as! NvAction;
        
        let lifeEvent = action.acttiming.lifeEvent
        var actionNameSuffix = "";
        
        if(lifeEvent == .CREATE){
           actionNameSuffix = "CREATE"
        }
        else if ( lifeEvent == .START){
           actionNameSuffix = "START"
            if( action.getStage() == .END){
                actionNameSuffix = "END"
            }
        }
        else if ( lifeEvent == .RESUME){
            actionNameSuffix = "RESUME"
        }
        else if ( lifeEvent == .PAUSE){
            actionNameSuffix = "PAUSE"
        }
        else if ( lifeEvent == .STOP){
            actionNameSuffix = "STOP"
        }
        else if ( lifeEvent == .DESTROY){
            actionNameSuffix = "DESTROY"
        }
        else if ( lifeEvent == .VIEWDIDLAYOUTSUBVIEWS){
            actionNameSuffix = "VIEWDIDLAYOUTSUBVIEWS"
        }
        else if ( lifeEvent == .VIEWDIDLOAD){
            actionNameSuffix = "VIEWDIDLOAD"
        }
        else if ( lifeEvent == .VIEWDIDAPPEAR){
            actionNameSuffix = "VIEWDIDAPPEAR"
        }
        else if ( lifeEvent == .VIEWWILLDISAPPEAR){
            actionNameSuffix = "VIEWWILLDISAPPEAR"
        }
        actionNameSuffix += " : " + action.getViewName();
        let nv = NSCharacterSet.urlQueryAllowed;
        print("[NetVision] Action Data retrieved is : \(action.getActionData())" );
        var urlactiondata = action.getActionData().addingPercentEncoding(withAllowedCharacters: nv)!;
        
        print("[NetVision] Action Data % encoding is : \(urlactiondata)" );
        var acttype = 0;
        if(action.getType() == NvAction.ActionType.MARK){
            urlactiondata = action.NvActionData.addingPercentEncoding(withAllowedCharacters: nv)!;
            acttype = 0;
        }
        else if(action.getType() == NvAction.ActionType.MEASURE){
            acttype = 1;
        }
        else if(action.getType() == NvAction.ActionType.USERTIMING){
            acttype = 2;
        }
        else if(action.getType() == NvAction.ActionType.TRANSACTION){
            urlactiondata = action.NvActionData.addingPercentEncoding(withAllowedCharacters: nv)!;
            acttype = 3;
        }
        
        let actStr = "\(action.getSessionId())|\(action.getPageId())|\(action.getPageInstance())|\(NvCapConfig.getChannelId())|\(action.getTs())|\(action.getActionName())|\(acttype)|\(action.getDuration())|\(urlactiondata)|\(action.getFF1())|\(action.getFFS1())\n" ;
        
        print("[NetVision][NvBAckGroundService][stringifyTimingRequest] \(actStr)")
        return (actStr, action.getPageInstance());
    }
    
    //self method will collect all the timing records and will send to server.
    internal func flushTimingRecord ( forceFlag : Bool){
        let size:Int64 = Int64(timingDataQueue.size());
        if((forceFlag || Int64(timingDataQueue.size()) >= userActionRecordThresholdValue) && !NvApplication.getSessId().elementsEqual("000000000000000000000"))  {
            
            if(timingDataQueue.size() == 0) {return;}
            
            var iterator = timingDataQueue.NodeAtTop();
            
            var (timingData, prevPageInst) = stringifyTimingRequest(nvr: (iterator?.val)!) ;
            print("[NetVision] Timing data queue is : \(timingData)");
            timingDataQueue.pop();  
            
            while(timingDataQueue.size() > 0)
            {
                iterator = timingDataQueue.NodeAtTop();
                var (timingDat, pageInst) = stringifyTimingRequest(nvr: (iterator?.val)!);
                if(prevPageInst == pageInst) {
                    timingData += timingDat;
                }
                else {
                    break;
                }
                print("[NetVision]: Timing data is-> \n  \(timingData)");
                timingDataQueue.pop();
                
            }
            //convert self post data into byte nvLinked.
            var postData : [UInt8];
            
            
            postData = Array(timingData.utf8);
            print("@[NetVision] data generated while usertiming request is : \(postData)");
            //create UserAction url.
            //format: <beaconUrl>?s=<sid>&op=timing
            var nvcconfig = NvCapConfigManager.getInstance().getConfig();
            
            var uRl : NSURL;
            
            var url = "\(nvcconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(ReqData.messageversion)&op=usertiming&pi=\(prevPageInst)&CavStore=000&d=\(NvApplication.getPageId())%7C\(NvCapConfig.getChannelId())&pid=0&lts=\(lts)";
            var userActioncallback =   NvHttpClientResponseCallback()


            //override
            func handleResponse(serv : NvBackGroundService, hrw : HttpResponseWrapper) {
                var nvresp : NvResponse? = nil;

                nvresp = Mapper<NvResponse>().map(JSONString: hrw.getResponseString())!
                if(nvresp == nil){
                    return
                }
                let check = (responseCommonProcessing( hrw: hrw, nvr : nvresp! )) as NvResponse? ;
                let nr = nvresp;
                if (check != nil){
                    processCallBack( nr: nr!);
                    processQueue();
                }
                else {
                    processQueue();
                }
            }

            let nsurl = NSURL(string: url)!
            let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: nsurl, ldata: postData, callback: userActioncallback);
            //let tq = ThreadQueue();

            let rfc = ReadyForServer();
            rfc.setNvClient(nvc: nvc);
            rfc.setCallBack(cB: handleResponse(serv:hrw:));
            rfc._setReqCode(reqCode: .READYFORSERVER);
//            if(NvApplication.getSessId().elementsEqual("000000000000000000000")) {
            self.addnvRequest(nvr: rfc);
//            else {
//                self.addRequestInFront(nvr: rfc);
//            }
//            tq.GlobalUtilityQueue.async() {
//                var hrw : HttpResponseWrapper ;
//                var status : Bool ;
//                (hrw,status) = nvc.doInBackground();
//                if ( status == false) {
//                    return ;
//                }
//                tq.GlobalMainQueue.async() {
//
//                    handleResponse(serv: self, hrw: hrw);
//
//                }
//            }
            lastTDflushTime = NvTimer.current_timestamp();
        }
    }
    
    
    private func processConfigResponse(app : UIApplication , cr: ConfigResponse){
        
        let configString = cr.getConfig();
        var nvConfig = NvCapConfig();
        nvConfig = Mapper<NvCapConfig>().map(JSONString: configString)!
        
        let nvcm = NvCapConfigManager.getInstance();
        nvcm._setNvConfig(nvConfig: nvConfig);
        
        nvcm.saveConfigIntoSharedPref(prefString: configString);
        
        self.nvrq.pop();
        // If SessionInfo request is not sent yet then send.
        if(NvApplication.getSessId() == "000000000000000000000") {
            let sessInfo =   NvSessionInfo(serv: self);
            sessInfo._sendSessionInfo();
        }
        processQueue();
    }

    private func processConfigReq(nvr : NvRequest) {
        var callback : NvHttpClientResponseCallback
        callback = NvHttpClientResponseCallback() ;
        func handleResponse( serv : NvBackGroundService, hrw : HttpResponseWrapper ) {
            
            let response = hrw.getHres();
            if(response == nil){
            }
            var respheaders = (response?.allHeaderFields);
        
            var value : String = "" ;
            
            if(respheaders == nil ){
            }
            else {
                if ( respheaders!["Etag"] == nil){
                }
                else {
                value = respheaders!["Etag"] as! String;
                }
            }
            
            let preferences = UserDefaults.standard
            
            let currentLevelKey = "NetVisionEtag"
            let currentLevel = NSString(string: value)
            
            preferences.set(currentLevel, forKey: currentLevelKey)
            
            let didSave = preferences.synchronize()
            
            if !didSave {
            }
            
            let crs : String? = hrw.getResponseString();
            
            if (crs != nil){
                let cr = ConfigResponse();
                cr._setConfig(config: crs!);
                processConfigResponse(app: NvApplication.getApp(),cr:  cr);
            
            }
            else {
            }
        }
        
        
        let nvc = NvHttpClient( service: self , lrequestType: "GET", lurl: NSURL(string: NvCapConfigManager.getInstance().getConfig().getConfig_url())!, ldata: nil, callback: callback);
        
        let tq = ThreadQueue();
        
        tq.GlobalUserInitiatedQueue.async() {
            var hrw : HttpResponseWrapper ;
            var status : Bool ;
            (hrw,status) = nvc.doInBackground();
            if ( status == false) {
                return ;
            }
            tq.GlobalMainQueue.async() {
                handleResponse(serv: self, hrw: hrw);
            }
        }
    }
    
    private func processAccountLogin(nvr : NvRequest){
        
        var al = nvr.getReqData() as! AccountLogin
        var accountLoginInfo = al.getApiKey()+"\n";
        
        var url = "\(NvCapConfig.CAV_RUM_SERVICE_AUTH_URL)?op=accountAuth";
        
        var accountAuthCallback =   NvHttpClientResponseCallback()
        let accountInfo : [UInt8]? = Array(accountLoginInfo.utf8)
        //override
        func handleResponse(serv : NvBackGroundService, hrw : HttpResponseWrapper) {
            
            // FIXME: there is no retry limit.
            if(hrw.getCode() != 200 ){
                let request = self.nvrq.ElementAtTop();
                self.deleteRequest(nvr: nil);
                self.addRequestInFront(nvr: request!);
            }
            else {
                self.deleteRequest(nvr: nil);
                processAuthResponse(hrw: hrw);
            }
        }

        if NSURL(string: url) == nil
        {
        }

        if(NvCapConfigManager.getInstance().getNvControl().isAccountAuthenticated()){
            return;
        }
        
        let nvc =   NvHttpClient(service: self, lrequestType: "GET", lurl: NSURL(string: url)!, ldata: accountInfo, callback: accountAuthCallback);
        
        let tq = ThreadQueue();
        
        tq.GlobalUtilityQueue.async() {
            
            var hrw : HttpResponseWrapper ;
            var status : Bool ;
        
            (hrw,status) = nvc.doInBackground();
            if ( status == false) {
                return ;
            }
            tq.GlobalMainQueue.async() {
                handleResponse(serv: self, hrw: hrw);
                
            }
        }
    }
    
    private func processSessionInfoRequest(nvr : NvRequest){

        let si =  nvr.getReqData() as! SessionInfo ;

        var versionnumber = 1;
        metadata.update_conntype()
        metadata.update_Location()

        //FIXME: missing argument is sessioninfodata -> model, countryName.
        let sessioninfodata =   "{\"dinfo\":{\"Device\":\"\(si.getDinfo()!.getDevice()) \",\"versionname\":\"\(si.getDinfo()!.getVersionname())\",\"Brand\":\"\(si.getDinfo()!.getBrand())\",\"Display\":\"\(si.getDinfo()!.getDISPLAY())\",\"Manufacturer\":\"\(si.getDinfo()!.getManufacturer())\",\"product\":\"\(si.getDinfo()!.getProduct())\",\"Release\":\"\(si.getDinfo()!.getRelease())\",\"ScreenHeight\":\"\(si.getDinfo()!.getScreenHeight())\",\"ScreenWidth\":\"\(si.getDinfo()!.getScreenWidth())\",\"VersionCode\":\"\(si.getDinfo()!.getVersioncode())\",\"API\":\"\(si.getDinfo()!.getAPI())\"},\"linfo\":{\"City\":\"\(si.getLinfo()!.getCity())\",\"State\":\"\(si.getLinfo()!.getState())\",\"Latitude\":\"\(si.getLinfo()!.getLatitude())\",\"Longitude\":\"\(si.getLinfo()!.getLongitude())\",\"CountryCode\":\"\(NvMetadata.GEO_LOCID)\",\"CountryName\":\"\(si.getLinfo()!.getCountryCode())\"}}" ;

 //       var nva = NvApplication.getApp()

        NvCapConfig.screenID = "68";
        
        let data =   "\(NvCapConfig.BrowserId)|\(NvMetadata.SCREEN)|\(NvCapConfig.AccessType)|\(NvCapConfig.MonitorColorDepth)|-1|\(NvCapConfig.Platform)|\(NvCapConfig.UserAgent)|\(NvSessionInfo.browserLang)|\(NvCapConfig.BrowserPlugin)|\(NvCapConfig.BrowserCname)|\(NvCapConfig.DoNotTrack)|Mobile|\(NvApplication.MobileAppversion)|\(NvCapConfig.MobileOsVersion)|-1|-1|-1|-1|\(NvMetadata.CARRIER)|\(NvMetadata.CONNECTION_TYPE)|\(NvMetadata.GEOID)|\(NvMetadata.GEO_LOCID)|\(NvMetadata.APP)|\(NvMetadata.VERSION)|\(NvMetadata.MANUFACTURE)|\(NvMetadata.MODEL)|\(NvCapConfig.getChannelId())|\(sessioninfodata)";
        
        //Encoding data
        let d = data.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)! as String
        let pInst = NvApplication.getpageInstance();
        let url =   "\(NvCapConfigManager.getInstance().getConfig().getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(SessionInfo.messageversion)&op=sessionInfo&pi=\(pInst)&pid=\(NvApplication.getPageId())&d=\(d)&lts=\(lts)"
        
        let sInfoCallback =   NvHttpClientResponseCallback()
        
        func handleResponse(serv : NvBackGroundService, hrw : HttpResponseWrapper) {
            NSLog("[NetVision][NvBackGroundService] handle response triggered and response string is %@", hrw.getResponseString())
            var nvresp : NvResponse? = nil;
            if(hrw.getResponseString() != nil || hrw.getResponseString() != ""){
                NSLog("[NetVision][NvBackGroundService] response string not empty")
                
                let jsonString = hrw.getResponseString()
                jsonParser(jsonString: jsonString)
                
                nvresp = Mapper<NvResponse>().map(JSONString: hrw.getResponseString())
                if(nvresp == nil){
                    processQueue();
                }
                else{
                    let nr = responseCommonProcessing( hrw: hrw , nvr: nvresp!) as NvResponse? ;
                    if (nr != nil){
                        NSLog("[NetVision][NvBackGroundService] response received and SID is %@", nvresp!.getSID());
                        let sessid = nvresp!.getSID();
                        let accessType = nvresp!.getAccessType();
                        NvMetadata.ACCESSTYPE = String(accessType)
                        let geoId = nvresp!.getGeoId()
                        NvMetadata.GEOID = String(geoId);
                        let locationId = nvresp!.getLocationId()
                        NvMetadata.GEO_LOCID = String(locationId)
                        let prevSid = NvApplication.getSessId();
                        NvApplication._setSessId(sessIdentifier: sessid);
                        if(wvh != nil){
                            wvh!.syncWebView(data: ["sid"]);
                        }
                        NvActivityLifeCycleMonitor.updateCrashFile()
                        lts = (nr?.lts)!;
                        self.deleteRequest(nvr: nil);
                        
                        if(prevSid != sessid) {
                            if(prevSid.elementsEqual("000000000000000000000")){
                                NSLog("[NetVision][NvBackGroundService] prev sid was an empty string i.e, 000000000000000000000 now flushing data");
                                addSIDFlush();
                            }
                            else {
                                NSLog("SID changed now the ")
                                clearQueue();
                                NvApplication._setpageInstance(pageIns: 1);
                                NvApplication._setSnapShotInstance(snapShotInst: 0);
                            }
                        }
                    
                        processQueue();
                    }
                    else {
                        processQueue();
                    }
                }
                
            }
            else{
                processQueue();
            }
            
        }
        
        var SessInfoData : [UInt8]
        SessInfoData = Array(sessioninfodata.utf8);
        
        let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: NSURL(string: url)!, ldata: SessInfoData , callback: sInfoCallback);
        
        let tq = ThreadQueue();
        
        tq.GlobalMainQueue.async() {
            var hrw : HttpResponseWrapper ;     
            var status : Bool ;
            (hrw,status) = nvc.doInBackground();
  //          NSLog("hrw and status value set and status is : %@", status)
            if ( status == false) {
                return ;
            }
            tq.GlobalMainQueue.async() {
                
                handleResponse(serv: self, hrw: hrw);
                
            }
        }
    }
    
    private func addSIDFlush() {
        func changeSID(queue : nvLinkedList < NvRequest >){
            if(!httpLogQueue.isEmpty()){
                var req : NvRequest? = queue.getNext(fromTop: true);
                while(req != nil){
                    switch (req?.getReqCode()) {
                    case .USERACTION?:
                        let action = req!.reqData as! UserActionData ;
                        action._setSessionId(sessionId: NvApplication.getSessId());
                        break;
                    case .APIACTION?:
                        let action = req!.reqData as! NvAction;
                        action._setSessionId(sessionId: NvApplication.getSessId());
                        break;
                    case .HTTPLOG?:
                        let action = req!.reqData as! HttpLogRequest;
                        action._setSessionId(sessionId: NvApplication.getSessId());
                        break;
//                    case .APIEVENT:
//                        action = req?.reqData as! EventRequest;
//                        break;
                    default:
                        break;
                    }
                    
                    req = queue.getNext();
                }
            }
        }
        if(!nvrq.isEmpty()){
          var nvr : NvRequest? = nvrq.getNext(fromTop: true);
          while(nvr != nil){
            if(nvr?.getReqCode() == .PAGEDUMP){//FIXME: change the data in record as well.
                let pdd = (nvr!.getReqData()) as! PageDumpData;
                pdd._setSessionId(sessionId: NvApplication.getSessId());
//            case .USERACTION:
//                let uad = nvr!.reqData as! UserActionData ;
//                uad._setSessionId(sessionId: NvApplication.getSessId());
//                break;
//            case .APIEVENT:
//                let er = nvr!.getReqData() as! EventRequest ;
//                er._setSessionId(sessionId: NvApplication.getSessId());
//                break;
//            case .APIACTION:
//                let action = nvr!.getReqData() as! NvAction;
//                action._setSessionId(sessionId: NvApplication.getSessId());
//                break;
//            case .HTTPLOG:
//                let httpData = nvr!.reqData as! HttpLogRequest;
//                httpData._setSessionId(sessionId: NvApplication.getSessId());
//                break;
            }
            nvr = nvrq.getNext();
          }
        }
        
        changeSID(queue: timingDataQueue)
        changeSID(queue: userActionQueue)
        changeSID(queue: httpLogQueue);

        if(eventQueue.count != 0){
            var i = 0, len = eventQueue.count;
            while(i<len){
                let nvr = eventQueue[i];
                let pdd = (nvr.getReqData()) as! EventRequest;
                pdd._setSessionId(sessionId: NvApplication.getSessId());
                i += 1;
            }
        }
    }


    func processActionRequest( nvr : NvRequest){
        timingDataQueue.push_bottom(ele: nvr);
        flushTimingRecord(forceFlag: false);
       
    }
    
    func stringifyEventRequest( nvr : NvRequest ) -> (String, Int) {
        
        let er = nvr.getReqData() as! EventRequest ;
        //this check prevents the case:
        //  when we are generating data for some pageInstance suppose 4 and suppose next request is a PageStart request with pageInstance 5 then in flushEventRecord function we might skip that request (i.e, first PageStart of 5) and we might also set NvBackGroundService.evReqLastPageStart flag to 5 b/c of which pageStart for 5 will never trigger, below check will skip those cases and will reduce some processing as well.

        
        var eventRecord =   "\(er.getSessionId())|\(er.getPageId())|\(er.getPageInstance())|\(er.gettimestamp())|\(er.getEvName())|";
        print("[NetVision][Event] eventRecord so far is : \(eventRecord)");
        if !(er.Misc.elementsEqual("")){
            eventRecord = eventRecord + "|\(er.Misc)"
        }
        
        //convert dict data into json string.
        
        //get name value.
        var prop : [ String : String ]?
        var data = "";
        var first = true;
        prop = er.getProp();
        print("[NetVision][Event] stringifyEventRequest triggered and prop is : \(prop)")
        if (prop != nil){
            for (_key , value) in prop! {
                if(first) {
                    data += "{";
                    data += "\"\(_key)\":\"\(value)\"";
                    first = false;
                }
                else {
                    data += ",\"\(_key)\":\"\(value)\"";
                }
            }
            if(first == false) {
              data += "}";
            }
        }
        
        eventRecord += data;
        
        if(er.evName != "customMetrics" && er.evName != "SessionID" && er.evName != "OrderTotal" && er.evName != "LoginID" && er.evName != "userSegmentMask" && er.evName != "transactionID")
        {
            eventRecord = eventRecord + "|";
        }
        
        eventRecord += "\n";
        
        return (eventRecord, er.getPageInstance());
    }
    
    func processEventRequest(nvr : NvRequest) {
        eventQueue.append(nvr);
        //flush  eventRequest.
        flushEventRecord(forceFlag: false);
    }
    
    public func addEventRequest(nvr: NvRequest, force: Bool = false) {
        eventQueue.append(nvr);
        flushEventRecord(forceFlag: force);
    }
    
    private func getPropertyValue( key : String, valueObject : Any) -> String {
        var value : String = "";
        if (valueObject is Int.Type) {
            value = "\(valueObject as! Int)";
        }
        else if (valueObject is String.Type){
            value = valueObject as! String;
        }
        else if (valueObject is Double.Type){
            value = "\(valueObject as! Double)";
        }
        else if (valueObject is NSDate){
            value = "\(valueObject as! NSDate)";
        }
        else if (valueObject is Bool){
            value = "\(valueObject as! Bool)";
        }
        else if (valueObject is Float){
            value =  "\(valueObject as! Float)";
        }
        return  "\(key): \(value)";
        
    }
    
    
    func processUserActionRequest(nvr : NvRequest)
    {
//        print("at.. func processUserActionRequest(nvr : NvRequest)")
        //Now add self record into userActionRecord.
        userActionQueue.push_bottom(ele: nvr);
        flushUserActionRecord(forceFlag: false);
    }
    
    func stringifyUserAction(nvr : NvRequest) -> (String, Int) {
//        print("at.. stringifyUserAction")
        let uad = nvr.reqData as! UserActionData ;
        let useractionRecord: String;
        if !(uad.getEvType() == 107){
            let data = String(uad.getValue().reversed()).data(using: .utf8)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as! String;
            let val = String(uad.getValue().count)+"."+data;
            useractionRecord = "\(NvApplication.getSessId())|\(uad.getPageId())|\(uad.getPageInstance())|\(uad.gettimestamp())|\(uad.getDuration())|\(uad.getEvType())|\(uad.getId())|-1|\(uad.getElemName())|\(uad.getElemType())|\(uad.getElemSubType())|\(uad.getXpos())|\(uad.getYpos())|\(uad.getWidth())|\(uad.getHeight())|\(val)|\(uad.getPreValue())|\(uad.getvalue1())|\(uad.getvalue2())|\(uad.getIframeid())||";
        }
        else {
            let data = uad.getValue();
            let val = String(uad.getValue().count)+"."+data;
            useractionRecord =                                                             "\(NvApplication.getSessId())|\(uad.getPageId())|\(uad.getPageInstance())|\(uad.gettimestamp())|\(uad.getDuration())|-7|\(uad.getId())|-1|\(uad.getElemName())|\(uad.getElemType())|\(uad.getElemSubType())|\(uad.getXpos())|\(uad.getYpos())|\(uad.getWidth())|\(uad.getHeight())|\(val)|\(uad.getPreValue())|\(uad.getvalue1())|\(uad.getvalue2())|\(uad.getIframeid())||";
        }
        
        
        return (useractionRecord, uad.getPageInstance());
    }
    
    private func processRequest(nvr : NvRequest){
        NSLog("[NetVision][NvBackGroundService] current timestamt is %lu", NvTimer.current_timestamp())
        switch(nvr.reqCode)
        {
        case .PAGEDUMP:
            NSLog("[NetVision][NvBackGroundService] processRequest called for pageDump");
            processPageDumpRequest(nvr: nvr);
            break;
        case .ACCOUNTLOGIN:
            NSLog("[NetVision][NvBackGroundService] processRequest called for accountLogin");
            processAccountLogin(nvr: nvr);
            break;
        case .CONFIGREQ:
            NSLog("[NetVision][NvBackGroundService] processRequest called for configReq");
            processConfigReq(nvr: nvr);
            break;
        case .SESSIONINFO:
            NSLog("[NetVision][NvBackGroundService] processRequest called for sessionInfo");
            processSessionInfoRequest(nvr: nvr);
            break;
        case .MONSTAT:
            NSLog("[NetVision][NvBackGroundService] processRequest called for pageDump monStat");
            processMonStatRequest(nvr: nvr);
            break;
        case .READYFORSERVER:
            NSLog("[NetVision][NvBackGroundService] processRequest called for readyforServer");
            SendToServer(nvr: nvr);
            break;
        default:
            NSLog("[NetVision][NvBackGroundService] processRequest called for defautl case");
            break;
        }
        
        return;
    }
    
    public func SendToServer(nvr: NvRequest) {
        let tq = ThreadQueue();
        let rfs = nvr as! ReadyForServer
        let nvc = rfs.getNvClient()
        if(nvc != nil) {
            tq.GlobalUtilityQueue.async() {
                var hrw : HttpResponseWrapper ;
                var status : Bool ;
                (hrw,status) = nvc!.doInBackground();
                if ( status == false) {
                    return ;
                }
                tq.GlobalMainQueue.async() {
                    rfs.callCallBack(service: self, hrw: hrw);
                    self.nvrq.pop();
                }
            }
        }
    }
    
    public func processMonStatRequest(nvr : NvRequest ) {
        let MonStatString = "\(HttpMonitorStat.request_count)%7C\(HttpMonitorStat.response_min)%7C\(HttpMonitorStat.response_max)%7C\(HttpMonitorStat.average_response_Time)%7C\(HttpMonitorStat.response_count)%7C\(HttpMonitorStat.error_count)%7C\(HttpMonitorStat.err_4xx)%7C\(HttpMonitorStat.err_5xx)%7C\(HttpMonitorStat.err_timeout)%7C\(HttpMonitorStat.err_conFail)%7C\(HttpMonitorStat.err_misc)" ;
        
        
        let nvcconfig = NvCapConfigManager.getInstance().getConfig();
        let pInst = NvApplication.getpageInstance();
        let url = "\(nvcconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(ReqData.messageversion)&op=monStats&pi=\(pInst)&d=MonStatString&lts=\(lts)";
        
        let userActioncallback =   NvHttpClientResponseCallback()
        
        let nvc =   NvHttpClient(service: self, lrequestType: "GET", lurl: NSURL(string: url)!, ldata: nil, callback: userActioncallback);

        let tq = ThreadQueue();

        tq.GlobalUtilityQueue.async() {
            var status : Bool ;
            (_,status) = nvc.doInBackground();
            if ( status == false) {
                return ;
            }
            tq.GlobalMainQueue.async() {
                self.deleteRequest(nvr: nil);
            }
        }
        return ;
    }
    
    func stringifyHTTPLogRequest(nvr : NvRequest) -> (String, Int, Int) {
        let httpData = nvr.reqData as! HttpLogRequest;
        let postStr = "\(httpData.encodedurl)|\((nvr.getTs()/1000) )|\( httpData.statuscode )|\(httpData.method)|\( httpData.bytetransferred )|\( httpData.responsetime )|\(httpData.jsonString)|||\(httpData.XCavNV)|{-1}\n";
        return (postStr,httpData.getPageInstance(),httpData.getPageId());
    }

    func flushHTTPLogRecord(force: Bool){
        if(NvApplication.getSessId().elementsEqual("000000000000000000000") || (!force && httpLogQueue.size() < 2)){
            return;
        }

        if(httpLogQueue.size() == 0) {return;}

        var iterator = httpLogQueue.NodeAtTop();

        var (HttpLogData, prevPageInstance, pgId) = stringifyHTTPLogRequest(nvr: (iterator?.val)!) ;

        while(httpLogQueue.size() > 0)
        {
            iterator = httpLogQueue.NodeAtTop();
            var (httpData, pageInst, pgId) = stringifyHTTPLogRequest(nvr: (iterator?.val)!);
            if(prevPageInstance == pageInst){
                HttpLogData += httpData;
            }
            else{
                break;
            }
            httpLogQueue.pop();
        }
        var postData : [UInt8];

        postData = Array(HttpLogData.utf8);

        let nvcconfig = NvCapConfigManager.getInstance().getConfig();
        
        print("logging locationid last : ",NvMetadata.GEO_LOCID)
        
        let url = "\(nvcconfig.getBeacon_url())?s=\(NvApplication.getSessId())&p=\(ReqData.protocolversion)&m=\(ReqData.messageversion)&op=xhrdata&pi=\(prevPageInstance)&pid=\(pgId)&d=\(NvApplication.getPageId())%7C\(NvCapConfig.getChannelId())%7C\(NvApplication.getBrowserId())%7C\(NvMetadata.GEOID)%7C\(NvMetadata.GEO_LOCID)%7C\(NvMetadata.ACCESSTYPE)%7C\(NvApplication.getStoreId())%7C\(NvApplication.getTerminalId())&d2=\(NvMetadata.CONNECTION_TYPE)%7C\(NvCapConfig.Platform)%7C\(NvApplication.getOSVersion())%7C\(NvMetadata.MODELID)%7C\(NvApplication.getMobileCarrierId())%7C\(NvMetadata.APPID)%7C\(NvMetadata.VERSIONID)&lts=\(lts)";
        
        var userActioncallback =   NvHttpClientResponseCallback()
        
        func handleResponse(serv : NvBackGroundService, hrw : HttpResponseWrapper) {
            
            var nvresp : NvResponse? = nil;
            
            nvresp = Mapper<NvResponse>().map(JSONString : hrw.getResponseString())
            if(nvresp == nil){
                return
            }
            let check = (responseCommonProcessing( hrw: hrw, nvr : nvresp! )) as NvResponse? ;
            let nr = nvresp;
            if (check != nil){
                processCallBack( nr: nr!);
                processQueue();
            }
            else {
                processQueue();
            }
        }
        
        let nvc =   NvHttpClient(service: self, lrequestType: "POST", lurl: NSURL(string: url)!, ldata: postData, callback: userActioncallback);
        
        let rfc = ReadyForServer();
        rfc.setNvClient(nvc: nvc);
        rfc.setCallBack(cB: handleResponse(serv:hrw:));
        rfc._setReqCode(reqCode: .READYFORSERVER);
//        if(NvApplication.getSessId().elementsEqual("000000000000000000000")) {
        self.addnvRequest(nvr: rfc);
//        }
//        else {
//            self.addRequestInFront(nvr: rfc);
//        }
//        let tq = ThreadQueue();
        
//        tq.GlobalUtilityQueue.async() {
//            var hrw : HttpResponseWrapper ;
//            var status : Bool ;
//            (hrw,status) = nvc.doInBackground();
//            if ( status == false) {
//                return ;
//            }
//            tq.GlobalMainQueue.async() {
//                handleResponse(serv: self, hrw: hrw);
//            }
//        }
        lastHLflushTime = NvTimer.current_timestamp();
    }

    func processHTTPLogRequest(nvr : NvRequest){
        httpLogQueue.push_bottom(ele: nvr);
        flushHTTPLogRecord(force: true);        
    }

    private func checkTimer(){
        if (timingDataQueue.isEmpty() && userActionQueue.isEmpty()){
            // both queues are empty and so stop timer if running
            if (timer != nil){
                timer?.stop_timer();
                timer = nil;
            }
        } else {
            // at least some queue has data to be flushed
            if (timer == nil){
                
                timer =   NvTimer();
            }
        }
    }

    class ServiceTimerTask : NvBackGroundService {
        func run()
        {
            let cts = NvTimer.current_timestamp();
            if ((cts - self.lastUQFlushTime) > 60000 && !userActionQueue.isEmpty()){
                // the last flush has happened more than 50 secs earlier
                flushUserActionRecord(forceFlag: true);
            }
            if ((cts - self.lastEQFlushTime) > 60000 && !eventQueue.isEmpty){
                // the last flush has happened more than 50 secs earlier
                flushEventRecord(forceFlag: true);
            }
            if ((cts - self.lastTDflushTime) > 60000 && !timingDataQueue.isEmpty()){
                // the last flush has happened more than 50 secs earlier
                flushTimingRecord(forceFlag: true);
            }
        }
    }
    
    public func flushAllQueues() {
        processQueue();
        // flush HwMonitor data too.
        let data = NvHWMonitor.shared()?.flushPerfData(UInt64(NvTimer.cav_epoch));
        if (data != nil) {
            // add one Useraction request.
            let nvr = NvRequest();
            nvr._setReqCode(reqCode: NvRequest.REQCODE.USERACTION);
            let uad = UserActionData();
            // now fill up uad for the touchevent
            uad._setSessionId(sessionId: NvApplication.getSessId());
            uad._setPageId(pageId: NvApplication.getPageId());
            let pInst = NvApplication.getpageInstance();
            uad._setPageInstance(pageInstance: pInst);
            uad._settimestamp(timestamp: NvTimer.current_timestamp());
            uad._setValue(value: data ?? "");
            uad._setEvType(evType: UAEVENTTYPE.UAEVENTTYPE.PERFDATA);
            nvr._setReqData(reqData: uad);
            NvCapture.getActivityMon().addRequest(nvr: nvr);
            // addnvRequest(nvr: nvr);
        }
        _ = NvTimer.current_timestamp();
        if (!userActionQueue.isEmpty()){
            // the last flush has happened more than 5 secs earlier
            flushUserActionRecord(forceFlag: true);
        }
        if (!eventQueue.isEmpty){
            // the last flush has happened more than 5 secs earlier
            flushEventRecord(forceFlag: true);
        }
        if (!timingDataQueue.isEmpty()){
            // the last flush has happened more than 5 secs earlier
            flushTimingRecord(forceFlag: true);
        }
        if(!httpLogQueue.isEmpty()){
            flushHTTPLogRecord(force: true);
        }
    }
    
    private func clearQueue() {
        objc_sync_enter(self)
        nvrq.clear();
        userActionQueue.clear();
        ActionTiming.clear();
        eventTiming.clear();
        userTiming.clear();
        httpLogQueue.clear();
        eventQueue = Array<NvRequest>();
        timingDataQueue.clear();
        objc_sync_exit(self);
    }
    
    private func processQueue(){
        let REQUEST_TIMEOUT = 20000; // 20 secs timeout
        var nvr : NvRequest? = nil;
        objc_sync_enter(self)
        if(nvrq.isEmpty()){
        }
        else {
            nvr = self.nvrq.ElementAtTop();
            if (nvr != nil){
                if ( nvr!.status == .PENDING){
                    nvr!.status = .SERVICING;
                    nvr!.ts = NvTimer.current_timestamp();
                }
                else if (nvr!.status == .SERVICING) {
                    
                    if ((NvTimer.current_timestamp() - nvr!.ts) > REQUEST_TIMEOUT){
                        
                        self.nvrq.pop() ;
                        nvr = self.nvrq.ElementAtTop();
                        if (nvr != nil){
                            nvr!.status = .SERVICING;
                            nvr!.ts = NvTimer.current_timestamp();
                        }
                    }
                    else {
                        nvr = nil;
                    }
                }
                else {
                    self.nvrq.pop();
                    nvr = (self.nvrq.ElementAtTop())!;
                    if (nvr != nil){
                        nvr!.status = .SERVICING;
                        nvr!.ts = NvTimer.current_timestamp();
                    }
                }

            }
        }

        objc_sync_exit(self)
        if(NvApplication.getSessId().elementsEqual("000000000000000000000") && nvr != nil && nvr!.reqCode != .CONFIGREQ && nvr!.reqCode != .ACCOUNTLOGIN  && nvr!.reqCode != .SESSIONINFO) {
            if(nvr!.status == .SERVICING){
                nvr!.status = .PENDING;
            }
            nvr = nil;
            return;
        }
        if (nvr != nil){
            
            processRequest(nvr: nvr!);
        }
        checkTimer();
        return;
    }
    
    private func postAccountLoginRequest(){
        let nvr : NvRequest =  NvRequest();
        let al =   AccountLogin();
        nvr._setReqCode(reqCode: NvRequest.REQCODE.ACCOUNTLOGIN);
        nvr._setReqData(reqData: al);
        
        al._setApiKey(apiKey: NvApplication.getApiKey());
        addRequestInFront(nvr: nvr);
        
    }
    
    private func checkClientNvServer(nvcm : NvCapConfigManager) -> Bool {
        NSLog("[NetVision NvBackGroundService] checkClientNvServer called");
        var proceed = false;
        if (!nvcm.getNvControl().isAccountAuthenticated()){
            // system has not authenticated with server or Nvserver is unknown, get one allocated based on apiKey
            postAccountLoginRequest();
        }
        else {
            proceed = true;
        }
        return proceed;
        
    }
    
    private func loadConfigFromServer(nvcm : NvCapConfigManager ){
        NSLog("[NetVision NvBackGroundService] loadConfigFromServer called");
        
        if (checkClientNvServer(nvcm: nvcm)){
            let configCheckSum = nvcm.getConfigCheckSum();
            let nvr : NvRequest =   NvRequest();
            let cr =   ConfigRequest();
            nvr._setReqCode(reqCode: NvRequest.REQCODE.CONFIGREQ);
            nvr._setReqData(reqData: cr);
            
            cr._setAuthKey(String: NvApplication.getAuthKey());
            cr._setMd5checksum(md5checksum: configCheckSum);
            addRequestInFront(nvr: nvr);
        }
    }
    
    private func processAuthResponse(hrw : HttpResponseWrapper ){
        let status = hrw.getCode();
        
        // FIXME: what if request fail ??
        // In this case either capturing should be disabled.
        if(status == -1){
            return;
        }
        if(hrw.getResponseString() == ""){
            return;
        }
        var authResp : AuthResponse? = nil;
        if (status == NvHttpClient.CODE_200_OK){
            
            authResp = Mapper<AuthResponse>().map(JSONString: hrw.getResponseString())
            
            if(authResp == nil) {
                //NSLog("[NetVision] Error parsing Json of AuthResponse ");
            }
        }
        let nvcm = NvCapConfigManager.getInstance();
        let rumPausedStopped :Bool = nvcm.getNvControl().isRumPausedStopped()
       
        if (authResp != nil && authResp!.getCode() == NvResponse.NvResponseCode.SUCCESS ){
            // successful auth response received
//            let nvcm = NvCapConfigManager.getInstance();
            
            let newUrl = NvBackGroundService.buildNewUrl(urlString: NvCapConfig.CAV_RUM_SERVICE_AUTH_URL, authResponse: authResp!.getConfig_url())
            
            nvcm.getConfig()._setConfig_url(config_url: newUrl);
            if !rumPausedStopped {
                nvcm.getNvControl()._setRumEnabled(rumEnabled: true);
            }
            
            nvcm.getNvControl()._setAccountAuthenticated(accountAuthenticated: true);
            loadConfigFromServer(nvcm: nvcm);
            
        } else {
            
            let nvcm = NvCapConfigManager.getInstance();
            nvcm.getNvControl()._setRumEnabled(rumEnabled: false);
            nvcm.getNvControl()._setAccountAuthenticated(accountAuthenticated: false);
            
        }
    }
    
    private static func buildNewUrl(urlString: String, authResponse: String) -> String {
            if authResponse.hasPrefix("http") {
                return authResponse
            }
            
            do {
                guard let url = URL(string: urlString) else {
                    throw URLError(.badURL)
                }
                
                var newUrl = "\(url.scheme ?? "http")://\(url.host ?? "")"
                if let port = url.port, port != 443 {
                    newUrl.append(":\(port)")
                }
                
                newUrl.append(authResponse)
                return newUrl
            } catch {
                print("Error occurred while building new URL: \(error)")
                return "Invalid URL"
            }
        }
    
    private func responseCommonProcessing( hrw : HttpResponseWrapper , nvr : NvResponse ) -> NvResponse? {
        if (hrw.getCode() != NvHttpClient.CODE_200_OK) {return nil;} // HTTP status code has to be 200 from server
        
        switch(nvr.getCode()){
        case .SUCCESS:
            
            break;
        case .UNAUTHENTICATED_REQUEST:
            
            postAccountLoginRequest();
            return nil
            
        }
        return nvr;
        
    }
    
    func processPagedumpResponse(npdr : PagedumpResponse) {
        var curEtag = npdr.getETAG();
        let prevEtag : String?
        // First check if current md5 is valid or not.
        if (npdr.getETAG() == nil ) {
            return;
        }
        // get md5 stored on Server.
        
        let preferences = UserDefaults.standard
        
        let currentLevelKey = "NetVisionEtag";
        if preferences.object(forKey: currentLevelKey) == nil {
            prevEtag = nil ;
        }
        else {
            prevEtag = preferences.string(forKey: currentLevelKey)
        }
        
        curEtag = "\"\(curEtag! )\""
        // compare both the md5 checksum.
        
        if (prevEtag == nil || !(curEtag == prevEtag) ) {
            // reload configuration from network.
            
        }
        let Sessid = npdr.getSID();
        let Sessionid = Sessid;
        let csessId  = NvApplication.getSessId();
        if (csessId != Sessionid){
            clearQueue();
            NvApplication._setSessId(sessIdentifier: Sessionid);
            NvApplication._setpageInstance(pageIns: 1);
            NvApplication._setSnapShotInstance(snapShotInst: 0);
            if(wvh != nil){
                wvh!.syncWebView(data: ["sid","pi","snapshotInstance"]);
            }
            let sessInfo = NvSessionInfo(serv: self);
            sessInfo._sendSessionInfo();
        }
        let bi = Int64(lts);
        lts = bi;
    }
    
    func _setWebViewHandler(wvh:NvWebViewHandler){
        self.wvh = wvh;
    }
    
    func jsonParser(jsonString: String) {
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        if let update = jsonObject["update"] as? [String: Any],
                           let app = update["app"] as? [String: [String: Any]],
                           let appID = app.keys.first,
                           let appInfo = app[appID],
                           let appVersions = appInfo["versions"] as? [String: String],
                           let appVersionID = appVersions.keys.first,
                           let device = update["device"] as? [String: [String: Any]],
                           let deviceID = device.keys.first {
                            NvMetadata.APPID = appID
                            NvMetadata.VERSIONID = appVersionID
                            NvMetadata.MODELID = deviceID
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }

}
