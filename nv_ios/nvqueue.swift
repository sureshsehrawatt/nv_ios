//
//  nvqueue.swift
//  NetVision
//
//  Created by compass-362 on 28/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation

public class nvqueue<T>: NSObject {
    var stack_front = [T]();
    var stack_back = [T]();
    private var topofstackfront : Int;
    private var topofstackback: Int;
    
    public override init(){
        topofstackback = -1;
        topofstackfront = -1;
    }
    
    public func enqueue(nvr : T!) {
        stack_back.append(nvr);
        topofstackback += 1;
    }
    public func enqueueinfront( nvr : T! ){
        stack_back.append(nvr);
        topofstackfront += 1;
    }
    public func dequeue() {
        
        if(topofstackfront == -1){
            if(topofstackback == -1){
                print("[NetVision] Stack is Empty. Nothing to pop");
                return ;
            }
            while(topofstackback >= 0){
                topofstackfront += 1
                stack_front[topofstackfront]=stack_back[topofstackback];
                stack_back.remove(at: topofstackback);
                
                topofstackback -= 1 ;
                // delete instance
            }
        }
        
        // delete stack_front[topofstackfront];
        stack_front.remove(at: topofstackfront);
        topofstackfront -= 1;
        
    }
    public func peek() -> T! {
        
        if(topofstackfront == -1){
            if(topofstackback == -1){
                print("[NetVision] Stack is Empty.");
                exit(EXIT_FAILURE);
            }
            while(topofstackback >= 0){
                topofstackfront += 1;
                stack_front[topofstackfront]=stack_back[topofstackback];
                topofstackfront -= 1;
                
                // delete instance
            }
        }
        
        return stack_front[topofstackfront]
        
    }
    
}
