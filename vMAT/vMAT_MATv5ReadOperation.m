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
    if ((self = [super init]) != nil) {
        _stream = stream;
    }
    return self;
}

- (long)readComplete:(uint8_t *)buffer
              length:(long)length
         handleError:(void(^)(long readLength, NSError * streamError))errorBlock;
{
    long readLength = 0;
    while (readLength < length &&
           !self.isCancelled &&
           !self.isFinished) {
        long lenr = [_stream read:&buffer[readLength]
                        maxLength:length - readLength];
        if (lenr > 0) readLength += lenr;
        else if (lenr == 0) {
            NSAssert([_stream streamError] == nil, @"Did not expect a streamError!");
            if (errorBlock != nil) {
                errorBlock(readLength, [_stream streamError]);
            }
            if (!self.isCancelled && !self.isFinished) {
                if (readLength == 0) self.isFinished = YES;
                else [self cancel];
            }
            break;
        }
        else {
            NSAssert([_stream streamError] != nil, @"Expected a streamError!");
            if (errorBlock != nil) {
                errorBlock(readLength, [_stream streamError]);
            }
            if (!self.isCancelled && !self.isFinished)  {
                [self cancel];
            }
            if (errorBlock == nil) {
                [_delegate operation:self
                         handleError:[_stream streamError]];
            }
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
         [self cancel];
         [_delegate operation:self
                  handleError:[NSError errorWithDomain:vMAT_ErrorDomain
                                                  code:vMAT_ErrorCodeInvalidMATv5Header
                                              userInfo:
                               @{ NSLocalizedFailureReasonErrorKey:
                               [NSString stringWithFormat:@"MATv5 header incomplete (only %ld bytes).", readLength],
                                  NSUnderlyingErrorKey: streamError ? : [NSNull null],
                               }]];
     }];
    if (self.isCancelled) {
        return;
    }
    uint64_t subsystemOffset = *(uint64_t *)&header[117];
    uint16_t version = *(uint16_t *)&header[124];
    uint16_t endianIndicator = *(uint16_t *)&header[126];
    uint16_t bom = 'MI';
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
            [self cancel];
            [_delegate operation:self
                     handleError:[NSError errorWithDomain:vMAT_ErrorDomain
                                                     code:vMAT_ErrorCodeInvalidMATv5Header
                                                 userInfo:
                                  @{ NSLocalizedFailureReasonErrorKey:
                                  [NSString stringWithFormat:@"MATv5 header endian indicator is invalid (%#02x).", endianIndicator],
                                  }]];
            return;
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

- (void)readElement;
{
    struct { uint32_t type; uint32_t length; } tag;
    [self readComplete:(uint8_t *)&tag length:8
           handleError:^(long readLength, NSError * streamError)
     {
         if (readLength == 0 && streamError == nil) {
             self.isFinished = YES;
         }
         else {
             [self cancel];
             [_delegate operation:self
                      handleError:[NSError errorWithDomain:vMAT_ErrorDomain
                                                      code:vMAT_ErrorCodeInvalidMATv5Tag
                                                  userInfo:
                                   @{ NSLocalizedFailureReasonErrorKey:
                                   [NSString stringWithFormat:@"MATv5 tag incomplete (only %ld bytes).", readLength],
                                      NSUnderlyingErrorKey: streamError ? : [NSNull null],
                                   }]];
         }
     }];
    if (self.isCancelled || self.isFinished) {
        return;
    }
    uint32_t smallElementBytes = tag.length;
    if (_swapBytes) {
        tag.type = OSSwapConstInt32(tag.type);
        tag.length = OSSwapConstInt32(tag.length);
    }
    BOOL isSmallElement = tag.type > 0xffff;
    vMAT_MIType type = isSmallElement ? (tag.type & 0xffff) : tag.type;
    uint32_t length = isSmallElement ? (tag.type >> 16) & 0b11 : tag.length;
    // The Matlab documentation is a bit obscure on this point, but seems to be saying:
    long actualLength = (type != miCOMPRESSED
                         ? ((unsigned long)((length) + (8) - 1)) & ~((unsigned long)((8) - 1))
                         : length);
    NSData * smallElementData = (isSmallElement
                                 ? [NSData dataWithBytes:&smallElementBytes length:length]
                                 : nil);
    if ([_delegate respondsToSelector:@selector(operation:handleElement:length:stream:)]) {
        NSNumber * savedOffset = (!isSmallElement
                                  ? [_stream propertyForKey:NSStreamFileCurrentOffsetKey]
                                  : nil);
        NSInputStream * delegateStream = (isSmallElement
                                          ? [NSInputStream inputStreamWithData:smallElementData]
                                          : _stream);
        if (isSmallElement) [delegateStream open];
        [_delegate operation:self
               handleElement:type
                      length:length
                      stream:delegateStream];
        if (isSmallElement) [delegateStream close];
        if (!isSmallElement) {
            long expectOffset = [savedOffset longValue] + actualLength;
            long actualOffset = [[_stream propertyForKey:NSStreamFileCurrentOffsetKey] longValue];
            if (actualLength != length) NSLog(@"%d rounded up to %ld", length, actualLength);
            NSLog(@"Expected %ld vs. actual %ld", expectOffset, actualOffset);
            if (expectOffset > actualOffset) {
                [self skipPadBytes:expectOffset - actualOffset];
            }
        }
        return;
    }
    NSMutableData * data = (id)smallElementData;
    if (data == nil) {
        data = [NSMutableData dataWithCapacity:length];
        data.length = length;
        [self readComplete:[data mutableBytes] length:length
               handleError:^(long readLength, NSError *streamError)
         {
             [self cancel];
             [_delegate operation:self
                      handleError:[NSError errorWithDomain:vMAT_ErrorDomain
                                                      code:vMAT_ErrorCodeInvalidMATv5Element
                                                  userInfo:
                                   @{ NSLocalizedFailureReasonErrorKey:
                                   [NSString stringWithFormat:@"MATv5 element incomplete (only %ld of %d bytes).",
                                    readLength, length],
                                      NSUnderlyingErrorKey: streamError ? : [NSNull null],
                                   }]];
         }];
        if (self.isCancelled) {
            return;
        }
    }
    if ([_delegate respondsToSelector:@selector(operation:handleElement:data:)]) {
        [_delegate operation:self
               handleElement:type
                        data:data];
    }
    if (length < actualLength) {
        [self skipPadBytes:actualLength - length];
    }
}

- (void)main;
{
    [self readHeader];
    while (!self.isCancelled &&
           !self.isFinished) {
        [self readElement];
    }
    self.isFinished = YES;
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
