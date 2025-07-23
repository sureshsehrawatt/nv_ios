//
//  NvUIViewController.m
//  Hackcancer
//
//  Created by compass-362 on 13/08/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "nv_ios/nv_ios-swift.h"
#import <CoreData/CoreData.h>
#import "NvUIGestureRecognizer.h"
#import "NvUIViewController.h"

@class NvActivityLifeCycleMonitor;
@class NvApplication;
@class NvPageDump;
@class NvUtils;
@class NvRequest;
@class LocationManager;
@class Timer;
@class NvAction;
@class NvCap;
@class NvTimer;
@class NvAutoTransactionConfig;

@implementation NvUIViewController

NvWebViewHandler *webViewHandler;
NvAutoTransaction *autoTxn;
NSString *current;
long int strtTime;
NSMutableDictionary *loadTime;
NSTimer *timer;
BOOL rootNotFound = true;
BOOL created = false;   // responsible for creating webView listener & initialising loadTime dictionary.

-(void) viewDidLoad {
    [super viewDidLoad];
    
    NSString *class = NSStringFromClass([self class]);
    if(!created){
        created = true;
        loadTime = [NSMutableDictionary dictionary];
    }
    //page load time start
    long int milliSecStart = (long int)[NvTimer current_timestamp];
    NSNumber *startTime = [NSNumber numberWithLong:milliSecStart];
    [loadTime setObject:startTime forKey:class];
    self.actNameArray = [NSMutableArray array];
    //if capturing is enabled
    if(NvCapture.isCapturing == false) {
        return;
    }
    _NvActlMon = [NvCapture getActivityMon];
    //set handler/listener for WebView
    //FIXME:: check for webview first.
    if(self.view != nil){
        webViewHandler = [NvWebViewHandler getInstance];
        UIView *view = self.view;
        [webViewHandler addWebViewListenerWithView:view];
    }
    _locManager = [[LocationManager alloc] init];
    if( [_locManager didFindLocation] == false) {
        [_locManager fetchLocation];
    }
    [_NvActlMon onViewDidLoadWithAct:self];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSString *actName = NSStringFromClass([self class]);
    [_NvActlMon setActivityWithAct:actName];
    
    BOOL actContains = false;
    if (!self.actNameArray) {
        self.actNameArray = [NSMutableArray array];
    }

    if (![self.actNameArray containsObject:actName]) {
        [self.actNameArray addObject:actName];
    } else {
        actContains = true;
    }
    
    if([self isRootViewCntrl] && (current == nil || [NvUtils checkIfParentIsCurrentRootViewCntrlWithVc:self current:current])){
        [_NvActlMon _setNvPageContextWithAct:self];
        [_NvActlMon setWebViewSyncVariableWithWvh:webViewHandler];
        current = actName;
        long int startTime;
        startTime = [[loadTime valueForKeyPath:actName] longValue];
        
        if(startTime == nil){
            //load from view Did disappear.
            startTime = [[loadTime valueForKeyPath:@"disAppear"] longValue];
        }
        if (actContains){
            strtTime = [[loadTime valueForKeyPath:@"disAppear"] longValue];
        } else {
            strtTime = startTime;
        }
        long int endTime = (long int)[NvTimer current_timestamp], timestamp = endTime - strtTime;
        NSString *data = [NSString stringWithFormat: @"%lu|%@|%lu|%li", startTime/1000, actName, timestamp, (long)[NvApplication getPageId]];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:data forKey:@"PageStart"];
        [NvAPIApm addNvEventWithEvName:@"PageStart" prop:dict force:false];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(NvCapture.isCapturing == false) return;
    // send the variable in nvBackground.
    NSString *actName = NSStringFromClass([self class]);
    //auto transaction.
    NvAutoTransactionConfig *autoTxnConf = [[[NvCapConfigManager getInstance] getConfig] getAutoTxn]; //NvCapConfigManager.getInstance.getConfig.getAutoTxn;
    if([autoTxnConf isEnable]) {
        autoTxn = [[NvAutoTransaction alloc] initWithVc: actName];
        [NvAutoTransaction setInstanceWithInst:autoTxn];
        [_NvActlMon setAutoTxnWithAutoTxn:autoTxn];
    }

    if([current isEqualToString:actName]) {
        long int endTime = (long int)[NvTimer current_timestamp], timestamp = endTime - strtTime;
        NSString *data = [NSString stringWithFormat: @"%lu|%@|%lu|%li", strtTime/1000, actName, timestamp, (long)[NvApplication getPageId]];
                // Format of Data:
                //       [NvTimer current_timestamp]+"|"+"PageStart"/*getActName*/+"|"+timestamp+"|"+NvApplication.getPageId()/*getPageId*/
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        [dict setObject:data forKey:@"PageStart"];
        [NvAPIApm addNvEventWithEvName:@"PageStart" prop:dict force:true];
    }
    [_NvActlMon onViewDidAppearWithAct:self];
    [timer invalidate];
    timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(captPageDump) userInfo:nil repeats:false];
    // setting timer in order to capture currect pageDump
}

-(void) captPageDump{
    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name:@"View appears" force:false];
}

-(void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if(NvCapture.isCapturing == false) return;
    UIView *v ;
    v = self.view;
    [_NvActlMon onActivitySaveInstanceStateWithActivity: self];
    [_NvActlMon onViewDidLayoutSubviewsWithAct: self];
    if(timer != nil) {
        [timer invalidate];
        timer = nil;
        timer = [NSTimer scheduledTimerWithTimeInterval:1.5 target:self selector:@selector(captPageDump) userInfo:nil repeats:false];
    }
    [NvPageDump setLastLayoutTimestampWithTime:[NvTimer current_timestamp]];
    // reset nvAutoTransaction timer
    [autoTxn resetTimer];
}

-(void) viewWillDisappear:(BOOL)animated {
    if(timer != nil) {
        [timer invalidate];
        timer = nil;
    }
    long int milliSecStart = (long int)[NvTimer current_timestamp];
    
    NSString *actName = NSStringFromClass([self class]);
    if(NvCapture.isCapturing == false) return;
    [_NvActlMon onViewWillDisappearWithAct:self];

    UIView *v = self.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    if([current isEqualToString:actName]) {
        //if pagedump is not captured for current pageInstance capture it.
        //Developer Note:"first flushAllQueues, then change page context"
        if(_NvActlMon == nil){
            _NvActlMon = [NvCapture getActivityMon];
        }
        [NvPageDump savePageDumpWithView:root Name:@"View appears" force:true];
        NSNumber *startTime = [NSNumber numberWithLong:milliSecStart];
        [loadTime setObject:startTime forKey:@"disAppear"];
        [_NvActlMon flushAllRequests];
        current = nil;
        
    }
}

-(BOOL) isRootViewCntrl {
    NSString *actName = NSStringFromClass([self class]);
    UIViewController *rtViewCntrl = [NvUtils getVisibleViewCntrlWithVc:self];
    if(rtViewCntrl != nil) {
        NSString *class = NSStringFromClass([rtViewCntrl class]);
        if(class != nil && actName != nil && [class isEqualToString:actName]){
            return true;
        }
    }
    return false;
}

@end

