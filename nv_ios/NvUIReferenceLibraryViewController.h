//
//  NvUIReferenceLibraryViewController.h
//  iOSNetVision
//
//  Created by compass-362 on 31/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "nv_ios/nv_ios-swift.h"
#import <UIKit/UIKit.h>

@class NvActivityLifeCycleMonitor;
@class NvUtils;

@interface NvUIReferenceLibraryViewController : UIReferenceLibraryViewController
@property NvActivityLifeCycleMonitor *NvActlMon;
@end
