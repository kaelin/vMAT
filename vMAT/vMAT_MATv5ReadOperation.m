//
//  vMAT_MATv5ReadOperation.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/27/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5ReadOperation.h"


@implementation vMAT_MATv5ReadOperation

- (id)initWithInputStream:(NSInputStream *)stream;
{
    NSParameterAssert(stream != nil);
    if ((self = [super init]) != nil) {
        _stream = stream;
        _elementHandler = self;
    }
    return self;
}

- (long)readComplete:(uint8_t *)buffer
              length:(long)length
         handleError:(void(^)(long readLength, NSError * streamError))errorBlock;
{
    long readLength = 0;
    while (readLength < length &&
           !self.isCancelled) {
        long lenr = [_stream read:&buffer[readLength]
                        maxLength:length - readLength];
        if (lenr > 0) readLength += lenr;
        else if (lenr == 0) {
            NSAssert([_stream streamError] == nil, @"Did not expect a streamError!");
            if (errorBlock != nil) {
                errorBlock(readLength, [_stream streamError]);
            }
            else @throw [_stream streamError];
            break;
        }
        else {
            NSAssert([_stream streamError] != nil, @"Expected a streamError!");
            if (errorBlock != nil) {
                errorBlock(readLength, [_stream streamError]);
            }
            else @throw [_stream streamError];
            break;
        }
    }
    return readLength;
}

- (long)readComplete:(uint8_t *)buffer
              length:(long)length;
{
    long result =
    [self readComplete:buffer length:length
           handleError:nil];
    return result;
}

- (void)readHeader; 
{
    if (self.isCancelled) return;
    uint8_t header[128] = { };
    [self readComplete:header length:128
           handleError:^(long readLength, NSError * streamError)
     {
         @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                    code:vMAT_ErrorCodeInvalidMATv5Header
                                userInfo:
                 @{ NSLocalizedFailureReasonErrorKey:
                 [NSString stringWithFormat:@"MATv5 header incomplete (only %ld bytes).", readLength],
                    NSUnderlyingErrorKey: streamError ? : [NSNull null],
                 }];
     }];
    uint64_t subsystemOffset = *(uint64_t *)&header[117];
    uint16_t version = *(uint16_t *)&header[124];
    uint16_t endianIndicator = *(uint16_t *)&header[126];
    uint16_t bom = 0x4d49; // 'MI';
    if (endianIndicator == bom) {
        _byteOrder = OSHostByteOrder();
        _swapBytes = NO;
    }
    else {
        endianIndicator = OSSwapConstInt16(endianIndicator);
        if (endianIndicator == bom) {
            _byteOrder = (OSHostByteOrder() == OSLittleEndian
                          ? OSBigEndian
                          : OSLittleEndian);
            _swapBytes = YES;
            subsystemOffset = OSSwapConstInt64(subsystemOffset);
            version = OSSwapConstInt16(version);
        }
        else {
            @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                       code:vMAT_ErrorCodeInvalidMATv5Header
                                   userInfo:
                    @{ NSLocalizedFailureReasonErrorKey:
                    [NSString stringWithFormat:@"MATv5 header endian indicator is invalid (%#02x).", endianIndicator],
                    }];
        }
    }
    if (subsystemOffset != 0x2020202020202020 && // All spaces means older file format
        subsystemOffset > 0) {
        _hasSubsystemOffset = YES;
        _subsystemOffset = subsystemOffset;
    }
    if ([_delegate respondsToSelector:@selector(operation:handleHeader:version:byteOrder:)]) {
        [_delegate operation:self
                handleHeader:[NSData dataWithBytes:header length:128]
                     version:version
                   byteOrder:_byteOrder];
    }
}

- (void)skipPadBytes:(long)length;
{
    long skippedLength = 0;
    while (skippedLength < length) {
        uint8_t skipBuffer[8];
        long lenr = [self readComplete:skipBuffer
                                length:MIN(length - skippedLength, sizeof(skipBuffer))];
        if (lenr > 0) skippedLength += lenr;
        else break;
    }
}

- (BOOL)matchTagType:(vMAT_MIType *)typeInOut
              length:(uint32_t *)lengthInOut
   smallElementBytes:(uint32_t *)bytesOut;
{
    struct { uint32_t type; uint32_t length; } tag;
    [self readComplete:(uint8_t *)&tag length:8
           handleError:^(long readLength, NSError * streamError)
     {
         if (readLength == 0 && streamError == nil) {
             if (*typeInOut != 0 || *lengthInOut != 0) goto error;
             self.isFinished = YES;
         }
         else {
         error:
             @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                        code:vMAT_ErrorCodeInvalidMATv5Tag
                                    userInfo:
                     @{ NSLocalizedFailureReasonErrorKey:
                     [NSString stringWithFormat:@"MATv5 tag incomplete (only %ld bytes).", readLength],
                        NSUnderlyingErrorKey: streamError ? : [NSNull null],
                     }];
         }
     }];
    if (self.isCancelled || self.isFinished) {
        return NO;
    }
    uint32_t smallElementBytes = tag.length;
    if (_swapBytes) {
        tag.type = OSSwapConstInt32(tag.type);
        tag.length = OSSwapConstInt32(tag.length);
    }
    BOOL isSmallElement = tag.type > 0xffff;
    vMAT_MIType type = isSmallElement ? (tag.type & 0xffff) : tag.type;
    uint32_t length = isSmallElement ? (tag.type >> 16) & 0b11 : tag.length;
    if (isSmallElement) {
        if (bytesOut == NULL) {
            @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                       code:vMAT_ErrorCodeInvalidMATv5Tag
                                   userInfo:
                    @{ NSLocalizedFailureReasonErrorKey:
                    [NSString stringWithFormat:@"MATv5 tag %@ with small element data is not expected.", vMAT_MITypeDescription(type)],
                    }];
        }
        else *bytesOut = smallElementBytes;
    }
    if (*typeInOut == 0) *typeInOut = type;
    else if (*typeInOut != type) return NO;
    if (*lengthInOut == 0) *lengthInOut = length;
    else if (*lengthInOut != length) return NO;
    return YES;
}

