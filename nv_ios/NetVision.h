//
//  NetVision.h
//  Hackcancer
//
//  Created by compass-362 on 06/01/17.
//  Copyright © 2017 Hackcancer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NetVision : NSObject
+(void)integrate:(UIWindow*) nvwindow;
+(void)setHttpReqBeacon:(NSString*) url;
@end
