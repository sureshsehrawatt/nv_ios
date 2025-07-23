//
//  NvUITableViewDelegate.m
//  Hackcancer
//
//  Created by compass-362 on 26/12/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import "NvUITableViewDelegate.h"
//#import <Hack_Cancer-Swift.h>
#import "nv_ios/nv_ios-swift.h"

@interface NvUITableViewDelegate () <UITableViewDelegate>

@end
@class NvPageDump;
@class NvUtils;

@implementation NvUITableViewDelegate 

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UIView *v = scrollView;
    
    UIView *root = [NvUtils getRootViewWithView:v];
    [NvPageDump savePageDumpWithView:root Name : @"scrollView appears" force:true];
    
}
@end
