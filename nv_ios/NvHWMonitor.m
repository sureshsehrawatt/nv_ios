//
//  NvHWMonitor.m
//  nv_ios
//
//  Created by narendra singh on 10/08/20.
//  Copyright © 2020 Cavisson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NvHWMonitor.h"
#import <mach/mach.h>
#import <assert.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <UIKit/UIKit.h>



@interface NvHWMonitor()

@end


typedef struct{
    NSString *interface;
    NSTimeInterval timestamp;
    float sent;
    uint64_t totalWiFiSent;
    uint64_t totalWWANSent;
    
    float received;
    uint64_t totalWiFiReceived;
    uint64_t totalWWANReceived;
} NetworkBandwidth;

/*Battarylevel,RAMavailable,RAMTotal,RAMUsed,ROMavailable,ROMTotal,ROMUsed,CPUFrequency,NetworkRecivedbytes,NetworkTransmitBytes,WifiSignalStrength,WifiLinkSpeed,CPUusedPercentage*/
typedef struct {
    long timestamp;
    float batteryLevel;
    float ramAvailable;
    float ramTotal;
    float ramUsed;
    float romAvailable;
    float romTotal;
    float romUsed;
    float cpuFreq;
    float networkRcvdBytes;
    float networkSentBytes;
    float wifiSignalStrength;
    float wifiLinkSpeed;
    float cpuUsages;
    float appCpuUsages;
    float appMemoryUsages;
}PerfData;

@implementation NvHWMonitor {
    NSTimer *timer;
    NSString *currentInterface;
    NetworkBandwidth *prevBandwidth;
    NetworkBandwidth bandwidthBuffer[2];
    char curBandwidthBufferIdx;
    // array for storing performance data temporarly
    NSMutableArray *perfDataQueue;
    PerfData *curPerfData;
    PerfData *perfDataBuffer;
    char curPerfDataIdx;
    short perfDataQueueLength;
    processor_cpu_load_info_t prevCpuInfo;
}


static NvHWMonitor *myinstance;
static NSString *kInterfaceWiFi = @"en0";
static NSString *kInterfaceWWAN = @"pdp_ip0";
static NSString *kInterfaceNone = @"";
static NSString *perfRecordHeader = @"Battarylevel,RAMavailable,RAMTotal,RAMUsed,ROMavailable,ROMTotal,ROMUsed,CPUFrequency,NetworkRecivedbytes,NetworkTransmitBytes,WifiSignalStrength,WifiLinkSpeed,CPUusedPercentage";
static short DEFAULT_PERF_DATA_QUEUE_LENGTH = 30;
static long BYTES_IN_1_MB = 0x100000;


+ (NvHWMonitor *) shared {
    @synchronized (self) {
        if (myinstance == nil) {
            myinstance = [self alloc];
        }
    }
    return myinstance;
}


- (void) start {
    NSLog(@"NvHWMonitor started");
    
    self->curBandwidthBufferIdx = 0;
    //memset buffer.
    memset((void*)&self->bandwidthBuffer[0], 0, sizeof(NetworkBandwidth) * 2);
    
    self->perfDataQueue = [@[] mutableCopy];
    self->perfDataQueueLength = DEFAULT_PERF_DATA_QUEUE_LENGTH;
    
    self->perfDataBuffer = (PerfData *)malloc(sizeof(PerfData) * (self->perfDataQueueLength + 1));
    memset(self->perfDataBuffer, 0, sizeof(PerfData) * (self->perfDataQueueLength + 1));
    self->curPerfDataIdx = 0;
    
    self->prevBandwidth = nil;
    // TODO: set current interface
    self->currentInterface = nil;
    // fill prevBandwidth
    [self logNetworkBandwidthInfo];
    
    //fill prevCpuInfo.
    [self logCPUUsageOverall];
    
    // [timer invalidate];
    self->timer = nil;
    [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(logHWMonitorData) userInfo:nil repeats:YES];
    
    // setup a timer to send dummy request to test networkBandwidth data.
    //[self setupTimerForDummyHttpRequest];
}

- (void) pushPerfData:(PerfData *)currentPerfData  {
    // Check if queue exhausted then remove entry from first place and then insert.
    while (self->perfDataQueue.count >= self->perfDataQueueLength) {
        [self->perfDataQueue removeObjectAtIndex:0];
    }
    
    [self->perfDataQueue addObject:[NSValue valueWithPointer:currentPerfData]];
}

