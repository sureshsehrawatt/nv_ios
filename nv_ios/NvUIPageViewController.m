//
//  NvUIPageViewController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUIPageViewController.h"
#import "NV_F4/NV_F4-swift.h"

@implementation NvUIPageViewController


-(void) viewDidLoad {
    [super viewDidLoad];
    if(NvCapture.isCapturing == false) {
        return;
    }
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(NvCapture.isCapturing == false) {
        return;
    }
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    
}

-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    if(NvCapture.isCapturing == false) {
        return;
    }
    UIView *v ;
    v = self.view;
    UIView *root;
    root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View appears" force:false];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    if(NvCapture.isCapturing == false) {
        return;
    }
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
}



@end
