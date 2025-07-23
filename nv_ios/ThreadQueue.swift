//
//  BackgroundThread.swift
//  NetVision
//
//  Created by compass-362 on 02/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation
import UIKit

@objc public class ThreadQueue : NSObject {
   @objc public var GlobalMainQueue: DispatchQueue {
        return DispatchQueue.main
    }
    
   @objc public var GlobalUserInteractiveQueue: DispatchQueue {
    
    
    DispatchQueue.GlobalQueuePriority.default
    DispatchQueue.GlobalQueuePriority.low
    DispatchQueue.GlobalQueuePriority.background
    
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    }
    
    @objc public var GlobalUserInitiatedQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
    }
    
    @objc public var GlobalUtilityQueue: DispatchQueue {
    return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
    }
    
    @objc public var GlobalBackgroundQueue: DispatchQueue {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    }
}
