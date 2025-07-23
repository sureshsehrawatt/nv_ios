//
//  NvWindowCallback.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit

public class NvWindowCallback : UIWindow {

    static var localCallback: UIWindow = UIWindow() //.Callback ;

    static var mon : NvActivityLifeCycleMonitor? = nil ;

    init (mon : NvActivityLifeCycleMonitor, localCallback: UIWindow) {
        NvWindowCallback.mon = mon;
        NvWindowCallback.localCallback = localCallback;
        super.init(coder: NSCoder.init())!
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    */
    public override func touchesEnded(_ itouches : Set<UITouch>, with event: UIEvent?){
        NvWindowCallback.mon!.processTouchEvent( ev: (itouches.first?.location(in: NvApplication.getApp().inputView))!);
        NvWindowCallback.localCallback.touchesEnded( itouches , with: event)
    }
}
