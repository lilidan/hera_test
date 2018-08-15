//
// Copyright (c) 2017, weidian.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "WDHPageBridge.h"
#import "WDHBaseViewController+Extension.h"
#import "WDHPageModel.h"
#import "WDHLog.h"

@implementation WDHPageBridge


NSString *const WHPageBridgeObject = @"WeixinJSBridge";
NSString *const WHPageBridgeMethod_InvokeCallbackHandler = @"invokeCallbackHandler";

//MARK: - 收到JS消息
- (void)onReceiveJSMessage:(NSString *)name body:(id)body controller:(WDHPageBaseViewController *)controller
{
    self.controller = controller;

    NSString *pageName = controller.pageModel.pagePath;
	HRLog(@"view2app_get--->desc: %@", @{@"page":pageName ,@"event":name,@"info":body});

    if ([name isEqualToString:@"invokeHandler"]) {
        [self invokeHandler:body];
    }else if ([name isEqualToString:@"publishHandler"]){
        [self publishHandler:body];
    }

}

- (void)onReceiveJSAlert:(NSString *)message {

}

//MARK: - wk js invoke/publish handler
- (void)invokeHandler:(id)data {
    HRLog(@"<page> invokeHandler: %@",data);
    
    if (data) {
        NSString *e = data[@"event"];
        if (!e || !self.manager) {
            return;
        }
        
        NSInteger callBackId = [data[@"callbackId"] integerValue];
        if ([e isEqualToString:@"getCurrentRoute"]) {
            NSDictionary *params = @{@"route":self.controller.pageModel.pagePath};
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:NULL];
            NSString *param = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSString *js = [NSString stringWithFormat:@"%@.%@('%d',%@)",WHPageBridgeObject,WHPageBridgeMethod_InvokeCallbackHandler,callBackId,param];
            [self callJS:js controller:self.controller callback:nil];
        }else if ([e isEqualToString:@"getLocalImgData"]){
            // 这条协议无法理解...不知道如何回调，所以改为别的处理方式。
            NSDictionary *params = data[@"paramsString"];
//            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:NULL];
//            NSString *param = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            NSString *js = [NSString stringWithFormat:@"%@.%@('%d',%@)",WHPageBridgeObject,WHPageBridgeMethod_InvokeCallbackHandler,callBackId,params];
            [self callJS:js controller:self.controller callback:^(id result) {
                NSLog(@"");
            }];
        }
    }
    
}

- (void)publishHandler:(id)data
{
    HRLog(@"<page> publishHandler: %@",data);

    if (data) {
        NSString *e = data[@"event"];
        if (!e || !self.manager) {
            return;
        }

        if ([e isEqualToString:@"custom_event_DOMContentLoaded"]) {
            [self.controller track_page_ready];
        }

        if (data[@"paramsString"]) {
            [self.manager page_publishHandler:e param:data[@"paramsString"] pageModel:self.controller.pageModel callbackId:@""];
        }
    }

}

- (void)callJS:(NSString *)js controller:(WDHPageBaseViewController *)controller callback:(void (^)(id result))callback {
    HRLog(@"<page> 执行: %@",js);

    NSString *pageName = controller.pageModel.pagePath;
	HRLog(@"app2view--->: desc: %@", @{@"page":pageName,@"info":js});

    [controller.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        // HRLog(@"<page> %@ 执行结果：%@",js,result);
        if (callback) {
            callback(result);
        }
    }];

}

@end

