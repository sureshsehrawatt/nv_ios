//
//  NvRequest.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit


public class NvRequest: NSObject  {
    
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    override init() {
        ts = NvTimer.current_timestamp();
    }
    
    func getStatus() -> Status {
        return status;
    }
    
    func _setStatus(status : Status) {
        self.status = status
    }
    
    func getTs() -> Int64 {
        return ts;
    }
    
    func _setTs(ts : Int64) {
        self.ts = ts;
    }
    
    func getReqCode() ->  REQCODE {
        return reqCode;
    }
    
    func _setReqCode(reqCode: REQCODE) {
        self.reqCode = reqCode;
    }
    
    func getReqData() -> ReqData {
        return reqData;
    }
    
    func _setReqData(reqData : ReqData ) {
        self.reqData = reqData;
    }
    
    var status : Status = .PENDING	;	// to be used in service queue to keep status
    var ts : Int64 = 0;		// To be used by service queue to keep start time of request for timeout
    var reqCode: REQCODE = .NONE ;
    var	reqData: ReqData = ReqData() ;
    
    enum Status {
        case PENDING
        case SERVICING
        case DONE
    }
    
    
    enum REQCODE : Int { //was (1)
        case PAGEDUMP = 1
        case USERACTION = 2
        case ACCOUNTLOGIN = 3
        case CONFIGREQ = 4
        case APIEVENT = 5
        case APIACTION = 6
        case SESSIONINFO = 7
        case HTTPLOG = 8
        case MONSTAT = 9
        case NONE = 10
        case READYFORSERVER = 11
    }
    private var numVal : Int = 0;
    
    init(numVal:Int) {
        self.numVal = numVal;
    }
    
    public func getNumVal() -> Int {
        return numVal;
    }
}


public class ReqData : NSObject, Mappable { // problem 14
    static var protocolversion = 200 ;
    static var messageversion = 0
    var sessionId : String;
    var	pageId :Int;
    var pageInstance :Int;
    var snapShotInstance :Int;
    var timestamp : Int64;
    var Misc = "";
    
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        //ReqData.protocolversion <- map["protocolversion"]
        //ReqData.messageversion <- map["messageversion"]
        sessionId <- map["sessionId"]
        pageId <- map["pageId"]
        pageInstance <- map["pageInstance"]
        snapShotInstance <- map["snapShotInstance"]
        timestamp <- map["timestamp"]
        Misc <- map["MiscData"]
    }
    
    public override init(){
        sessionId = NvApplication.getSessId();
//        sessionId = formatSID(sid: 0)
        pageId = NvApplication.getPageId()
        pageInstance = NvApplication.getpageInstance()
        snapShotInstance = NvApplication.getSnapShotInstance()
        timestamp = NvTimer.current_timestamp()/1000
    }
    public func getMisc() -> String {
        return Misc;
    }
    public func _Misc( misc : String) {
        Misc = misc;
    }
    
    
    public func getSessionId() -> String {return sessionId;}
    public func _setSessionId( sessionId :String) {self.sessionId = sessionId;}
    public func getPageId() -> Int {return pageId;}
    public func _setPageId(pageId : Int) {
        self.pageId = pageId;
    }
    public func getPageInstance() -> Int {
        return pageInstance;
    }
    
    public func _setPageInstance(pageInstance: Int) {
        self.pageInstance = pageInstance;
    }
    
    public func gettimestamp() -> Int64 {
        return timestamp;
    }
    
    public func _settimestamp( timestamp : Int64) {
        self.timestamp = timestamp;
    }
    
    public func getSnapShotInstance() -> Int {
        return snapShotInstance;
    }
    
    public func _setSnapShotInstance(snapShotInstance : Int) {
        self.snapShotInstance = snapShotInstance;
    }
}


public class AccountLogin : ReqData { // problem 26
    var apiKey: String = "";
    
    public override func mapping(map: Map) {
        super.mapping(map: map)
        apiKey <- map["apiKey"]
    }
    
