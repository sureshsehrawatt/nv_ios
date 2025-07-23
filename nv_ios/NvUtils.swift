//
//  NvUtils.swift
//  NetVision
//
//  Created by compass-362 on 15/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import Foundation
import UIKit

/*
func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
//takeScreenShot
}
*/




public func formatSID ( sid : Int64) -> String
{
    let sidSTR = String(sid);
    //find no of digit.
    let n = Int16((sidSTR as NSString).length);
    //add 21 - n 0 in begining.
    var pref = "";
    for i in 1...(21-n) {
        pref += "0";
    }
    return pref + sidSTR;
    
}

class NvUIScrollViewDelegate : UIScrollView, UIScrollViewDelegate {
    internal func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        //NvPageDump.savePageDump(NvUtils.getRootView(self), name: "didscroll" , force: false);
    }
}

/*
extension UIButton {
override public func didMoveToSuperview() {
//take screentshot
}
}
*/
public class NvUtils: NSObject {
    static var leftswipe : UISwipeGestureRecognizer? = nil ;
    @objc(getRootViewWithView:)
    public static func getRootView ( view : UIView ) -> UIView {
        var curr = view
        while( curr.superview != nil ){
            curr = curr.superview!
        }
        return curr
    }
    
    @objc public static func getRootViewController() -> UIViewController? {
        let vc = UIApplication.shared.keyWindow?.rootViewController
        return getVisibleViewControllerFrom(vc: vc)
    }

    @objc(checkIfParentIsCurrentRootViewCntrlWithVc: current:)
    public static func checkIfParentIsCurrentRootViewCntrl(vc: UIViewController, current: String) -> Bool{
        let vc1 = vc.parent;
        if(vc1 != nil)
        {
            //let className = NSStringFromClass(type(of:vc1) as! AnyClass);
            var className = NSStringFromClass(vc1!.classForCoder);
            if(!className.elementsEqual("UIWindow")){
                if(className.elementsEqual(current))
                {
                    return true
                }
                else
                {
                    return checkIfParentIsCurrentRootViewCntrl(vc:vc1!, current:current)
                }
            }
        }
        return false;
    }
    
    @objc(getVisibleViewCntrlWithVc: )
    public static func getVisibleViewCntrl( vc: UIViewController? ) -> UIViewController? {
        // Fixme :
        if(NvCapConfig.getRootViewController().count > 0){
            var rootViewCntrl:UIViewController? = nil;
            let name = NSStringFromClass(type(of: vc) as! AnyClass);
            if(name as String == NvCapConfig.getRootViewController()){
                    return vc;
            }
            else {
                //Niket
//                if(vc?.childViewControllers != nil){
//                    let j = vc?.childViewControllers;
//                    for k in j!{
//                        if(rootViewCntrl == nil) {
//                            rootViewCntrl = getVisibleViewCntrl(vc: k)!;
//                        }
//                    }
//                }
                if(vc?.children != nil){
                    let j = vc?.children;
                    for k in j!{
                        if(rootViewCntrl == nil) {
                            rootViewCntrl = getVisibleViewCntrl(vc: k)!;
                        }
                    }
                }
                return rootViewCntrl;
            }
             //iterate complete tree and see if rootViewControllerClass exist then return that object
        }
        if let nc = vc as? UINavigationController {
            return nc.visibleViewController
        }
        else if let tc = vc as? UITabBarController {
            return tc.selectedViewController
        }
        else {
            if let pvc = vc?.presentedViewController {
                return pvc
            }
            else {
                if(vc?.parent != nil){
                    return getVisibleViewCntrl(vc: vc?.parent);
                }
                else {
                    return vc;
                }
            }
        }
    }

    public static func installswipegesrecon( window : UIWindow) {
        leftswipe = UISwipeGestureRecognizer(target: window, action: "LeftSwipe:")
    }

}

public func LeftSwipe (sender : UISwipeGestureRecognizer) {
}

public func Crash () {
    var i : Int ;
    var j : Int? = nil
     i = (j)!
}

public func getVisibleViewControllerFrom( vc: UIViewController? ) -> UIViewController? {
    if let nc = vc as? UINavigationController {
        return getVisibleViewControllerFrom(vc: nc.visibleViewController)
    }
    else if let tc = vc as? UITabBarController {
        return getVisibleViewControllerFrom(vc: tc.selectedViewController)
    }
    else {
        if let pvc = vc?.presentedViewController {
            return getVisibleViewControllerFrom(vc: pvc)
        }
        else {
            return vc
        }
    }
}




//
//  main.swift
//  d
//
//  Created by compass-362 on 16/07/16.
//  Copyright © 2016 compass-362. All rights reserved.
//


