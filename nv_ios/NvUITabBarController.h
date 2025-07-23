//
//  NvUITabBarController.h
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
//#import <Hack_Cancer-Swift.h>
#import "nv_ios/nv_ios-swift.h"
#import <UIKit/UIKit.h>

@class NvActivityLifeCycleMonitor;

@interface NvUITabBarController : UITabBarController
@property NvActivityLifeCycleMonitor *NvActlMon;
@end