    public func getApiKey() -> String {
        return apiKey;
    }
    public func _setApiKey( apiKey : String ) {
        self.apiKey = apiKey;
    }
    override init(){}
    
}


public class SessionInfo : ReqData { // problem 26
    var linfo = LocationInfo() ;
    var dinfo : DeviceInfo? ;
    
    override init(){}
    
    public override func mapping(map: Map) {
        ReqData.protocolversion <- map["protocolversion"]
        ReqData.messageversion <- map["messageversion"]
        sessionId <- map["sessionId"]
        pageId <- map["pageId"]
        pageInstance <- map["pageInstance"]
        snapShotInstance <- map["snapShotInstance"]
        timestamp <- map["timestamp"]
        var inf : String = "";
        inf <- map["linfo"]
        linfo = Mapper<LocationInfo>().map(JSONString: inf)!;
        inf <- map["dinfo"]
        dinfo = Mapper<DeviceInfo>().map(JSONString: inf);
    }
    
    func getLinfo() -> LocationInfo? { //uses internal type
        
        return linfo;
    }
    func _setLinfo(linfo: LocationInfo? ) {
        self.linfo = linfo!
    }
    func getDinfo() -> DeviceInfo? {
        return dinfo;
    }
    func _setDinfo(dinfo : DeviceInfo? ) {
        self.dinfo = dinfo;
    }
    /*		public String getDevInfo() {
    return devInfo;
    }
    public func_setDevInfo(String devInfo) {
    self.devInfo = devInfo;
    }
    */
}
public class LocationInfo : Mappable { //problem 26
    var latitude : Double = -1;		// latitude
    var longitude : Double = -1;	// longitude
    var city: String = "";
    var state: String = "";		// admin area, typically, state from Geocoder
    var countryCode : String = "";	// country code
    //				String devInfo;		// device information in | seperated string format
    init(){}
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    public func getLatitude() -> Double {
        return latitude;
    }
    public func _setLatitude(latitude: Double) {
        self.latitude = latitude;
    }
    public func getLongitude() -> Double {
        return longitude;
    }
    public func _setLongitude(longitude: Double) {
        self.longitude = longitude;
    }
    public func getCity() -> String {
        return city;
    }
    public func _setCity(city: String) {
        self.city = city;
    }
    public func getState()-> String {
        return state;
    }
    public func _setState(state: String ) {
        self.state = state;
    }
    public func getCountryCode() ->String {
        return countryCode;
    }
    public func _setCountryCode(country : String) {
        self.countryCode = country;
    }
    public func mapping(map: Map) {
        latitude <- map["latitude"]		// latitude
        longitude <- map["longitude"]	// longitude
        city <- map["city"]
        state <- map["state"]		// admin area, typically, state from Geocoder
        countryCode <- map["countryCode"]
    }
}
public class DeviceInfo : Mappable { //problem 26
    var API = 0;                // static
    var Device = "abc";
    var Product = "";
    var Release = "";
    var Brand = "Apple";
    var DISPLAY = "";
    var Manufacturer = "Apple";
    var ScreenWidth = 0;
    var ScreenHeight = 0;
    var versioncode = 0.00;
    var versionname = ""; // end static
    init(){
        //Device =  "";
        Device = UIDevice.current.model;
    }
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    public func mapping(map: Map) {
        API <- map["API"]                // static
        Device <- map["Device"]
        Product <- map["Product"]
        Release <- map["Release"]
        Brand <- map["Brand"]
        DISPLAY <- map["DISPLAY"]
        Manufacturer <- map["Manufacturer"]
        ScreenWidth <- map["ScreenWidth"]
        ScreenHeight <- map["ScreenHeight"]
        versioncode <- map["versioncode"]
        versionname <- map["versionname"]
    }
    