- (void) resetPerfData:(PerfData *)perfData {
    // memset was assigning nan and NV was rejecting data with nan value.
    //memset(perfData, -1, sizeof(PerfData));
    perfData->appCpuUsages =
    perfData->appMemoryUsages =
    perfData->batteryLevel =
    perfData->cpuFreq =
    perfData->cpuUsages =
    perfData->networkRcvdBytes =
    perfData->networkSentBytes =
    perfData->ramAvailable =
    perfData->ramTotal =
    perfData->ramUsed =
    perfData->romAvailable =
    perfData->romUsed =
    perfData->romTotal =
    perfData->wifiLinkSpeed =
    perfData->wifiSignalStrength = -1;
}

// This data will be read by RDT Agent to capture device and app performance stats.
- (void) logRDTData: (PerfData *)perfData {
 NSLog(@"CavPerfData:AppCpuUsages=%.2f;appMemoryUsages=%.2f;Battarylevel=%.2f;RAMavailable=%.2f;RAMTotal=%.2f;RAMUsed=%.2f;ROMavailable=%.2f;ROMTotal=%.2f;ROMUsed=%.2f;CPUFrequency=%.2f;NetworkRecivedbytes=%.2f;NetworkTransmitBytes=%.2f;WifiSignalStrength=%.2f;WifiLinkSpeed=%.2f;CPUusedPercentage=%.2f",
          perfData->appCpuUsages,
          perfData->appMemoryUsages,
          perfData->batteryLevel,
          perfData->ramAvailable,
          perfData->ramTotal,
          perfData->ramUsed,
          perfData->romAvailable,
          perfData->romTotal,
          perfData->romUsed,
          perfData->cpuFreq,
          perfData->networkRcvdBytes,
          perfData->networkSentBytes,
          perfData->wifiSignalStrength,
          perfData->wifiLinkSpeed,
          perfData->cpuUsages);
}

- (void) logHWMonitorData {
    // TODO: It should cover ram, rom, wifi, battery, network and obvious cpu.
    // get current buffer.
    self->curPerfData = &self->perfDataBuffer[self->curPerfDataIdx];
    
    self->curPerfDataIdx = ((self->curPerfDataIdx+1) %  (self->perfDataQueueLength + 1));
    
    [self resetPerfData:self->curPerfData];
    
    //set timestamp
    self->curPerfData->timestamp = (long) [[[NSDate alloc] init] timeIntervalSince1970];
    
    [self logCPUUsages];
    [self logMemoryUsages];
    [self logCPUUsageOverall];
    [self logRamUsagesOverall];
    [self logBatteryPercentage];
    [self logDiskSpace];
    [self logNetworkBandwidthInfo];
    [self logRouterLinkSpeed];
    
    [self pushPerfData:self->curPerfData];
    
    // Log RDT Data.
    [self logRDTData:self->curPerfData];
}

// App specific
- (void) logCPUUsages {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t) tinfo, &task_info_count);
    
    if (kr != KERN_SUCCESS) {
        return;
    }
    
    task_basic_info_t basic_info;
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0;
    
    basic_info = (task_basic_info_t) tinfo;
    
    // get thread in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    
    if (kr != KERN_SUCCESS) {
        return;
    }
    
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < (int)thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t) thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return;
        }
        
        basic_info_th = (thread_basic_info_t) thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float) TH_USAGE_SCALE * 100.0;
        }
        
    } // for each threads.
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count* sizeof(thread_t));
    if (kr != KERN_SUCCESS) {
        NSLog(@"error in deallocating memory");
    }
    
    self->curPerfData->appCpuUsages = tot_cpu;
    NSLog(@"CPU Usages - %f", tot_cpu);
}
/*
 * Flush Data format -  ["Battarylevel,RAMavailable,RAMTotal,RAMUsed,ROMavailable,ROMTotal,ROMUsed,CPUFrequency,NetworkRecivedbytes,NetworkTransmitBytes,WifiSignalStrength,WifiLinkSpeed,CPUusedPercentage", "208607405205,96.0,760.0,3734.0,2974.0,35080.0,51205.0,16125.0,1747.0,14914.85,1252.65,1.0,-1.0,0.0"]
 */
