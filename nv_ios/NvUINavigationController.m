//
//  NvUINavigationController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUINavigationController.h"

@implementation NvUINavigationController

@class NvUtils;

-(void) viewDidLoad {
    //super viewDidLoad;
    [super viewDidLoad];
    //self.initGestureRecognizer;
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
    //[NvActlMon alloc];
    //[NvActivityLifeCycleMonitor alloc];
   // [_NvActlMon onActivityCreatedWithActivity:self];
    // [_NvActlMon onActivityStartedWithActivity:self];
    
    
}
-(void) viewDidAppear:(BOOL)animated {
    //super.viewDidAppear(animated);
    //self.initGestureRecognizer;
      UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View appears" force:true];
    [super viewDidAppear:animated];
    
   // [_NvActlMon onActivityResumed:self];
  
    
   
    
    
    
}
-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    UIView *v ;
    v = self.view;
    UIView *root;
    root = [NvUtils getRootViewWithView:v];
    //[NvPageDump savePageDumpWithView:root Name : @"View appears" force:false];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    // NvPageDump.savePageDump(NvUtils.getRootView(self.view), name: "View Appears" , force: false);
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    //[NvPageDump savePageDumpWithView:root Name : @"View disappears" force:false];
    [_NvActlMon onActivityPausedWithActivity:self];
}



@end
