//
//  NvUITabBarController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUITabBarController.h"
//#import <Hack_Cancer-Swift.h>
#import "NV_F4/NV_F4-swift.h"
@class NvActivityLifeCycleMonitor;
@class NvPageDump;
@class NvUtils;
@class NvRequest;
@class LocationManager;


@implementation NvUITabBarController




-(void) viewDidLoad {
    //super viewDidLoad;
    [super viewDidLoad];
    //self.initGestureRecognizer;
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
    
}
-(void) viewDidAppear:(BOOL)animated {
    //super.viewDidAppear(animated);
    //self.initGestureRecognizer;
    [super viewDidAppear:animated];
    
   // [_NvActlMon onActivityResumed:self];
    UIView *v = self.view;
    
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View appears" force:true];
    
    
}
-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    UIView *v ;
    v = self.view;
    UIView *root;
    root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View appears" force:false];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    // NvPageDump.savePageDump(NvUtils.getRootView(self.view), name: "View Appears" , force: false);
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    //[NvPageDump savePageDumpWithView:root Name : @"View disappears" force:false];
    //[_NvActlMon onActivityPausedWithActivity:self];
}




@end
