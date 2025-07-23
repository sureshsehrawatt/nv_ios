//
//  NvHttpClient.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit
import MobileCoreServices
import Foundation


public class NvHttpClient : NSObject {
    
    enum HTTPError: Error {
        
        case NoUrl
    }
    
    static let CODE_200_OK = 200; // for time being as data shows error. Remove once byte dependency is established
    var url: NSURL? = nil;
    var postFlag: Bool? = nil ;
    var data : [UInt8]? = nil; // data an array of bytes type
    var httpClient :  URLSessionUploadTask = URLSessionUploadTask() ;
    var request : NSMutableURLRequest? = NSMutableURLRequest() ;
    var response : HTTPURLResponse? = nil;
    var responseData : NSData? = nil;
    private var postcallback: NvHttpClientResponseCallback = NvHttpClientResponseCallback() ;
    private var runningStat : Bool = false;
    private var service : NvBackGroundService;
    init( service: NvBackGroundService, lrequestType: String, lurl: NSURL , ldata: [UInt8]? , callback: NvHttpClientResponseCallback! ) {
        // TODO Auto-generated constructor stub
        url = lurl;
        request = NSMutableURLRequest(url : url! as URL);
        request!.httpMethod = lrequestType ;
        request!.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        self.service = service;
        postFlag = (lrequestType == "POST" ) ?true:false;
        data = ldata;
        if(data != nil){
        }
        else {
        }
        if callback != nil {
            postcallback = callback;
        }
        
    }
    //create method to reset the parameters so it can be reused.
    func reset(lrequestType: String?, lurl: NSURL?, ldata :[UInt8]? ,callback:NvHttpClientResponseCallback?)->Bool
    {
        if runningStat == true {
            print("[NetVision] HttpClient is in running State, Can not reset.\n");
            return false;
        }
        url = lurl;
        postFlag = (lrequestType == "POST") ? true : false ; //find
        data = ldata;
        if callback != nil {
            postcallback = callback!;
            return true;
        }
        return false
    }
    
    var a : HttpResponseWrapper?;
    
    func doInBackground() ->  ( HttpResponseWrapper ,  Bool ) {//look at this
        
        let hrw : HttpResponseWrapper = HttpResponseWrapper() ;
        let tq = ThreadQueue();
        self.runningStat = true;
        //create the request
        var sem = DispatchSemaphore.init(value: 0);
        var task : URLSessionDataTask? = nil ;
        if self.request!.httpMethod == "POST" {
            let d : NSData = NSData(bytes: self.data!, length: self.data!.count);
            task = URLSession.shared.uploadTask(with: self.request! as URLRequest, from: d as Data, completionHandler: { data , response , err in
                if(err != nil){
                    
                }
                else {
                    self.response = response as? HTTPURLResponse;
                    self.responseData = (data as NSData?);
                }
                defer { sem.signal() }
            })
        }
        else {
            task = URLSession.shared.dataTask(with: self.request! as URLRequest, completionHandler: { data , response , err in
                if(err != nil){
                    
                }
                else {
                    self.response = response as? HTTPURLResponse;
                    
                    self.responseData = (data! as NSData);
                    
                }
                defer { sem.signal() }

            })
        }
        
        task!.resume();
        
        sem.wait();
        var response_code : Int = 0;
        if( response != nil ) {
            response_code = response?.statusCode ?? -1 ;
        }
        hrw._setCode(code: response_code);
        let resp = response ?? nil ;
        if(resp == nil){
            NSLog("[NetVision][NvHttpClient][URL] async: gotchya");
        }
        hrw._setHres(hres: response);
        var content : String = ""
        if(self.responseData != nil){
            content = String(data: self.responseData! as Data, encoding: String.Encoding.utf8)!
        }
        hrw._setResponseString(responseString: content);
        
        print("[NetVision][NvHttpClient][URL]  \(url?.absoluteString)")
        NSLog("[NetVision][NvHttpClient][URL] response string set for above url is %@", content );
        
        if hrw.getHres() == nil {
            return ( hrw , false );
        }
        return ( hrw , true );
        
    }
    
    //self method will just reset.
    func onCancelled(hrw: HttpResponseWrapper){
        runningStat = false;
        print("[NetVision] async: Http Request Cancelled");
        reset(lrequestType: "GET", lurl: nil, ldata: nil, callback: nil);
    }
    
    static func getData( resp : HTTPURLResponse ) throws -> NSData {
        
        guard let url = resp.url else { throw HTTPError.NoUrl }
        let d = try NSData(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
        
        return d
    }
    
    public static func getHttpResponse(response: HTTPURLResponse) -> String { // 'is' is a keyword hence Is used
        var ret : String;
        do {
            let d = try getData(resp: response);
            ret = String ( data: d as Data, encoding: String.Encoding.utf8)!
            return ret;
        }
        catch {
            print("[NetVision]  HTTPError.NoUrl\n");
        }
        return ""
    }
    
//    private func extractSessionId(response : HTTPURLResponse ){
//        let CAV_NV = "CAV_NV";
//        let hdrs = response.allHeaderFields;
//        var sessId : String? = nil;
//        for hdr in hdrs {
//            var name: String;
//            name = (hdr as! String).uppercased()
//            var arr = [String]();
//            arr = name.components(separatedBy: "=");
//            var origvalue: String;
//            var origname: String;
//            origname = arr[0];
//            origvalue = arr[1];
//            if origname == CAV_NV {
//
//                // we have got session cookie
//                sessId = origvalue ;
//                break;
//            }
//
//        }
//        if sessId != nil {
//            //TODO: put a check if service is not nil.
//            // save extracted Session id in NvAapplication
//
//            var csessId: String;
//            csessId = NvApplication.getSessId();
//            if ( csessId != sessId ){
//                // the sessionid has changed,
//                NvApplication._setSessId(sessIdentifier: sessId!);
//                NvApplication._setpageInstance(pageIns: 0);
//                NvApplication._setSnapShotInstance(snapShotInst: 0);
//                // sessionId has changed and so new SessionInfo needs to be sent for self session
//                let sessInfo = NvSessionInfo(serv: service);
//                sessInfo._sendSessionInfo();
//            }
//        }
//
//    }
    
}
