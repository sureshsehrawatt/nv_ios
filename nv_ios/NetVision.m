//
//  NetVision.m
//  Hackcancer
//
//  Created by compass-362 on 06/01/17.
//  Copyright © 2017 Hackcancer. All rights reserved.
//
#import "NetVision.h"
#import "NvHttpRequestWatcher.h"
#import "nv_ios/nv_ios-Swift.h"
#import <CrashReporter/CrashReporter.h>
#import <CommonCrypto/CommonDigest.h>
#import "NvUIGestureRecognizer.h"
#import <sys/sysctl.h>

@class NvCavConfig;

@implementation NetVision

static NvUIGestureRecognizer *NvGesRecon;

// process Start time ios:

+(void) integrate : (UIWindow *) nvwindow {
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSLog(@"integrate start");
//    NSLog(@"[NetVision] appStartTime is %f",[NetVision processStartTime]);
//    [NvApplication setAppStrTimeWithTime:([NSDate date].timeIntervalSince1970 - [NetVision processStartTime])];
    [NetVision getPageStartTime];
    NSError *error;
    if ([crashReporter hasPendingCrashReport]) {
        NSLog(@"debuging: hasPendingCrashReport");
        [NetVision handleCrashReport];
    }
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        NSLog(@"debuging: [NetVision] Warning: Could not enable crash reporter: %@", error);
    NSString *path = [[NSBundle mainBundle] pathForResource:@"NV" ofType:@"plist"];
    if(path != nil){
        NSDictionary *resourceDict = [[NSDictionary alloc] initWithContentsOfFile:path];
        if(resourceDict != nil){
            if(resourceDict[@"CAV_RUM_SERVICE_AUTH_URL"] != nil){
                [NvCapConfig setAuthURLWithUrl:resourceDict[@"CAV_RUM_SERVICE_AUTH_URL"]];
            }
            else{
                NSLog(@"debuging: [NetVision] Not configured CAV_RUM_SERVICE_AUTH_URL..");
            }
            if(resourceDict[@"ROOTVIEWCONTROLLER"] != nil){
                NSString *rvc= resourceDict[@"ROOTVIEWCONTROLLER"];
                [NvCapConfig setRootViewControllerWithRvc:rvc];
            }
            else{
                
            }
        }
    }
   
    Boolean *varr = [NSURLProtocol registerClass: [NvHttpRequestWatcher class]];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (configuration != nil) {
        NSLog(@"debuging: configuration != nil");
        // Append entry
        NSMutableArray *protcolArray = [configuration.protocolClasses mutableCopy];
        [protcolArray insertObject:[NvHttpRequestWatcher class] atIndex:0];
        configuration.protocolClasses = protcolArray;
    } else {
        NSLog(@"debuging:  } else {");
        configuration.protocolClasses = @[[NvHttpRequestWatcher class]];
    }
    NvGesRecon = [[NvUIGestureRecognizer alloc] init];
    [NvGesRecon InitWithWindow:nvwindow];
    NSLog(@"debuging: end!");
}

+(void) getPageStartTime {
    size_t len = 4;
    int mib[len];
    struct kinfo_proc kp;
    
    sysctlnametomib("kern.proc.pid", mib, &len);
    mib[3] = getpid();
    len = sizeof(kp);
    sysctl(mib, 4, &kp, &len, NULL, 0);
    
    struct timeval startTime = kp.kp_proc.p_un.__p_starttime;
    //    NSLog(@"process time genration successfur %fu",  startTime.tv_sec + startTime.tv_usec / 1e6);
    long int milliSecStart = (long int)[NvTimer current_timestamp];
    double appTime = [NSDate date].timeIntervalSince1970 - startTime.tv_sec + startTime.tv_usec / 1e6;
    NSString *data = [NSString stringWithFormat: @"%.0f", trunc(appTime*1000)];
//    NSLog(@"[NetVision][NvUIViewController] data triggerd from viewWillAppear is %@", abs(data));
    [NvMetadata setAppStartWithTime:data];
}