    public func getAPI() -> Int {
        return API;
    }
    public func _setAPI( aPI : Int) {
        API = aPI;
    }
    public func getDevice() -> String {
        return Device;
    }
    public func _setDevice( device : String  ) {
        Device = device;
    }
    public func getProduct() -> String {
        return Product;
    }
    public func _setProduct( product : String  ) {
        Product = product;
    }
    public func getRelease() -> String {
        return Release;
    }
    public func _setRelease( release : String  ) {
        Release = release;
    }
    public func getBrand() -> String {
        return Brand;
    }
    public func _setBrand( brand : String  ) {
        Brand = brand;
    }
    public func getDISPLAY() -> String {
        return DISPLAY;
    }
    public func _setDISPLAY(dISPLAY : String  ) {
        DISPLAY = dISPLAY;
    }
    public func getManufacturer() -> String {
        return Manufacturer;
    }
    public func _setManufacturer(String manufacturer  : String  ) {
        Manufacturer = manufacturer;
    }
    public func getScreenWidth() ->Int {
        return ScreenWidth;
    }
    public func _setScreenWidth( screenWidth: Int) {
        ScreenWidth = screenWidth;
    }
    public func getScreenHeight() -> Int {
        return ScreenHeight;
    }
    public func _setScreenHeight( screenHeight : Int ) {
        ScreenHeight = screenHeight;
    }
    public func getVersioncode() -> Double {
        return versioncode;
    }
    public func _setVersioncode(versioncode: Double) {
        self.versioncode = versioncode;
    }
    public func getVersionname() -> String {
        return versionname;
    }
    public func _setVersionname(String versionname : String  ) {
        self.versionname = versionname;
    }
    
}


public class HttpLogRequest : ReqData {
    public static var messageVersion = 0;
    var encodedurl : String = "";
    var statuscode : Int = 0;
    var method : String = "";
    public var XCavNV : String = "";
    public var CorrelationID : String = "";
    public var bytetransferred : Int = 0;
    var responsetime : Int64 = 0;
    var ff1 : Int = 0;
    var exceptioncount : Int = 0;
    var flowpathinstance : Int = 0;
    var jsonString : String = "";
    override init(){
        super.init();
    }
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    public override func mapping(map: Map) {
        super.mapping(map: map);
        //url <- map["url"]
    }
}


public class ConfigRequest : ReqData {
    var authKey : String = "" ;
    var md5checksum : String? = nil ;
    
    public func getMd5checksum() -> String? {
        return md5checksum
    }
    public func _setMd5checksum( md5checksum : String?  ) {
        self.md5checksum = md5checksum ;
    }
    public func getAuthKey() -> String {
        return authKey;
    }
    public func _setAuthKey(String authKey : String  ) {
        self.authKey = authKey;
    }
    override init(){}
    public override func mapping(map: Map) {
        super.mapping(map: map)
        authKey <- map["authKey"]
        md5checksum <- map["md5checksum"]
    }
}


public class EventRequest : ReqData {
    
    var evName : String = "" ;
    var prop : [String : String]? = nil;
    //Map<String, Object> prop;
    
    override init(){}
    public override func mapping(map: Map) {
        super.mapping(map: map)
        evName <- map["evName"];
        prop <- map["prop"]
    }
    public func getEvName() -> String {
        return evName;
    }
    public func _setEvName(String evName : String  ) {
        self.evName = evName;
    }
    public func getProp() -> [String : String]? { // problem 7
        return prop ;
    }
    public func _setProp(prop : [String : String]?) { // problem 7
        self.prop = prop;
    }
}


public class PageDumpData : ReqData {
    public override func mapping(map: Map) {
        super.mapping(map: map)
        bmap <- map["bmap"]
        screenName <- map["screenName"]
        captureFlag <- map["captureFlag"]
    }
    public static let CAPTURE_FLAG_NO_DUMP   	= 0;
    public static let CAPTURE_FLAG_PAGEDUMP  	= 1;
    public static let CAPTURE_FLAG_COMPRESSED_DUMP = 2;
    override init(){
        
    }
    //url format: /<beacon_url>?s=<sid>&op=pagedump&pi=<page instance>&d=<page id>|<cpf-flag>
    var bmap : UIImage? = nil  ;	// the compression etc needs to be done in service before sending to server rather than in the UI thread // problem 27
    var screenName : String = "" ;
    var captureFlag: Int = 1;	//
    
