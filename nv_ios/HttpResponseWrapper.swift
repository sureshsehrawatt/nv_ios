//
//  HTTPURLResponseWrapper.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

//AG MARK//

import UIKit
import Foundation

public class HttpResponseWrapper: NSObject {
    
    var hres : HTTPURLResponse? ;
    var code : Int;
    var responseString : String ;
    override init(){
        code = 0;
        responseString = "";
    }
    func getHres() -> HTTPURLResponse? {
        return hres ;
    }
    func _setHres(hres: HTTPURLResponse?) {
        self.hres = hres;
    }
    func getCode() -> Int {
        return code;
    }
    func _setCode(code: Int) {
        self.code = code;
    }
    func getResponseString() -> String {
        return responseString;
    }
    func _setResponseString(responseString: String) {
        self.responseString = responseString;
    }
}