- (NSString *) flushPerfData:(uint64_t)cavEpochTime {
    if (self->perfDataQueue.count == 0)
        return nil;
    NSLog(@"flushPerfData called. Total elements - %d", self->perfDataQueue.count);
    NSMutableString *data = [NSMutableString stringWithString:@"[\""];
    
    // append header first.
    [data appendFormat:@"%@\"", perfRecordHeader];
    
    
    PerfData * perfData;
    while (self->perfDataQueue.count != 0){
        perfData = [[self->perfDataQueue objectAtIndex:0] pointerValue];
        
        [data appendFormat:@",\"%llu,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\"", (perfData->timestamp - cavEpochTime)*1000,
         perfData->batteryLevel,
         perfData->ramAvailable,
         perfData->ramTotal,
         perfData->ramUsed,
         perfData->romAvailable,
         perfData->romTotal,
         perfData->romUsed,
         perfData->cpuFreq,
         perfData->networkRcvdBytes,
         perfData->networkSentBytes,
         perfData->wifiSignalStrength,
         perfData->wifiLinkSpeed,
         perfData->cpuUsages];
/*
        // for debugging data.
        NSLog(@"NvHWMonitor Data:%llu,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f, timestamp = %llu, cav_epoch_time - %llu", (perfData->timestamp - cavEpochTime) * 1000,
              perfData->batteryLevel,
              perfData->ramAvailable,
              perfData->ramUsed,
              perfData->ramUsed,
              perfData->romAvailable,
              perfData->romTotal,
              perfData->romUsed,
              perfData->cpuFreq,
              perfData->networkRcvdBytes,
              perfData->networkSentBytes,
              perfData->wifiSignalStrength,
              perfData->wifiLinkSpeed,
              perfData->cpuUsages,
              (unsigned long long)perfData->timestamp,
              cavEpochTime);
 */
      
        [self->perfDataQueue removeObjectAtIndex:0];
    }
    
    [data appendString:@"]"];
    
    return data;
}

// This method will capture overall ram usages.
- (void) logRamUsagesOverall {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = HOST_VM_INFO64_COUNT;
    
    vm_statistics64_data_t vm_stat;
    vm_size_t pageSize;
    kern_return_t kerr;
    
    //FIXME: get this value from host_page_size. AS iPhone 5S is having some issue which gives host_page_size 16384 while host_statistics64 giving result as per page size 4096
    pageSize = 4096;
    
    kerr = host_statistics64(host_port, HOST_VM_INFO64, (host_info64_t)&vm_stat, &host_size);
    if (kerr != KERN_SUCCESS) {
        NSLog(@"host_statistics64() has failed, error - %s", mach_error_string(kerr));
        return;
    }
    
    uint64_t totalRam, freeRam, usedRam;
    
    totalRam = [NSProcessInfo processInfo].physicalMemory;
    usedRam = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pageSize;
    freeRam = totalRam - usedRam;
    
    self->curPerfData->ramTotal = totalRam/ BYTES_IN_1_MB;
    self->curPerfData->ramUsed = usedRam / BYTES_IN_1_MB;
    self->curPerfData->ramAvailable = freeRam / BYTES_IN_1_MB;
}

- (void) logMemoryUsages {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kerr == KERN_SUCCESS) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
        NSLog(@"Memory in use (in MB): %f", (CGFloat)info.resident_size / 1048576);
        self->curPerfData->appMemoryUsages = (CGFloat)info.resident_size / BYTES_IN_1_MB;
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

- (void) logBatteryPercentage {
    // Check if battery monitoring is not enabeld then do it.
    if (![[UIDevice currentDevice] isBatteryMonitoringEnabled]) {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    }
    
    self->curPerfData->batteryLevel = [[UIDevice currentDevice] batteryLevel];
    NSLog(@"Battery Percentage : %f", self->curPerfData->batteryLevel);
}


- (void) logDiskSpace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    uint64_t totalUsedSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        totalUsedSpace = totalSpace - totalFreeSpace;
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
        
        self->curPerfData->romTotal = totalSpace / BYTES_IN_1_MB;
        self->curPerfData->romUsed = totalUsedSpace / BYTES_IN_1_MB;
        self->curPerfData->romAvailable = totalFreeSpace / BYTES_IN_1_MB;
        
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
}

