//
//  NvHttpRequestWatcher.m
//  Hackcancer
//
//  Created by compass-362 on 28/09/16.
//  Copyright © 2016 Hackcancer. All rights reserved.
//

#import "NvHttpRequestWatcher.h"
#import "nv_ios/nv_ios-Swift.h"


@class NvRequest;
@class NvUIApplication;
@class NvActivityLifeCycleMonitor;

@implementation NvHttpRequestWatcher

static NSUInteger requestCount = 0;
static NSUInteger reqID = 0;
static NSUInteger responseCount = 0;
static NSUInteger TotalResponseTime = 0 ;
static NSUInteger MaxResponseTime = 0 ;
static NSUInteger MinResponseTime = 1000;
static double averageResponseTime = 0.00;
static NSUInteger err_count = 0;
static NSUInteger err4xx = 0;
static NSUInteger err5xx = 0;
static NSUInteger errTO = 0;
static NSUInteger errCF = 0;
static NSUInteger errMisc = 0;
static NSString *NV_URL = @"NIL";

+(void)SetNVServerURL: (NSString *) url {
    NV_URL = [[[NSURL alloc] initWithString:url] host] ;
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {

    if ([NSURLProtocol propertyForKey:@"NvProtocolHandledKey" inRequest:request]) {
        return NO;
    }
    [NSURLProtocol setProperty:@YES forKey:@"NvProtocolHandledKey" inRequest:request];
    return YES;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    self.requestID = reqID++;
    if([self.request.URL.host  isEqual: NV_URL]){
        
    }
    else {
        requestCount++;
        [NvPageDump incrementHttpRequestCount];
        [NvAutoTransaction incrementHttpRequestCount];
    }
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"NvProtocolHandledKey" inRequest:newRequest];
   
    _requestStartTime = [[[NSDate alloc] init] timeIntervalSince1970];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading {
    [NSURLProtocol removePropertyForKey:@"NvProtocolHandledKey" inRequest:self.request];
    if([self.request.URL.host  isEqual: NV_URL]){
    }
    else {
        [NvPageDump decrementHttpRequestCount];
        [NvAutoTransaction decrementHttpRequestCount];
        
        [[[NvActivityLifeCycleMonitor alloc] init] formHttpLogWithRequest :self.request response:_response data:self.responseData responsetime:_responsetime];
        [[[NvActivityLifeCycleMonitor alloc] init] updateHttpMonStatWithReq_cnt:requestCount resp_cnt:responseCount err_cnt:err_count avg:averageResponseTime hi:MaxResponseTime lo:MinResponseTime er4x:err4xx er5x:err5xx erTO:errTO erCF:errCF erMisc:errMisc];
    }
    [self.connection cancel];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
   _responsetime = [[[NSDate alloc] init] timeIntervalSince1970] - _requestStartTime;
   
    if([self.request.URL.host  isEqual: NV_URL]){
        
    }
    else {
    
        NSHTTPURLResponse *rs = [[NSHTTPURLResponse alloc] init];
        rs = (NSHTTPURLResponse*)response ;
    
        NSUInteger status = rs.statusCode;
    
        if (status <  100 || status >= 400) {
            err_count++;
            if(status >=400 && status < 500){
                err4xx++;
            }
            if( status >= 500) {
                err5xx++;
            }
        }
        else {
            responseCount++;
            TotalResponseTime += _responsetime;
            averageResponseTime = TotalResponseTime / responseCount;
            if(_responsetime > MaxResponseTime ){
                MaxResponseTime = _responsetime;
            }
            if(_responsetime < MinResponseTime ){
                MinResponseTime = _responsetime;
            }
        }
    }
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    self.responseData = data;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
    if(error.code == NSURLErrorTimedOut){
        errTO++;
    }
    else if( error.code == NSURLErrorUnknown){
        errMisc++;
    }
    else if ( error.code == NSURLErrorUnsupportedURL){
        err4xx++;
    }
    else if ( error.code == NSURLErrorNotConnectedToInternet){
        errCF++;
    }
    else if ( error.code == NSURLErrorRedirectToNonExistentLocation){
        err4xx++;
    }
    else if( error.code == NSURLErrorNoPermissionsToReadFile) {
        err4xx++;
    }
    else if( error.code == NSURLErrorCannotConnectToHost) {
        errCF++;
    }
    else if( error.code == NSURLErrorBadServerResponse) {
        err5xx++;
    }
    else if( error.code == NSURLErrorNetworkConnectionLost) {
        errCF++;
    }
    else {
        errMisc++;
    }
    
    err_count++;
}

@end
