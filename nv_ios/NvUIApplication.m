//
//  NvApplication.m
//  iOSNetVision
//
//  Created by compass-362 on 16/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//#import <Hack_Cancer-Swift.h>

#import <CoreData/CoreData.h>
#import "NvHttpRequestWatcher.h"
#import "NvUIApplication.h"

@class NvActivityLifeCycleMonitor;
@class NvPageDump;
@class NvUtils;
@class NvApplication;
@class NvCapture;
@class LocationManager;

@implementation NvUIApplication

UIViewController *rootViewController ;
UIViewController *currUIViewController ;


//private var rootViewController : UIViewController? = nil;
-(void) initGestureRecognizer : (UIViewController*) vc  {


}



-(void) applicationWillTerminate:(UIApplication *)application {

    [NvCapture stopCapture];

}
-(BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _didrecieveSessionInfo = false;
    _locManager = [[LocationManager alloc] init];

    rootViewController = application.keyWindow.rootViewController;
    //UIViewController *vc = rootViewController;
    [NvApplication _setApp];
   // NSUncaughtExceptionHandler.
    currUIViewController = [NvUtils getRootViewController];

    //UIWindow *keywindow = [[UIApplication sharedApplication] keyWindow];

    return true;
}


#pragma mark - Window

- (UIWindow *)window
{

    if (!_window)
    {
        CGRect bounds = [UIScreen mainScreen].bounds;
        
        _window = [[UIWindow alloc] initWithFrame:bounds];
    }
    
    return _window;
}

@end

/*
 
 - (return_type) method_name:( argumentType1 )argumentName1
 joiningArgument2:( argumentType2 )argumentName2 ...
 joiningArgumentn:( argumentTypen )argumentNamen
 {
 body of the -(void)tion
 }
 
*/
