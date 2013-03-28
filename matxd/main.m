//
//  main.m
//  matxd
//
//  Created by Kaelin Colclasure on 3/26/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT.h"


@interface MATv5ReadDelegate : NSObject <vMAT_MATv5ReadOperationDelegate> {
    long _remainingLength[128];
}

@property (assign) int recursionDepth;

@end

@implementation MATv5ReadDelegate

- (void)operation:(vMAT_MATv5ReadOperation *)operation
      handleError:(NSError *)error;
{
    NSLog(@"%@", [error localizedDescription]);
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
     handleHeader:(NSData *)descriptiveData
          version:(int16_t)version
        byteOrder:(int32_t)byteOrder;
{
    char * byteOrderDesc[] = { "Unknown", "Little Endian", "Big Endian" };
    char * swapBytesDesc[] = { "native", "needs swapping" };
    NSString * description = [[NSString alloc] initWithBytes:[descriptiveData bytes]
                                                      length:operation.hasSubsystemOffset ? 116 : 124
                                                    encoding:NSUTF8StringEncoding];
    printf("  ↱ Description: %s\n", [description UTF8String]);
    if (operation.hasSubsystemOffset) {
        printf("  ↱ Subsystem Data Offset: %lld\n", operation.subsystemOffset);
    }
    printf("  ↱ Version: %#06x\n", version);
    printf("  ↱ Byte Order: %s (%s)\n", byteOrderDesc[byteOrder], swapBytesDesc[operation.swapBytes]);
    printf("MATv5 Header %s\n", [[descriptiveData description] UTF8String]);
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
           length:(uint32_t)byteLength
           stream:(NSInputStream *)stream;
{
    printf("%*sElement Type %s %d bytes\n", 2 * _recursionDepth, "", [vMAT_MITypeDescription(type) UTF8String], byteLength);
    if (type == miMATRIX) {
        long localDepth = _recursionDepth;
        _remainingLength[localDepth] = byteLength;
        _recursionDepth++;
        while (_remainingLength[localDepth] > 0) {
            [operation readElement];
        }
        _recursionDepth--;
    }
    else {
        NSMutableData * data = [NSMutableData dataWithCapacity:byteLength];
        data.length = byteLength;
        [operation readComplete:[data mutableBytes] length:byteLength];
        printf("%*s↳ %s\n", 2 * _recursionDepth, "", [[data description] UTF8String]);
    }
}

@end

int main(int argc, const char * argv[])
{
    // TODO: Options?
    @autoreleasepool {
        NSInputStream * stream = nil;
        NSString * matPath = [NSString stringWithUTF8String:argv[1]];
        stream = [NSInputStream inputStreamWithFileAtPath:matPath];
        [stream open];
        vMAT_MATv5ReadOperation * reader = [[vMAT_MATv5ReadOperation alloc] initWithInputStream:stream];
        MATv5ReadDelegate * delegate = [[MATv5ReadDelegate alloc] init];
        [reader setDelegate:delegate];
        NSOperationQueue * queue = [[NSOperationQueue alloc] init];
        [queue setName:@"com.ohmware.matxd"];
        [queue addOperation:reader];
        [queue waitUntilAllOperationsAreFinished];
    }
    return 0;
}
