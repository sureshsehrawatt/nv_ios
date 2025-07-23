//
//  Timer.swift
//  NetVision
//
//  Created by compass-362 on 29/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation
import UIKit

public class NvTimer:NSObject{
    private var interval,start, end : Int64;
    public static let cav_epoch : Int64 = 1388534400;
    private var stop : Bool = false;
    override init(){
        interval = 0;
        start = 0;
        end = 0;
        
    }
    @objc(current_timestamp)
    public static func current_timestamp() -> Int64{
        var curr : Double =  NSDate().timeIntervalSince1970  ;
        curr = curr * 1000;
        return ( Int64 ( curr ) - (cav_epoch * 1000));
    }
    
     public func start_timer(){
        if(stop == false){
            print("[NetVision] Already running...Error\n");
            return;
        }
        start = Int64 ( NSTimeIntervalSince1970 * 1000 ) ;
        stop = false ;
    }
    
     public func stop_timer() -> Int64{
        if(stop){
            print("[NetVision] Already paused/stopped...Error\n");
            return interval;
        }
        end =  Int64 ( NSTimeIntervalSince1970 * 1000 ) ;
        interval += end - start;
        stop = true;
        return interval;
    }
    
     public func pause(){
        if(stop){
            print("[NetVision] Already paused/stopped...Error\n");
            return;
        }
        end = Int64 ( NSTimeIntervalSince1970 * 1000 ) ;
        interval = end - start;
        stop = true
    }
    
     public func reading() -> Int64 {
        return interval;
    }
    
}
