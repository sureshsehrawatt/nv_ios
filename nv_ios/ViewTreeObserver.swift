//
//  ViewTreeObserver.swift
//  NetVision
//
//  Created by compass-362 on 23/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
/*
import Foundation
import UIKit

public class ViewTreeObserver {
    public func onstart(){
        let RootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController;
        let currView = RootViewController?.view;
        setupObserverfor(currView!);
        
    }
    public func setupObserverfor(currView : UIView) {
        //currView.tar
        
        if(currView is UITextField){
            (currView as! UITextField).addTarget(currView, action: "EditingBegan:", forControlEvents: UIControlEvents.EditingChanged)
        }
        
        let subviews = currView.subviews;
        
        for view in subviews {
            setupObserverfor(view);
        }
        (currView as! UITextView).delegate?.textViewDidChange!(currView as! UITextView)
    }
    
    public func stop(){
        
    }
}

public func EditingBegan(textField: UITextField) {
    //  take screenshot
    
    // NvPageDump.savePageDump(NvUtils.getRootView(textField as UIView), name: "EditingText" , force: false);
    
}
extension UITextField {
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.addTarget(self, action: "EditingBegan:", forControlEvents: UIControlEvents.EditingChanged)
    }
    
}

*/