+ (void) setHttpReqBeacon: (NSString *) url {
    [NvHttpRequestWatcher SetNVServerURL:url];
}

+ (void) handleCrashReport {
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    NSLog(@"[NetVision][Crash] Handle Crash Report");
    // Try loading the crash report
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData == nil) {
        NSLog(@"[NetVision][Crash] Could not load crash report: %@", error);
    }
    else {
        // We could send the report from here, but we'll just print out
        // some debugging info instead
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: crashData error: &error] ;
        if (report == nil) {
            NSLog(@"[NetVision][Crash] Could not parse crash report");
        }
        else{
            NSString *humanReadable = [PLCrashReportTextFormatter stringValueForCrashReport:report withTextFormat:PLCrashReportTextFormatiOS];
    //        printf("[NetVision][Crash] print f data is %s\n", [humanReadable UTF8String]);
            
            NSUserDefaults *nsud = [NSUserDefaults standardUserDefaults];
            
            NSString *Crashkey = @"NvCrashKey" ;
            NSString *urlcontent = [nsud stringForKey:Crashkey];


            NSMutableArray *lines = [humanReadable componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

            NSString *line;
            NSString *value;
            unsigned char result[16];
            NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
            NSString *stackTrace = @"";
            NSString *className = @"";
            NSString *methodName = @"";
            NSString *appName = @"";
            NSString *rawData = @"";
            NSString *hashableString;
            int64_t startTime = [NvTimer current_timestamp];
            while (lines.count > 0) {
                line = lines.firstObject;
                NSMutableArray *parts = [line componentsSeparatedByString:@":"];
                NSString *header = parts.firstObject;
                // generate string data.
                header = [header stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                if([header isEqualToString:@"Process"]){
                    appName = parts.lastObject;
                    appName = [appName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSMutableArray *prt = [appName componentsSeparatedByString:@" "];
                    appName = prt.firstObject;
                    NSLog(@"[NetVision][Crash] app name retrieved from crash data is : %@", appName);
                }
                
                if([header isEqualToString:@"Crashed Thread"]){
                    value = parts.lastObject;
                    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    value = [NSString stringWithFormat:@"Thread %@ Crashed",value];
                }
                else if ([header isEqualToString:value] || [header isEqualToString:@"Last Exception Backtrace"]){ //TODO : check if handling is correct.
                    NSLog(@"[NetVision][Crash] header value retrieved is %@", value);
                    rawData = [NetVision appendData:line priorData:rawData];
                    [lines removeObjectAtIndex:0];
                    line = lines.firstObject;
                   // NSMutableArray *hashcomp = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
       //             hashableString = [NSString stringWithFormat:@"%@%@%@",[hashcomp objectAtIndex:3],hashcomp.lastObject];
                    while(true){
                        NSMutableArray *hashcomp = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if(hashcomp.count > 3){
                        //check for app name and log className, methodName
                            if([className length] == 0 && [line containsString:appName]){
                                className = [hashcomp objectAtIndex:3];
                                //FIXME: Niket - 125560 - In below line of code, objectAtIndex value is changed from 32 to 31.
                                methodName = [NSString stringWithFormat:@"%@ %@", className, [hashcomp objectAtIndex:31]];
                                NSLog(@"[NetVision][Crash]method name is %@", methodName);
                            }
                        
                        // generating hash
                            hashableString = [NSString stringWithFormat:@"%@%@%@",hashableString,[hashcomp objectAtIndex:3],hashcomp.lastObject];
                        
                            // generating raw Data and stackTrace.
                            rawData = [NetVision appendData:line priorData:rawData];
                            stackTrace = [NetVision appendData:line priorData:stackTrace];
                            [lines removeObjectAtIndex:0];
                            line = lines.firstObject;
                            int i;
                            NSLog(@"count = %d",i++);
                        }
                        else {
                            break;
                        }
                    }
                    while(true){
                        // generating raw data
                        rawData = [NetVision appendData:line priorData:rawData];
                        [lines removeObjectAtIndex:0];
                        if(lines.count == 0){
                            break;
                        }
                        line = lines.firstObject;
                    }
                    [jsonDict setObject:stackTrace forKey:@"STACK_TRACE"];
//                    [jsonDict setObject:className forKey:@"CLASS_NAME"];
//                    [jsonDict setObject:methodName forKey:@"METHOD_NAME"];
                    [jsonDict setObject:@"0" forKey:@"LINE_NUMBER"];
                    break;
                }
                else {
                    [jsonDict setObject:parts.lastObject forKey:header];
                }
                rawData = [NetVision appendData:line priorData:rawData];
                [lines removeObjectAtIndex:0];
            }
            NSLog(@"[NetVision][Crash] output crash is : \n %@", stackTrace);
            [jsonDict setObject:rawData forKey:@"RAW_DATA"];
            double timestamp = [report.systemInfo.timestamp timeIntervalSince1970];
            timestamp -= 1388534400;
            
            // generating hash.
            
            const char *cstr = [hashableString UTF8String];
            CC_MD5(cstr, strlen(cstr), result);
            NSString *hash = [NSString stringWithFormat:              @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                              result[0], result[1], result[2], result[3],
                              result[4], result[5], result[6], result[7],
                              result[8], result[9], result[10], result[11],
                              result[12], result[13], result[14], result[15]
                              ];
            
            NSLog(@"[NetVision][Crash] hash %@",hash);
            //humanReadable = [humanReadable stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            NSError *err;
            NSData *postData1 = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&err];
            if(!postData1){
                NSLog(@"Got an error %@", err);
                return;
            }
            NSString *jsonString = [[NSString alloc] initWithData:postData1 encoding:NSUTF8StringEncoding];
            NSLog(@"[NetVision][Crash] checking json data %@", jsonString);
//            NSMutableCharacterSet *set = [NSMutableCharacterSet alphanumericCharacterSet];
//            [set addCharactersInString:@"{}<>,.?/_-[]+:\\"];
//            jsonString = [jsonString stringByAddingPercentEncodingWithAllowedCharacters: set];
//            NSLog(@"[NetVision][Crash]string generated is %@", jsonString);
//            NSString *jsonStr = [jsonString stringByReplacingOccurrencesOfString:@"\\n" withString:@"%0A"];
//            NSLog(@"[NetVision][Crash]after replacing %@", jsonStr);
//            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            jsonString = [jsonString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            NSString *data = [[[NSString alloc] init] stringByAppendingFormat:@"%@|%lu|%@|%@|%@|%@||%@",hash,(unsigned long)timestamp,className,methodName,report.signalInfo.name,report.signalInfo.code,jsonString];
            NSData *postdata = [data dataUsingEncoding:NSUTF8StringEncoding];
            if ( urlcontent == nil){
                NSLog(@"[NetVision][Crash] URL content is nil");
            }
            else {
                NSURL *url = [[NSURL alloc] initWithString:[urlcontent stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];

                NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
                [req setHTTPMethod:@"POST"];
                [req setHTTPBody:postdata];
                NSURLSession *session = [NSURLSession sharedSession];
                [[session dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    NSLog(@"[NetVision][Crash] crash report response %@", response);
                }] resume];
            }
            int64_t endTime = [NvTimer current_timestamp];
            NSLog(@"[NetVision][Crash] diff is %lld", endTime-startTime);
        }
    }
finish:
    [crashReporter purgePendingCrashReport];
    return;
}

+ (NSString *) appendData: (NSString *) strToAppend priorData: (NSString *) prior {
    NSString *temp = [prior stringByAppendingString:strToAppend];
    prior = temp;
    temp = [prior stringByAppendingString:@"\n"];
    prior = temp;
    return prior;
}

@end
    
