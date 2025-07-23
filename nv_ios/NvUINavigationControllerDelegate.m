//
//  NvUINavigationControllerDelegate.m
//  iOSNetVision
//
//  Created by compass-362 on 19/08/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

#import "NvUINavigationControllerDelegate.h"
//#import <Hack_Cancer-Swift.h>
#import "NV_F4/NV_F4-swift.h"


@class NvPageDump;

@implementation NvUINavigationControllerDelegate

-(void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    //[NvPageDump savePageDumpWithView:viewController.view Name : @"View will disappear" force:false];
    
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    //[NvPageDump savePageDumpWithView:viewController.view Name : @"View appears" force:false];
    
}

@end
