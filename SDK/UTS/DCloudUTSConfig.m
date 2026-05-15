//
//  DCloudUTSConfig.m
//  UTSTestComponent
//
//  Created by DCloud-iOS-XHY on 2022/12/26.
//

#import "DCloudUTSConfig.h"
#import <DCloudUTSFoundation/DCloudUTSFoundation.h>

@implementation DCloudUTSConfig

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *filePath = [bundle pathForResource:@"config.json" ofType:nil];
        if (filePath) {
            NSData *data = [NSData dataWithContentsOfFile:[bundle pathForResource:@"config.json" ofType:nil]];
            if (data) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if (dict && [dict isKindOfClass:NSDictionary.class]) {
                    NSArray *components = [dict objectForKey:@"components"];
                    if (components && [components isKindOfClass:NSArray.class]) {
                        for (NSDictionary *item in components) {
                            if ([item isKindOfClass:NSDictionary.class]) {
                                NSString *className = [WXConvert NSString:[item objectForKey:@"class"]];
                                NSString *name = [WXConvert NSString:[item objectForKey:@"name"]];
                                Class aClass = NSClassFromString(className);
                                if (name && aClass) {
                                    [WXSDKEngine registerComponent:name withClass:aClass];
                                    NSLog(@"Success register component name:%@ class:%@",name,className);
                                }
                            }
                        }
                    }

                    NSString *hookclass = dict[@"hooksClass"];
                    if (hookclass) {
                        [DCUniBridge registerHookClass:hookclass];
                    }
                }
            }
        }
    });
}

@end
