//
//  NvUIApplication.h
//  iOSNetVision
//
//  Created by compass-362 on 16/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#ifndef NvUIApplication_h
#define NvUIApplication_h



#endif /* NvUIApplication_h */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "nv_ios/nv_ios.h"

@interface NvUIApplication : UIResponder < UIApplicationDelegate >
@property BOOL *didrecieveSessionInfo;
@property (nonatomic, strong) UIWindow *window;
@property LocationManager *locManager;
@end
