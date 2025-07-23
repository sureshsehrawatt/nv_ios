import UIKit
public class NvCap:NSObject{
    
    private static var nvapiControl : NvAPIControl? = nil ;
    private static var nvapiRum : NvAPIRum? = nil ;
    private static var nvapiApm : NvAPIApm? = nil    ;
    private static var intialized = false;
    
    // Control APIs
    
    @objc(startWithAct:apiKey:)
    public static func start( act :UIViewController, apiKey : String){
        NSLog("[NetVision NvCap] start called");
        
        let fld = NvFlushCrashData()
        fld.flushData()
        
        if (!intialized){
            intialized = true;
            nvapiControl = NvAPIControl();
            nvapiRum =   NvAPIRum();
            nvapiApm =   NvAPIApm();
            nvapiControl!.start(act: act, apiKey: apiKey);
            
            print("Location Data in NvCap")
            let ld = LocationData()
            let ld2 = LocationData()
    
        }
    }
    
    @objc(stop)
    public static func stop(){
        intialized = false;
        nvapiControl!.stop();
        nvapiRum = nil;
        nvapiControl = nil;
        nvapiApm = nil;
    }
    //MARK:- @objc added before method to call method from objc class - BugID - 106515 - 26/07/21
    @objc(pause)
    public static func pause(){
        if (intialized){
            nvapiControl!.pause();
        }
    }
    //MARK:- @objc added before method to call method from objc class - BugID - 106515 - 26/07/21
    @objc(resume)
    public static func resume(){
        if (intialized){
            nvapiControl!.resume();
        }
    }
    
    //order total
    @objc(setOrderTotalWithvalue:)
    public static func setOrderTotal (value : String){
        if(value.count > 0){
            let detail:[String : String] = ["OrderTotal": value];
            addNvEvent(evName: "OrderTotal", prop: detail);
        }
    }
    
    @objc(setOrderTotalWithvalue:count:)
    public static func setOrderTotal (value : String, count : Float){
        if(value.count > 0){
            let detail:[String : String] = ["OrderTotal": value+"|\(count)"];
            addNvEvent(evName: "OrderTotal", prop: detail);
        }
    }
    
    // loginId
    @objc(setLoginIdWithId:)
    public static func setLoginId(id: String){
        // mask domain name.
        var st: String = id;
        let firstIndex = id.firstIndex(of: "@");
        if firstIndex != nil {
          st = String(id[..<(firstIndex ?? id.endIndex)]) + "*******";
        }
          
        // encode login id.
        // s.length + "." + Base64.encode(CAVNV.utils.reverse(s));
        st = String(st.reversed())

        
        let utf8str = st.data(using: .utf8)
        if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
            
            let encodedId: String = (String(st.count) + "." + base64Encoded);
            
            NSLog("Encoded Login ID - %@", encodedId);
            let detail:[String : String] = ["LoginID": encodedId];
            addNvEvent(evName: "LoginID", prop: detail);
        }
    }
    
    // RUM APIs
    
    public static func addNvEvent (evName : String){
        addNvEvent(evName: evName , prop: nil);
    }
    @objc(addNVEventWithevName:prop:)
    public static func addNvEvent( evName : String , prop : [String : String]? ){
        if (intialized && nvapiControl!.isRumEnabled()){
            print("data will be added to request queue");
            nvapiRum!.addNvEvent(evName: evName, prop: prop);
        }
    }

    public static func setStoreInfo(storeId : Int, associateId : String, terminalId : Int)
    {
        NvApplication._setStoreId(id: storeId);
        NvApplication._setAssociateId(id: associateId)//setAssociateId(associateId);
        NvApplication._setTerminalId(id: terminalId);
        //HashMap<String, Object> detail = new HashMap();
        //detail.put("StoreInfo", storeId + "|" + terminalId + "|" + associateId);
        var details:[String : String] = ["StoreInfo":"\(storeId)|\(terminalId)|\(associateId)"];
        addNvEvent(evName:"StoreInfo", prop:details);
    }
    
    @objc(markSensitiveWithViewId:)
    public static func markSensitive(viewId : Int){
        if (intialized && nvapiControl!.isRumEnabled()){
            nvapiRum!.markSensitive(viewId: viewId);
        }
    }
    
    @objc(unmarkSensitiveWithViewId:)
    public static func unmarkSensitive(viewId : Int){
        if  intialized == true && nvapiControl!.isRumEnabled() {
            nvapiRum!.unmarkSensitive(viewId: viewId);
            
        }
    }
    /**
     *
     * @param view: view on which user action has happened
     * @param actionName: Name of the action
     * @param actionData: string data json encoded for the action
     */
    public static func addUserAction(act : UIViewController, view : UIView, actionName : String , actionData : String ){
        if (intialized && nvapiControl!.isRumEnabled()){
//            print("at.. addUserAction")
            nvapiRum!.addUserAction(act: act, view: view, actionName: actionName, actionData: actionData);
        }
    }
    
}
