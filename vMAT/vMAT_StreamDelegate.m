//
//  vMAT_StreamDelegate.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/25/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_StreamDelegate.h"


dispatch_semaphore_t semaphore = NULL;

@implementation vMAT_StreamDelegate

#pragma mark - Caller's Queue

- (id)initWithStream:(NSStream *)stream
                rows:(vDSP_Length)rows
                cols:(vDSP_Length)cols
             options:(NSDictionary *)options;
{
    NSParameterAssert(options == nil); // TODO: Implement options…
    NSParameterAssert(rows * cols > 0);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Use no more than vMAT_LIMIT_CONCURRENT_STREAMS dispatch work queues.
        semaphore = dispatch_semaphore_create(vMAT_LIMIT_CONCURRENT_STREAMS);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if ((self = [super init]) != nil) {
        _stream = stream;
        _stream.delegate = self;
        _rows = rows;
        _cols = cols;
        _options = [options copy];
    }
    return self;
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
    lenD = _rows * _cols * sizeof(float);
    _bufferData = [NSMutableData dataWithCapacity:lenD];
    [_bufferData setLength:lenD];
    D = [_bufferData mutableBytes];
    idxD = 0;
    __weak id weakSelf = self;
    _completionBlock = ^(vDSP_Length outputLength, NSError * error) {
        vMAT_StreamDelegate * weak = weakSelf;
        [weak.bufferData setLength:weak->idxD];
        weak.outputBlock(NULL, 0, weak.bufferData, error);
    };
    [_stream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSRunLoopCommonModes];
    [self main];
}

- (void)startWriting;
{
    lenD = [_bufferData length];
    D = [_bufferData mutableBytes];
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
                    NSMutableData * outputData = [NSMutableData dataWithCapacity:lenD];
                    [outputData setLength:lenD];
                    // Matlab writes data in column order, whereas C stores it in row order.
                    vDSP_mtrans([_bufferData mutableBytes], 1, [outputData mutableBytes], 1, _rows, _cols);
                    _outputBlock([outputData mutableBytes],
                                 lenD / sizeof(float),
                                 outputData, error);
                    goto finish;
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
                    _completionBlock(lenD / sizeof(float), nil);
                    goto finish;
                }
            }
            break;
        }
            
        case NSStreamEventErrorOccurred:
            error = [_stream streamError];
            // Fall through
        case NSStreamEventEndEncountered:
            if (error == nil) {
                error = [NSError errorWithDomain:vMAT_ErrorDomain
                                            code:vMAT_ErrorCodeEndOfStream
                                        userInfo:nil];
            }
            _completionBlock(0, error);
        finish:
            if ([stream streamStatus] != NSStreamStatusClosed) {
                [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                                  forMode:NSRunLoopCommonModes];
            }
            break;
            
        default:
            NSLog(@"%s %ld", __func__, eventCode);
            break;
    }
}

@end
