//
//  NvGestureRecognizer.h
//  Hackcancer
//
//  Created by compass-362 on 01/09/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import <NvUIViewController.h>

@class NvAutoTransaction;

@interface NvUIGestureRecognizer : NSObject

@property UITapGestureRecognizer *tapGesture   ;
@property UILongPressGestureRecognizer *longPressedGesture  ;
@property UIRotationGestureRecognizer *rotateGesture  ;
@property UIPinchGestureRecognizer *pinchGesture  ;
@property UIPanGestureRecognizer *panGesture  ;
@property UISwipeGestureRecognizer *LeftswipeGesture   ;
@property UISwipeGestureRecognizer *RightswipeGesture  ;
@property UISwipeGestureRecognizer *UpswipeGesture    ;
@property UISwipeGestureRecognizer *DownswipeGesture  ;


-(void)InitWithWindow:(UIWindow*)window ;

@end
