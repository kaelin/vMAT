//
//  main.m
//  matxd
//
//  Created by Kaelin Colclasure on 3/26/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  • Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  • Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "vMAT.h"


@interface MATv5ReadDelegate : NSObject <vMAT_MATv5ReadOperationDelegate>

@property (assign) int recursionDepth;

@end

@implementation MATv5ReadDelegate

- (void)operation:(vMAT_MATv5ReadOperation *)operation
   handleVariable:(vMAT_MATv5Variable *)variable;
{
    // MATv5ReadDelegate provides its own alternative implementation of the
    // -operation:handleElement:length:stream: method. It intentionally
    // bypasses the default processing of workspace variables so that it
    // can dump the constituent elements individually.
    NSAssert(NO, @"%s should never be called!", __func__);
}

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
    const char * descBytes = [descriptiveData bytes];
    NSUInteger descLength  = operation.hasSubsystemOffset ? 116 : 124;
    while (descLength > 0 && (descBytes[descLength - 1] == 0 || isspace(descBytes[descLength - 1])))
        --descLength;
    NSString * description = [[NSString alloc] initWithBytes:descBytes
                                                      length:descLength
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
        _recursionDepth++;
        while (operation.elementRemainingLength > 0) {
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