- (void) logNetworkBandwidthInfo {
    // NetworkBandwidth *bandwidth = (NetworkBandwidth *)malloc(sizeof(NetworkBandwidth));
    NetworkBandwidth *bandwidth = &self->bandwidthBuffer[(int)self->curBandwidthBufferIdx];
    self->curBandwidthBufferIdx = (self->curBandwidthBufferIdx + 1) % 2;
    
    bandwidth->timestamp = [[NSDate date] timeIntervalSince1970];
//    bandwidth->timestamp = [[[NSDate alloc] init] timeIntervalSince1970];
    bandwidth->interface = nil;
    
    int mib[] = {
        CTL_NET,
        PF_ROUTE,
        0,
        0,
        NET_RT_IFLIST2,
        0
    };
    
    size_t len;
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        NSLog(@"sysctl failed (1)");
        return;
    }
    
    char *buf = malloc(len);
    if (!buf)
    {
        NSLog(@"malloc() for buf has failed.");
        return;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        NSLog(@"sysctl failed (2)");
        free(buf);
        return;
    }
    
    char *lim = buf + len;
    char *next = NULL;
    for (next = buf; next < lim; )
    {
        struct if_msghdr *ifm = (struct if_msghdr *)next;
        next += ifm->ifm_msglen;
        
        /* iOS does't include <net/route.h>, so we define our own macros. */
#define RTM_IFINFO2 0x12
        if (ifm->ifm_type == RTM_IFINFO2)
#undef RTM_IFINFO2
        {
            struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
            
            char ifnameBuf[IF_NAMESIZE];
            if (!if_indextoname(ifm->ifm_index, ifnameBuf))
            {
                NSLog(@"if_indextoname() has failed.");
                continue;
            }
            NSString *ifname = [NSString stringWithCString:ifnameBuf encoding:NSASCIIStringEncoding];
            
            if ([ifname isEqualToString:kInterfaceWiFi])
            {
                bandwidth->totalWiFiSent += if2m->ifm_data.ifi_obytes;
                bandwidth->totalWiFiReceived += if2m->ifm_data.ifi_ibytes;
            }
            else if ([ifname isEqualToString:kInterfaceWWAN])
            {
                bandwidth->totalWWANSent += if2m->ifm_data.ifi_obytes;
                bandwidth->totalWWANReceived += if2m->ifm_data.ifi_ibytes;
            }
        }
    }
    
    // FIXME: Currently we are combining data recieved and sent from both the interface but later we should check for interface too which require setup of Reachability.
    // Reference - https://github.com/asido/SystemMonitor/blob/master/SystemMonitor/Network/NetworkInfoController.m
    if (self->prevBandwidth != nil) {
        NSLog(@"Current bandwidth - %p, prevBandwidth - %p", (void *)bandwidth, (void *)prevBandwidth);
        NSLog(@"Current totalWiFiReceived - %llu, totalWWANReceived - %llu", bandwidth->totalWiFiReceived, bandwidth->totalWWANReceived);
        
        bandwidth ->sent = (bandwidth->totalWiFiSent - prevBandwidth->totalWiFiSent);
        bandwidth->received = (bandwidth->totalWiFiReceived - prevBandwidth->totalWiFiReceived);
        
        bandwidth->sent += (bandwidth->totalWWANSent - prevBandwidth->totalWWANSent);
        bandwidth->received += (bandwidth ->totalWWANReceived - prevBandwidth->totalWWANReceived);
        
        NSLog(@"Total Byte Sent - %f,Total Byte Received - %f", bandwidth->sent, bandwidth->received);
        
        self->curPerfData->networkRcvdBytes = bandwidth->received/ (bandwidth->timestamp - prevBandwidth->timestamp);
        self->curPerfData->networkSentBytes = bandwidth->sent / (bandwidth->timestamp - prevBandwidth->timestamp);
    }
    
    // free previous and set this as new.
    free(buf);
    self->prevBandwidth = bandwidth;
}


- (void) setupTimerForDummyHttpRequest {
    NSLog(@"Setting up setupTimerForDummyHttpRequest");
    static NSTimer *requesttimer = nil;
    
    if (requesttimer != nil) {
        [requesttimer invalidate];
        requesttimer = nil;
    }
    
    requesttimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendDummyHttpRequest) userInfo:nil repeats:YES];
}

- (void) sendDummyHttpRequest {
    static int counter = 0;
    static boolean_t isRequestActive = NO;
    
    if (isRequestActive == YES) return;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    counter++;
    [request setURL:[NSURL URLWithString:[@"https://www.cavisson.com/" stringByAppendingFormat:@"?counter=%d", counter]]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:10000];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest: request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // FIXME: Check for errors.
        if (error != nil) {
            NSLog(@"Error in fetch http request %@", [error localizedDescription]);
        } else {
            NSLog(@"Data Received");
        }
        
        isRequestActive = NO;
    }];
    
    isRequestActive = YES;
    [task resume];
}