protocol nvenum {}
protocol nvclass {}

public func NSNumberfrom(value : Any) -> NSNumber {
    
    var n : NSNumber = 0 ;
    
    if type(of: value) is Int64.Type {
        n = NSNumber(value: (value as? Int64)!);
    }
    else if type(of: value) is Int.Type {
        n = NSNumber(value: (value as? Int)!);
    }
    else if type(of: value) is Int32.Type {
        n = NSNumber(value: (value as? Int32)!);
    }
    else if type(of: value) is Int8.Type {
        n = NSNumber(value: (value as? Int8)!);
    }
    else if type(of: value) is UInt.Type {
        n = NSNumber(value: (value as? UInt)!)
    }
    else if type(of: value) is UInt8.Type {
        n = NSNumber(value: (value as? UInt8)!)
    }
    else if type(of: value) is UInt16.Type {
        n = NSNumber(value: (value as? UInt16)!)
    }
    else if type(of: value) is UInt32.Type {
        n = NSNumber(value: (value as? UInt32)!)
    }
    else if type(of: value) is UInt64.Type {
        n = NSNumber(value: (value as? UInt64)!)
    }
    else if type(of: value) is Int16.Type {
        n = NSNumber(value: (value as? Int16)!)
    }
    else if type(of: value) is Double.Type {
        n = NSNumber(value: (value as? Double)!)
    }
    else if type(of: value) is Float.Type {
        n = NSNumber(value: (value as? Float)!)
    }
    return n
}

public func correctedJSONString (str : String) -> NSDictionary! {
    let d = str.data(using: String.Encoding.utf8)
    do{
        let output = try JSONSerialization.jsonObject(with: d! , options : JSONSerialization.ReadingOptions.allowFragments );
        return output as! NSDictionary
    }
    catch{}
    //NSJSONSerialization.JSONObjectWithData(string, encoding:,
    //   options :  , erro);
    return nil;
}

public func nvJSONStringfromDictionary( dictionary dic : [NSString : AnyObject]) -> String {
    
    let opt : JSONSerialization.WritingOptions = .prettyPrinted;
    var actionData : String = "";
    do {
        
        let data = try JSONSerialization.data(withJSONObject: dic, options: opt)
        
        actionData = (NSString(data: data, encoding: String.Encoding.utf8.rawValue ) as String?)!
    }
        
    catch {
        print("[NetVision] Error");
    }
    return actionData;
}

public func NvDictionaryfromObject(object : Any) -> [NSString : AnyObject] {
    //print("[NetVision] ag");
    var dictionary = [NSString : AnyObject ]()
    
    let mirror = Mirror(reflecting : object);
    
    //print(object.dynamicType);
    //print(mirror.children.count);
    for child in mirror.children {
        //  print ("hh");
        
        guard let key = child.label else { continue }
        if( child.value is NSNull){
            dictionary[key as NSString] = "" as AnyObject ;
            continue;
        }
        let value: Any = child.value
        if(
            type(of: value) is Int64.Type || type(of: value) is Int.Type ||
                type(of: value) is Int32.Type || type(of: value) is Int8.Type ||
                type(of: value) is UInt.Type || type(of: value) is UInt8.Type ||
                type(of: value) is UInt16.Type || type(of: value) is UInt32.Type ||
                type(of: value) is UInt64.Type || type(of: value) is Int16.Type ||
                type(of: value) is Double.Type || type(of: value) is Float.Type
            
            ){
                
                
                //var i : Int(d);
            dictionary[key as NSString] = NSNumberfrom(value: value);
                //print(key,dictionary[key],d);
                continue;
                
        }
        else if(type(of: value as! AnyObject) is String.Type){
            dictionary[key as NSString] = value as? NSString
        }
        else if(type(of: value) is Bool.Type){
            dictionary[key as NSString] = value as? AnyObject
        }
        else if ( value is AnyObject ) {
            
            //print("[NetVision] \(value) ");
            let childict = NvDictionaryfromObject(object: value);
            let str = nvJSONStringfromDictionary(dictionary: childict)
            //var correctstr = str;
            let correctstr = (correctedJSONString(str: str))!;
            dictionary[key as NSString] = correctstr  ;
            continue;
            
            //print(child.label);
        }
            
        else if value is nvenum { // for enum type
            dictionary[key as NSString] = (value as! NSString);
        }
        else { // for optional type
            let childict = NvDictionaryfromObject(object: value);
            let str = nvJSONStringfromDictionary(dictionary: childict)
            let correctstr = (correctedJSONString(str: str))!;
            dictionary[key as NSString] = correctstr ;
            continue;
        }
    }
    
    return dictionary
}




/*
class NvUIView {
var a : UIView;
a.
}
*/
