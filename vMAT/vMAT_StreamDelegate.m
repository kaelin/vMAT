//
//  vMAT_StreamDelegate.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/25/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_StreamDelegate.h"

#import "vMAT_Private.h"


dispatch_semaphore_t semaphore = NULL;

@implementation vMAT_StreamDelegate

#pragma mark - Caller's Queue

- (id)initWithStream:(NSStream *)stream
              matrix:(vMAT_Array *)matrix
             options:(NSDictionary *)options;
{
    NSParameterAssert(stream != nil);
    NSParameterAssert(options == nil); // TODO: Implement options…
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Use no more than vMAT_LIMIT_CONCURRENT_STREAMS dispatch work queues.
        semaphore = dispatch_semaphore_create(vMAT_LIMIT_CONCURRENT_STREAMS);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if ((self = [super init]) != nil) {
        _stream = stream;
        _stream.delegate = self;
        _matrix = matrix;
        _options = [options copy];
    }
    return self;
}

- (id)initWithStream:(NSStream *)stream
                rows:(vDSP_Length)rows
                cols:(vDSP_Length)cols
             options:(NSDictionary *)options;
{
    return nil;
}

#pragma mark - Global Concurrent Queue

- (void)main;
{
    NSRunLoop * runLoop = [NSRunLoop currentRunLoop];
    [runLoop run];
    // NSLog(@"%s done", __func__);
    dispatch_semaphore_signal(semaphore);
}

- (void)startReading;
{
    if (_matrix.size[1] == 0) _isGrowingMatrix = YES;
    else NSAssert(_matrix.data.length == vMAT_Size_prod(_matrix.size) * vMAT_MITypeSizeof(_matrix.type), @"Invalid matrix length");
    if (_isGrowingMatrix) { // Read one column at a time into _bufferData
        lenD = _matrix.size[0] * vMAT_MITypeSizeof(_matrix.type);
        NSAssert(lenD > 0, @"Invalid matrix dimensions");
        _bufferData = [NSMutableData dataWithCapacity:lenD];
        _bufferData.length = lenD;
        D = _bufferData.mutableBytes;
    }
    else {                  // Read directly into the output matrix.data
        lenD = _matrix.data.length;
        D = _matrix.data.mutableBytes;
    }
    idxD = 0;
    __weak id weakSelf = self;
    _completionBlock = ^(vDSP_Length outputLength, NSError * error) { // Only handles error
        vMAT_StreamDelegate * weak = weakSelf;
        weak.outputBlock(nil, error);
    };
    [_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
    [self main];
}

- (void)startWriting;
{
    lenD = _matrix.data.length;
    D = _matrix.data.mutableBytes;
    idxD = 0;
    [_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
    [self main];
}

- (void)stream:(NSStream *)stream
   handleEvent:(NSStreamEvent)eventCode;
{
    NSError * error = nil;
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable: {
            long room = lenD - idxD;
            long lenr = [(NSInputStream *)_stream read:&D[idxD]
                                             maxLength:room];
            if (lenr > 0) {
                idxD += lenr;
                room -= lenr;
                if (room == 0) {
                    if (_isGrowingMatrix) {
                        [_matrix.data appendData:_bufferData];
                        idxD = 0; // Reset buffer index
                    }
                    else {
                        [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                          forMode:NSRunLoopCommonModes];
                        _outputBlock(_matrix, error);
                        goto finish;
                    }
                }
            }
            break;
        }
            
        case NSStreamEventHasSpaceAvailable: {
            long room = lenD - idxD;
            long lenw = [(NSOutputStream *)_stream write:&D[idxD]
                                               maxLength:room];
            if (lenw > 0) {
                idxD += lenw;
                room -= lenw;
                if (room == 0) {
                    [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                      forMode:NSRunLoopCommonModes];
                    _completionBlock(lenD / vMAT_MITypeSizeof(_matrix.type), error);
                    goto finish;
                }
            }
            break;
        }
            
        case NSStreamEventErrorOccurred:
            error = [_stream streamError];
            goto error;
            
        case NSStreamEventEndEncountered:
            if (_isGrowingMatrix) {
                vMAT_idx_t m = _matrix.size[0];
                vMAT_idx_t n = (vMAT_idx_t)_matrix.data.length / (m * vMAT_MITypeSizeof(_matrix.type));
                [_matrix reshape:vMAT_MakeSize(m, n)];
                [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                  forMode:NSRunLoopCommonModes];
                _outputBlock(_matrix, error);
                goto finish;
            }
            else {
                error = [NSError errorWithDomain:vMAT_ErrorDomain
                                            code:vMAT_ErrorCodeEndOfStream
                                        userInfo:nil];
            }
        error:
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSRunLoopCommonModes];
            _completionBlock(0, error);
        finish:
            break;
            
        default:
            NSLog(@"%s %ld", __func__, eventCode);
            break;
    }
}

@end
