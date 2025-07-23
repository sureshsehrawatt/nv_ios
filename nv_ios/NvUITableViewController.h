//
//  NvUITableViewController.h
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
//#import <Hack_Cancer-Swift.h>
//#import <iOSNetVision/iOSNetVision-Swift.h>

#import <UIKit/UIKit.h>

@class NvActivityLifeCycleMonitor;
@class LocationManager;

@interface NvUITableViewController : UITableViewController

@property NvActivityLifeCycleMonitor *NvActlMon;
@property LocationManager *locManager;
@property BOOL created;
@end
