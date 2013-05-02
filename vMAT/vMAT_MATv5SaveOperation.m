//
//  vMAT_MATv5SaveOperation.m
//  vMAT
//
//  Created by Kaelin Colclasure on 5/1/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5SaveOperation.h"

#import "vMAT_Private.h"


@implementation vMAT_MATv5SaveOperation

- (id)initWithOutputStream:(NSOutputStream *)stream;
{
    NSParameterAssert(stream != nil);
    if ((self = [super init]) != nil) {
        _stream = stream;
    }
    return self;
}

- (NSString *)headerDescription;
{
    NSString * desc = nil;
    if ([_dataSource respondsToSelector:@selector(headerDescriptionForOperation:)]) {
        desc = [_dataSource headerDescriptionForOperation:self];
    }
    else {
        NSString * date = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                         dateStyle:NSDateFormatterMediumStyle
                                                         timeStyle:NSDateFormatterLongStyle];
        // TODO: Date should look like "Mon Apr 29 00:17:04 2013"
        //                  instead of "May 2, 2013 11:08:56 AM PDT"
        desc = [NSString stringWithFormat:@"MATLAB 5.0 MAT-file, Platform: MACI64;vMAT %@, Created on: %@",
                vMAT_VersionTag, date];
    }
    if (desc.length == 0 || desc.length > (128 - 12)) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeInvalidMATv5Header
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                [NSString stringWithFormat:@"MATv5 header description length is invalid (%ld bytes).",
                 desc.length],
                }];
    }
    return desc;
}

- (void)writeComplete:(const void *)buffer
               length:(long)length;
{
    long writeLength = 0;
    while (writeLength < length &&
           !self.isCancelled) {
        long lenw = [_stream write:&buffer[writeLength]
                         maxLength:length - writeLength];
        if (lenw >= 0) {
            writeLength += lenw;
        }
        else {
            @throw [_stream streamError];
        }
    }
}

- (void)writeHeader;
{
    NSString * headerDescription = [self headerDescription];
    NSMutableData * data = [NSMutableData dataWithCapacity:128];
    data.length = 128;
    sprintf([data mutableBytes], "%-116s", [headerDescription UTF8String]);
    short * header = [data mutableBytes];
    header[62] = 0x0100;
    header[63] = 0x4d49; // 'MI';
    [self writeComplete:[data bytes] length:[data length]];
    _numberOfVariables = [_dataSource numberOfVariablesForOperation:self];
    _numberOfVariablesRemaining = _numberOfVariables;
}

- (void)writeToplevelElement;
{
    if (_numberOfVariablesRemaining == 0) {
        self.isFinished = YES;
        return;
    }
    NSUInteger index = _numberOfVariables - _numberOfVariablesRemaining;
    --_numberOfVariablesRemaining;
    vMAT_MATv5Variable * variable = [_dataSource operation:self variableAtIndex:index];
    
    [_delegate operation:self didSaveVariable:variable];
}

- (void)main;
{
    @try {
        @autoreleasepool {
            [self writeHeader];
        }
        while (!self.isCancelled &&
               !self.isFinished) {
            @autoreleasepool {
                [self writeToplevelElement];
            }
        }
    }
    @catch (NSError * error) {
        [_delegate operation:self
                 handleError:error];
    }
    @finally {
        self.isFinished = YES;
    }
}

- (void)setIsFinished:(BOOL)isFinished;
{
    if (self.isFinished != isFinished) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = isFinished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

@end

@implementation vMAT_MATv5SaveOperationDelegate

- (id)initWithSaveOperation:(vMAT_MATv5SaveOperation *)operation;
{
    if ((self = [super init]) != nil) {
        _operation = operation;
        _operation.dataSource = self;
        _operation.delegate = self;
    }
    return self;
}

- (void)start;
{
    [_operation start];
    _completionBlock(_workspace, nil);
}

- (NSUInteger)numberOfVariablesForOperation:(vMAT_MATv5SaveOperation *)operation;
{
    return 0;
}

- (vMAT_MATv5Variable *)operation:(vMAT_MATv5SaveOperation *)operation
                  variableAtIndex:(NSUInteger)index;
{
    return nil;
}

- (void)operation:(vMAT_MATv5LoadOperation *)operation
      handleError:(NSError *)error;
{
    _completionBlock(@{ }, error);
    _completionBlock = nil;
}

@end
