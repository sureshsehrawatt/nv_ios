//
//  NvHttpRequestWatcher.h
//  Hackcancer
//
//  Created by compass-362 on 28/09/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NvHttpRequestWatcher : NSURLProtocol <NSURLConnectionDelegate>
-(void)Hello:(NSString *)world;
@property (nonatomic, strong) NSURLConnection *connection;
@property long double requestStartTime;
@property NSUInteger *requestID;
@property NSHTTPURLResponse *response;
@property double responsetime;
@property NSData *responseData;
@property NSMutableData *data;
@property NSURLSessionDataTask *task;
+(void)SetNVServerURL: (NSString *) url;
@end