    public func getBmap() -> UIImage? { // problem 27
        return bmap;
    }
    public func _setBmap(bmap : UIImage? ) { // problem 27
        self.bmap = bmap;
    }
    public func getCaptureFlag() -> Int {
        return captureFlag;
    }
    public func _setCaptureFlag( captureFlag : Int ) {
        self.captureFlag = captureFlag;
    }
    public func getScreenName() -> String {
        return screenName;
    }
    public func _setScreenName( screenName : String  ) {
        self.screenName = screenName;
    }
    
}
class UAEVENTTYPE{
    enum UAEVENTTYPE : Int {
        case FOCUS=0, BLUR=1, TOUCHEND=2, CHANGE=3,
        HASHCHANGE=4,   // not being used
        MOUSEOVER=5,    // not being used, not relevant from mobile perspective
        PAN=1002,	// TBD - whether gesture to expand can be mapped to it
        ROTATE=1003,	// TBD - whether we should capture self and lead to another screenshot after scroll over
        ORIENTATIONCHANGE=1004, // self should be captured and a new screenshot taken when self event occurs
        CLICK=1005,	// self is then event that will be sent when touch ends
        TOUCHSTART=1006, // self is the event that will be sent when touch starts
        APIUA=1007,       // self is used when mobile sdk api is used to log a UA
        DOUBLETAP=12,
        LONGPRESS=13,
        SWIPE=14,
        PERFDATA=107,
        PINCH=1011
    }
    
    var numVal: Int;
    
    init( numVal: Int) {
        self.numVal = numVal;
    }
    
    func getNumVal() -> Int {
        return numVal;
    }
    
}


public class UserActionData : ReqData {
    
    override init(){
        super.init()
    }
    public override func mapping(map: Map) {
        super.mapping(map: map)
        duration <- map["duration"]
        
        evType <- map["evType"]
        
        id <- map["id"]
        Iframeid <- map["Iframeid"]
        elemName <- map["elemName"]
        elemType <- map["elemType"]
        elemSubType <- map["elemSubType"]
        xpos <- map["xpos"]
        ypos <- map["ypos"]
        width <- map["width"]
        height <- map["height"]
        value <- map["value"]
        value1 <- map["value1"]
        value2 <- map["value2"]
        preValue <- map["preValue"]
        top <- map["top"]
        left <- map["left"]
    }
    var	duration: Int64 = 0 ;// To be used for input fields to know time taken to change a field
    
    var evType : UAEVENTTYPE.UAEVENTTYPE? = nil ;
    
    var id : Int = -1  ;        // String id of the clicked element // changed into int
    
    //var	idType : Int;  // -1 for string and -2 for xpath - not relevant for mobile
    var	elemName : String = "" ;  // name of the field - TBD what to be filled?
    var elemType : String = "" ;  // View type - button, edittext ...
    var elemSubType : String = "" ; // to be picked from inputType for a veiw
    var xpos : Int = -1;
    var ypos : Int = -1;
    var	width : Int = -1;
    var	height : Int = -1;
    var	value : String = "" ;
    var value1 : String = "" ;
    var value2 : String = "" ;
    var	preValue : String = "" ;
    var top : Int = -1;
    var	left : Int = -1;
    var Iframeid : String = "";
    
