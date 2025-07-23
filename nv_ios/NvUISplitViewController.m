//
//  NvUISplitViewController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUISplitViewController.h"
#import "nv_ios/nv_ios-swift.h"
@class NvActivityLifeCycleMonitor;
@class NvPageDump;
@class NvUtils;
@class NvRequest;
@class LocationManager;


@implementation NvUISplitViewController



-(void) viewDidLoad {
    [super viewDidLoad];
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
    [_NvActlMon onActivityCreatedWithActivity:self];
    [_NvActlMon onActivityStartedWithActivity:self];
    
    
}
-(void) viewDidAppear:(BOOL)animated {
    [_NvActlMon onActivityResumedWithActivity:self];
    UIView *v = self.view;
    
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"splitView appears" force:true];
    
    
}
-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    UIView *v ;
    v = self.view;
    UIView *root;
    root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"splitView subview layout" force:false];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View disappears" force:false];
    [_NvActlMon onActivityPausedWithActivity:self];
}



@end
