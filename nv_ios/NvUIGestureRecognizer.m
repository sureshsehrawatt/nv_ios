//
//  NvGestureRecognizer.m
//  Hackcancer
//
//  Created by compass-362 on 01/09/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import "NvUIGestureRecognizer.h"
#import <Foundation/Foundation.h>
#import "NV_F4/NV_F4-swift.h"
@interface NvUIGestureRecognizer()
@property UIWindow *nvwindow;
@end

@class NvActivityLifeCycleMonitor;
@class NvUtils;
@class NvPageDump;

@implementation NvUIGestureRecognizer

-(void) removegestures {
    
}

-(void) InitWithWindow:(UIWindow *)window {
    _nvwindow = window;
    _LeftswipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeLeftSwipeGesture:) ];
    _LeftswipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    
    _RightswipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeRightSwipeGesture:) ];
    _RightswipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    //_RightswipeGesture.
    
    _UpswipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeUpwardSwipeGesture:) ];
    _UpswipeGesture.direction = UISwipeGestureRecognizerDirectionUp;

    _DownswipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget: self action:@selector(recognizeDownwardSwipeGesture:) ];
    _DownswipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(recognizeTapGesture:) ];
    
    _longPressedGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self action: @selector(recognizeLongPressGesture:) ];
    
    _rotateGesture =[[UIRotationGestureRecognizer alloc] initWithTarget: self action: @selector(recognizeRotateGesture:) ];
    
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget: self action: @selector(recognizePinchGesture:) ];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(recognizePanGesture:) ];


    _LeftswipeGesture.cancelsTouchesInView = NO;
    _RightswipeGesture.cancelsTouchesInView = NO;
    _UpswipeGesture.cancelsTouchesInView = NO;
    _DownswipeGesture.cancelsTouchesInView = NO;
    _tapGesture.cancelsTouchesInView = NO;
    _longPressedGesture.cancelsTouchesInView = NO;
    _rotateGesture.cancelsTouchesInView = NO;
    _pinchGesture.cancelsTouchesInView = NO;
    _panGesture.cancelsTouchesInView = NO;

    _panGesture.minimumNumberOfTouches = 1;

    [window addGestureRecognizer:_RightswipeGesture];
    [window addGestureRecognizer:_tapGesture];
    [window addGestureRecognizer:_LeftswipeGesture];

    [window addGestureRecognizer:_UpswipeGesture];
    [window addGestureRecognizer:_DownswipeGesture];
    [window addGestureRecognizer:_rotateGesture];
    [window addGestureRecognizer:_pinchGesture];
}

-(void) simulatedTap : (CGPoint*)event {
//    printf("at.. simulatedTap");
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon TouchGestureWithEvent: *event];
}

-(void) recognizeLeftSwipeGesture : (UISwipeGestureRecognizer*)sender  {
//    printf("at.. recognizeLeftSwipeGesture");
    CGPoint event;
    event = [sender locationInView: [NvUtils getRootViewController].view ];

    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon SwipeGestureWithEvent: event];
}

-(void) recognizeRightSwipeGesture : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView: [NvUtils getRootViewController].view ];

    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon SwipeGestureWithEvent: event];
}

-(void) recognizeUpwardSwipeGesture : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView:[NvUtils getRootViewController].view ];
    int x = event.x;
    int y = (event.y);
   
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    
    [NvActlMon SwipeGestureWithEvent: event];
}

-(void) recognizeDownwardSwipeGesture : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView:[NvUtils getRootViewController].view ];
    
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon SwipeGestureWithEvent: event];
}

-(void) recognizeLongPressGesture  : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView:sender.view.window ];
    
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon LongPressGestureWithEvent: event];
}

-(void) recognizeTapGesture : (UISwipeGestureRecognizer*)sender {
//    printf("at.. recognizeTapGesture");
    CGPoint event;
    event = [sender locationInView:sender.view.window];
    UIView *v = sender.view;
    UIView *root = [NvUtils getRootViewWithView:v];
    NSURL *verify = [NSURL URLWithString:@"https://google.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:verify];
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    NvActivityLifeCycleMonitor *nvActlMon = [NvCapture getActivityMon];
    [nvActlMon setActWithAct:[NvUtils getRootViewController]];
    [nvActlMon TouchGestureWithEvent: event];
}
-(void) recognizeRotateGesture : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView:[NvUtils getRootViewController].view ];
   
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon RotationGestureWithEvent: event];
}

-(void) recognizePinchGesture : (UISwipeGestureRecognizer*)sender {
    CGPoint event;
    event = [sender locationInView:[NvUtils getRootViewController].view ];
   
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon PinchGestureWithEvent: event];
}

-(void) recognizePanGesture : (UISwipeGestureRecognizer*)sender {
    
    CGPoint event;
    event = [sender locationInView: [[sender view] window] ];
   
    NvActivityLifeCycleMonitor *NvActlMon = [[NvActivityLifeCycleMonitor alloc] initWithVc:[NvUtils getRootViewController]];
    [NvActlMon PanGestureWithEvent: event];
}

@end