    public func getIframeid() -> String {
        return Iframeid;
    }
    public func _setIframeid(Iframeid: String) {
        self.Iframeid = Iframeid;
    }
    public func getTop() -> Int {
        return top;
    }
    public func _setTop(top: Int) {
        self.top = top;
    }
    public func getLeft() -> Int{
        return left;
    }
    public func _setLeft(left : Int) {
        self.left = left;
    }
    public func getDuration() -> Int64 {
        return duration;
    }
    public func _setDuration(duration : Int64) {
        self.duration = duration;
    }
    func getEvType()  -> Int { //public
        return (evType?.rawValue)! ;
    }
    func _setEvType(evType: UAEVENTTYPE.UAEVENTTYPE? ) { //public
        self.evType = evType;
    }
    public func getId() -> Int {
        return id;
    }
    public func _setId ( id : Int  ) {
        self.id = id;
    }
    /*
    public func getIdType() -> Int {
    return idType;
    }
    public func _setIdType(idType :Int) {
    self.idType = idType;
    }
    */
    public func getElemName() -> String {
        return elemName;
    }
    public func _setElemName(elemName : String  ) {
        self.elemName = elemName;
    }
    public func getElemType() -> String {
        return elemType;
    }
    public func _setElemType(elemType : String  ) {
        self.elemType = elemType;
    }
    public func getElemSubType() -> String {
        return elemSubType;
    }
    public func _setElemSubType( elemSubType  : String  ) {
        self.elemSubType = elemSubType;
    }
    public func getXpos() -> Int {
        return xpos;
    }
    public func _setXpos(xpos: Int) {
        self.xpos = xpos;
    }
    public func getYpos()-> Int {
        return ypos;
    }
    public func _setYpos( ypos : Int) {
        self.ypos = ypos;
    }
    public func getWidth() -> Int {
        return width;
    }
    public func _setWidth(width: Int)  {
        self.width = width;
    }
    public func getHeight() -> Int {
        return height;
    }
    public func _setHeight(height : Int) {
        self.height = height;
    }
    public func getValue() -> String {
        return value;
    }
    public func _setValue( value : String  ) {
        self.value = value;
    }
    public func getvalue1() -> String {
        return value1;
    }
    public func _setvalue1(value1: String) {
        self.value1 = value1;
    }
    public func getvalue2() -> String {
        return value2;
    }
    public func _setvalue2(value2: String) {
        self.value2 = value2;
    }
    public func getPreValue() -> String {
        return preValue;
    }
    public func _setPreValue(preValue : String  ) {
        self.preValue = preValue;
    }
    
}


public class ReadyForServer : NvRequest{
    var nvClient: NvHttpClient? = nil;
    var callBack: ((_ serv : NvBackGroundService, _ hrw : HttpResponseWrapper) -> ())? = nil;
    
    func setNvClient(nvc : NvHttpClient) {
        nvClient = nvc;
    }
    func getNvClient() -> NvHttpClient? {
        return nvClient;
    }
    
    func setCallBack(cB: @escaping ((_ serv : NvBackGroundService, _ hrw : HttpResponseWrapper) -> ())) {
        callBack = cB;
    }
    
    func callCallBack(service: NvBackGroundService, hrw: HttpResponseWrapper) {
        if(callBack != nil){
            callBack!(service, hrw);
        }
    }
}
/**

public static class TimingData : ReqData {

//timing url format: http://www.nvserver.com/nv?s=<21digitsid>&op=timing&pi=<pageinstance>&d=<timing>

String 	actionName;
long	actionStartTimer.current_timestamp();
long	actionEndTimer.current_timestamp();
long	duration;
public String getActionName() {
return actionName;
}
public func_setActionName(String actionName) {
self.actionName = actionName;
}
public long getActionStartTimer.current_timestamp()() {
return actionStartTimer.current_timestamp();
}
public func_setActionStartTimer.current_timestamp()(long actionStartTimer.current_timestamp()) {
self.actionStartTimer.current_timestamp() = actionStartTimer.current_timestamp();
}
public long getActionEndTimer.current_timestamp()() {
return actionEndTimer.current_timestamp();
}
public func_setActionEndTimer.current_timestamp()(long actionEndTimer.current_timestamp()) {
self.actionEndTimer.current_timestamp() = actionEndTimer.current_timestamp();
}
public long getDuration() {
return duration;
}
public func_setDuration(long duration) {
self.duration = duration;
}

}
**/


