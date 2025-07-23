//
//  NvUIReferenceLibraryViewController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUIReferenceLibraryViewController.h"
@implementation NvUIReferenceLibraryViewController

int capturePageDump = false;
-(void) viewDidLoad {
    [super viewDidLoad];
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
}

-(void) viewDidAppear:(BOOL)animated {
    if(capturePageDump)
    {
        [super viewDidLayoutSubviews];
        UIView *v ;
        v = self.view;
        UIView *root;
        root = [NvUtils getRootViewWithView:v];
        capturePageDump = false;
    }

    UIView *v = self.view;
    
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View appears" force:true];
    
    
}
-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    // now we should capture the pagedump
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View layout subviews" force:false];
    capturePageDump = true;
}
-(void) viewWillDisappear:(BOOL)animated {
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"View disappears" force:false];
    [_NvActlMon onActivityPausedWithActivity:self];
}



@end
