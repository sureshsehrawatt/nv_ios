//
//  BFHWMonitor.h
//  OpenShop
//
//  Created by narendra singh on 07/08/20.
//  Copyright © 2020 Business-Factory. All rights reserved.
//

#ifndef NVHWMonitor_h
#define NVHWMonitor_h

@interface NvHWMonitor : NSObject

+ (NvHWMonitor *) shared;
- (void) start;
- (NSString *) flushPerfData:(uint64_t)cavEpochTime;

@end

//typedef struct {
//    NSString *interface;
//    NSTimeInterval timestamp;
//    float sent;
//    uint64_t totalWiFiSent;
//    uint64_t totalWWANSent;
//    
//    float received;
//    uint64_t totalWiFiReceived;
//    uint64_t totalWWANReceived;
//} NetworkBandwidth;

#endif /* NVHWMonitor_h */
