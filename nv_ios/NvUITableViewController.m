
//
//  NvUITableViewController.m
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUITableViewController.h"
#import "NV_F4/NV_F4-swift.h"
@class NvActivityLifeCycleMonitor;
@class NvPageDump;
@class NvUtils;
@class NvRequest;
@class LocationManager;
@class NvTimer;

@implementation NvUITableViewController


int millisecondstart;
-(void) viewDidLoad {
    [super viewDidLoad];
    _NvActlMon = [[NvActivityLifeCycleMonitor alloc] init];
    
    _locManager = [[LocationManager alloc] init];
    if( [_locManager didFindLocation] == false) {
        [_locManager fetchLocation];
    }
    _created = false;
    if([self isRootViewCntrl]){
        millisecondstart = (int)[NvTimer current_timestamp];
    }
}
-(void) viewDidAppear:(BOOL)animated {
    
    if([self isRootViewCntrl]){
        int endTime = (int)[NvTimer current_timestamp];
        int timestamp = endTime - millisecondstart;
        NSString *data = [NSString stringWithFormat: @"%i|UITableViewController|%i|%i", millisecondstart, timestamp, [NvApplication getPageId]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:data forKey:@"PageStart"];
        [NvCap addNVEventWithevName:@"PageStart" prop:dict];
    }
    if(!_created){
        [_NvActlMon onActivityCreatedWithActivity:self];
        
    }
    
    
    if(!_created){
        [_NvActlMon onActivityStartedWithActivity:self];
        _created = true;
        
    }
     UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"TableView appears" force:true];
   

     [_NvActlMon onActivityResumedWithActivity:self];
   
    
    
}
-(void) viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    UIView *v ;
    v = self.view;
    UIView *root;
    root = [NvUtils getRootViewWithView:v];
    [_NvActlMon onActivitySaveInstanceStateWithActivity: self];
    
}
-(void) viewWillDisappear:(BOOL)animated {
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [_NvActlMon onActivitySaveInstanceStateWithActivity:self];
    
    [NvPageDump savePageDumpWithView:root Name : @"TableView disappears" force:true];
    [_NvActlMon onActivityPausedWithActivity:self];
    if([self isRootViewCntrl]){
        [_NvActlMon _setNvPageContextWithAct:self];
    }
}

-(BOOL) isRootViewCntrl {
    NSString *actName = (self.nibName != nil) ? self.nibName : @"UIViewController";
    UIViewController *rtViewCntrl = NvUtils.getRootViewController;
    if(rtViewCntrl != nil){
        NSString *rootViewCntrlNIBname = (rtViewCntrl.nibName != nil) ? rtViewCntrl.nibName : actName;
        if([rootViewCntrlNIBname isEqualToString:actName]){
            return true;
        }
    }
    else{
    }
    return false;
}
@end
