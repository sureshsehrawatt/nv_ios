//
//  NvUIViewController.h
//  iOSNetVision
//
//  Created by compass-362 on 17/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//
//#import <Hack_Cancer-Swift.h>


#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
//#import "NVF-Swift.h"

@class NvActivityLifeCycleMonitor;
@class LocationManager;
@class NvCapture;
@class NvWebViewHandler;
@class NvApplication;
@class NvAutoTransaction;

@interface NvUIViewController : UIViewController 
@property NvActivityLifeCycleMonitor *NvActlMon;
@property LocationManager *locManager;
@property NvWebViewHandler *webViewHandler;
@property NSTimer *timer;
@property NvAutoTransaction *autoTxn;
@property (nonatomic, strong) NSMutableArray *actNameArray;
extern WKWebView *webView;
extern NSMutableDictionary *loadTime;
extern BOOL rootNotFound;
extern BOOL created;
@end