- (void) logRouterLinkSpeed {
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    double linkSpeed = 0;
    
    NSString *name = [[NSString alloc] init];
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    linkSpeed = networkStatisc->ifi_baudrate;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    self->curPerfData->wifiLinkSpeed = linkSpeed;
    NSLog(@"Router link speed - %f", linkSpeed);
}

- (void) logCPUUsageOverall {
    // host_info params
    unsigned int                processorCount;
    processor_cpu_load_info_t   processorTickInfo;
    mach_msg_type_number_t      processorMsgCount;
    // Errors
    kern_return_t               kStatus;
    // Loops
    unsigned int                i;
    // Data per proc
    unsigned long               system, user, nice, idle;
    unsigned long long          total, inuse;
    
    float usagesPct;
    
    // Read the current ticks
    kStatus = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount,
                                  (processor_info_array_t*)&processorTickInfo, &processorMsgCount);
    if (kStatus != KERN_SUCCESS)
    {
        NSLog(@"host_processor_info() failed");
        return;
    }
    
    
    if (self->prevCpuInfo != nil) {
        usagesPct = 0;
        for (i = 0; i < processorCount; i++) {
            //system.
            if (processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] >= prevCpuInfo[i].cpu_ticks[CPU_STATE_SYSTEM]) {
                system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] - prevCpuInfo[i].cpu_ticks[CPU_STATE_SYSTEM];
            } else {
                // case of overflow.
                system = processorTickInfo[i].cpu_ticks[CPU_STATE_SYSTEM] + (ULONG_MAX - prevCpuInfo[i].cpu_ticks[CPU_STATE_SYSTEM] + 1);
            }
            
            //user
            if (processorTickInfo[i].cpu_ticks[CPU_STATE_USER] >= prevCpuInfo[i].cpu_ticks[CPU_STATE_USER]) {
                user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] - prevCpuInfo[i].cpu_ticks[CPU_STATE_USER];
            } else {
                // case of overflow.
                user = processorTickInfo[i].cpu_ticks[CPU_STATE_USER] + (ULONG_MAX - prevCpuInfo[i].cpu_ticks[CPU_STATE_USER] + 1);
            }
            
            //nice
            if (processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] >= prevCpuInfo[i].cpu_ticks[CPU_STATE_NICE]) {
                nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] - prevCpuInfo[i].cpu_ticks[CPU_STATE_NICE];
            } else {
                // case of overflow.
                nice = processorTickInfo[i].cpu_ticks[CPU_STATE_NICE] + (ULONG_MAX - prevCpuInfo[i].cpu_ticks[CPU_STATE_NICE] + 1);
            }
            
            // idle
            if (processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] >= prevCpuInfo[i].cpu_ticks[CPU_STATE_IDLE]) {
                idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] - prevCpuInfo[i].cpu_ticks[CPU_STATE_IDLE];
            } else {
                // case of overflow.
                idle = processorTickInfo[i].cpu_ticks[CPU_STATE_IDLE] + (ULONG_MAX - prevCpuInfo[i].cpu_ticks[CPU_STATE_IDLE] + 1);
            }
            /*
            NSLog(@"CPU Utilisation cpu %d system = %lul, user = %lul, nice = %lul, idle = %lul", i, system, user, nice, idle);
            */
            
            inuse = (system + user + nice);
            total = inuse + idle;
            
            usagesPct += (inuse/(float)total*100.0);
        }
        
        usagesPct = (usagesPct / (float)processorCount);
        
        self->curPerfData->cpuUsages = usagesPct;
        
        NSLog(@"CPU Utilisation - %.2f", usagesPct);
        
    }
    
    if (self->prevCpuInfo == nil) {
        self->prevCpuInfo = malloc(processorCount * sizeof(*prevCpuInfo));
    }
    
    // fill prevCpuInfo.
    for (natural_t i = 0; i < processorCount; i++) {
        for (NSUInteger j = 0; j < CPU_STATE_MAX; j++) {
            prevCpuInfo[i].cpu_ticks[j] = processorTickInfo[i].cpu_ticks[j];
        }
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)processorTickInfo, (vm_size_t) (processorMsgCount * sizeof(*processorTickInfo)));

}


@end