- (BOOL)matchTagType:(vMAT_MIType *)typeInOut
              length:(uint32_t *)lengthInOut;
{
    return [self matchTagType:typeInOut length:lengthInOut smallElementBytes:NULL];
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
           length:(uint32_t)byteLength
           stream:(NSInputStream *)stream;
{
    NSAssert(operation == self, @"I'm not myself right now!");
    NSMutableData * data = [NSMutableData dataWithCapacity:byteLength];
    data.length = byteLength;
    [self readComplete:[data mutableBytes] length:byteLength];
}

- (void)readElement;
{
    vMAT_MIType type = 0; // Match any
    uint32_t length = 0;  // Match any
    uint32_t smallElementBytes = ~0;
    BOOL isSmallElement = NO;
    if (![self matchTagType:&type length:&length smallElementBytes:&smallElementBytes]) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeInvalidMATv5Element
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                [NSString stringWithFormat:@"MATv5 top-level element is incomplete."],
                }];
    }
    if (length <= 4 && smallElementBytes != ~0) {
        isSmallElement = YES;
        NSData * smallElementData = [NSData dataWithBytes:&smallElementBytes length:length];
        NSInputStream * delegateStream = [NSInputStream inputStreamWithData:smallElementData];
        NSInputStream * originalStream = _stream;
        _stream = delegateStream;
        [delegateStream open];
        [_delegate operation:self
               handleElement:type
                      length:length
                      stream:delegateStream];
        [delegateStream close];
        _stream = originalStream;
        return;
    }
    // The Matlab documentation is a bit obscure on this point, but seems to be saying:
    long actualLength = (type != miCOMPRESSED
                         ? ((unsigned long)((length) + (8) - 1)) & ~((unsigned long)((8) - 1))
                         : length);
    NSNumber * savedOffset = [_stream propertyForKey:NSStreamFileCurrentOffsetKey];
    [_elementHandler operation:self
                 handleElement:type
                        length:length
                        stream:_stream];
    long expectOffset = [savedOffset longValue] + actualLength;
    long actualOffset = [[_stream propertyForKey:NSStreamFileCurrentOffsetKey] longValue];
    if (actualLength != length) NSLog(@"%d rounded up to %ld", length, actualLength);
    // NSLog(@"Expected %ld vs. actual %ld", expectOffset, actualOffset);
    if (expectOffset > actualOffset) {
        [self skipPadBytes:expectOffset - actualOffset];
    }
}

- (void)readToplevelElement;
{
    vMAT_MIType type = 0; // Match any (really miCOMPRESSED or miMATRIX)
    uint32_t length = 0;  // Match any
    if (![self matchTagType:&type length:&length]) {
        self.isFinished = YES;
        return;
    }
    // The Matlab documentation is a bit obscure on this point, but seems to be saying:
    long actualLength = (type != miCOMPRESSED
                         ? ((unsigned long)((length) + (8) - 1)) & ~((unsigned long)((8) - 1))
                         : length);
    NSNumber * savedOffset = [_stream propertyForKey:NSStreamFileCurrentOffsetKey];
    [_elementHandler operation:self
                 handleElement:type
                        length:length
                        stream:_stream];
    long expectOffset = [savedOffset longValue] + actualLength;
    long actualOffset = [[_stream propertyForKey:NSStreamFileCurrentOffsetKey] longValue];
    if (actualLength != length) NSLog(@"%d rounded up to %ld", length, actualLength);
    // NSLog(@"Expected %ld vs. actual %ld", expectOffset, actualOffset);
    if (expectOffset > actualOffset) {
        [self skipPadBytes:expectOffset - actualOffset];
    }
}

- (void)main;
{
    @try {
        @autoreleasepool {
            [self readHeader];
        }
        while (!self.isCancelled &&
               !self.isFinished) {
            @autoreleasepool {
                [self readToplevelElement];
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

- (void)setDelegate:(id<vMAT_MATv5ReadOperationDelegate>)delegate;
{
    _delegate = delegate;
    if ([_delegate respondsToSelector:@selector(operation:handleElement:length:stream:)]) {
        _elementHandler = _delegate;
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

@implementation vMAT_MATv5ReadOperationDelegate

- (id)initWithReadOperation:(vMAT_MATv5ReadOperation *)operation;
{
    if ((self = [super init]) != nil) {
        _operation = operation;
    }
    return self;
}

- (void)start;
{
    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
    [queue setName:@"com.ohmware.vMAT_MATv5ReadOperationDelegate"];
    [queue addOperation:_operation];
    [queue waitUntilAllOperationsAreFinished];
    _completionBlock(@{ }, nil);
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
   handleVariable:(vMAT_MATv5Variable *)variable;
{
    
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
      handleError:(NSError *)error;
{
    
}

@end

@implementation vMAT_MATv5Variable

- (id)initWithReadOperation:(vMAT_MATv5ReadOperation *)operation;
{
    if ((self = [super init]) != nil) {
        _operation = operation;
    }
    return self;
}

@end
