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
        semaphore = dispatch_semaphore_create(4); // Tie up no more than (N) dispatch work queues
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    if ((self = [super init]) != nil) {
        _stream = stream;
        _stream.delegate = self;
        lenD = rows * cols * sizeof(float);
        _bufferData = [NSMutableData dataWithCapacity:lenD];
        [_bufferData setLength:lenD];
        D = [_bufferData mutableBytes];
        idxD = 0;
    }
    return self;
}

#pragma mark - Global Concurrent Queue

- (void)main;
{
    NSRunLoop * runLoop = [NSRunLoop currentRunLoop];
    [runLoop run];
    NSLog(@"%s done", __func__);
    dispatch_semaphore_signal(semaphore);
}

- (void)startReading;
{
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
                if (room == 0) goto finish;
            }
            break;
        }
            
        case NSStreamEventErrorOccurred:
            // Fall through
        case NSStreamEventEndEncountered:
        finish:
            _outputBlock([_bufferData mutableBytes],
                         lenD / sizeof(float),
                         _bufferData, error);
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop]
                              forMode:NSRunLoopCommonModes];
            break;
            
        default:
            NSLog(@"%s %ld", __func__, eventCode);
            break;
    }
}

@end
