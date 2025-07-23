//
//  NvPermisson.swift
//  Hackcancer
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

import Foundation
import UIKit

class NvPermission: NSObject {
    static var didGetSessionInfo : Bool = false;
    static func GotNvPermission(){
        didGetSessionInfo = true;
    }
    static func resetPermission(){
        didGetSessionInfo = false;
    }
}
