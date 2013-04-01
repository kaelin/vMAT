//
//  vMAT_MATv5ReadOperation.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/27/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5ReadOperation.h"

#import <BlocksKit/BlocksKit.h>


@interface vMAT_MATv5ReadOperation (Private)

- (void)readElementType:(vMAT_MIType *)typeInOut
                 length:(uint32_t *)lengthInOut
            outputBlock:(void(^)())outputBlock;

@end

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

- (void)readComplete:(void *)buffer
              length:(long)length
         handleError:(void(^)(long readLength, NSError * streamError))errorBlock;
{
    long readLength = 0;
    while (readLength < length &&
           !self.isCancelled) {
        long lenr = [_stream read:&buffer[readLength]
                        maxLength:length - readLength];
        if (lenr > 0) {
            readLength += lenr;
            _elementRemainingLength -= lenr;
        }
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
    if (readLength < length && self.isCancelled) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeOperationCancelled
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                @"MATv5 read operation was cancelled."
                }];
    }
}

- (void)readComplete:(void *)buffer
              length:(long)length;
{
    return [self readComplete:buffer length:length
                  handleError:nil];
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
    _elementRemainingLength = 0; // Account for those 128 bytes
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
    __block BOOL didHandleError = NO;
    long skippedLength = 0;
    while (skippedLength < length && !didHandleError) {
        uint8_t skipBuffer[8];
        long lenr = MIN(length - skippedLength, sizeof(skipBuffer));
        [self readComplete:skipBuffer
                    length:lenr
               handleError:^(long readLength, NSError *streamError)
         {
             didHandleError = YES;
             if (streamError != nil) @throw streamError;
         }];
        skippedLength += lenr;
    }
}

static void (^ unexpectedEOS)() = ^ {
    @throw [NSError errorWithDomain:vMAT_ErrorDomain
                               code:vMAT_ErrorCodeEndOfStream
                           userInfo:
            @{ NSLocalizedFailureReasonErrorKey:
            @"MATv5 read operation encountered unexpected end of input stream."
            }];
};

- (void)matchTagType:(vMAT_MIType *)typeInOut
              length:(uint32_t *)lengthInOut
   smallElementBytes:(uint32_t *)bytesOut
           handleEOS:(void(^)())handleEOSBlock;
{
    __block BOOL didHandleError = NO;
    struct { uint32_t type; uint32_t length; } tag;
    [self readComplete:&tag length:8
           handleError:^(long readLength, NSError * streamError)
     {
         didHandleError = YES;
         if (readLength == 0 && streamError == nil) {
             if (*typeInOut != 0 || *lengthInOut != 0) goto error;
             else handleEOSBlock();
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
    if (didHandleError) return;
    uint32_t smallElementBytes = tag.length;
    if (_swapBytes) vMAT_swapbytes(&tag, 2);
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
    else if (*typeInOut != type) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeInvalidMATv5Element
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                [NSString stringWithFormat:@"MATv5 element invalid (read tag %@; expecting %@).",
                 vMAT_MITypeDescription(type), vMAT_MITypeDescription(*typeInOut)],
                }];
    }
    if (*lengthInOut == 0) *lengthInOut = length;
    else if (*lengthInOut != length) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeInvalidMATv5Element
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                [NSString stringWithFormat:@"MATv5 element invalid (read tag %@ with length %u; expecting %u).",
                 vMAT_MITypeDescription(type), length, *lengthInOut],
                }];
    }
}

- (void)matchTagType:(vMAT_MIType *)typeInOut
              length:(uint32_t *)lengthInOut;
{
    return [self matchTagType:typeInOut
                       length:lengthInOut
            smallElementBytes:NULL
                    handleEOS:unexpectedEOS];
}

- (void)matchArrayFlags:(uint32_t *)flagsOut
             dimensions:(NSArray **)dimensionsOut
                   name:(NSString **)nameOut;     // Optional
{
    __block uint32_t type = 0, length = 0;
    type = miUINT32; length = 8;
    [self matchTagType:&type length:&length];
    [self readComplete:flagsOut length:8];
    if (_swapBytes) vMAT_swapbytes(flagsOut, 2);
    int32_t dimensions[8] = { };
    type = miINT32; length = 0;
    [self matchTagType:&type length:&length];
    if (length > sizeof(dimensions)) {
        @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                   code:vMAT_ErrorCodeUnsupportedMATv5Element
                               userInfo:
                @{ NSLocalizedFailureReasonErrorKey:
                [NSString stringWithFormat:@"MATv5 array element has %ld dimensions (can only read up to %ld).",
                 length / sizeof(*dimensions), sizeof(dimensions) / sizeof(*dimensions)],
                }];
    }
    [self readComplete:dimensions length:length];
    long dimensionsLength = length / sizeof(*dimensions);
    if (_swapBytes) vMAT_swapbytes(dimensions, dimensionsLength);
    NSNumber * values[8] = { };
    for (int i = 0;
         i < dimensionsLength;
         i++) {
        values[i] = [NSNumber numberWithInt:dimensions[i]];
    }
    *dimensionsOut = [NSArray arrayWithObjects:values count:dimensionsLength];
    if (nameOut != NULL) {
        type = miINT8; length = 0;
        [self readElementType:&type
                       length:&length
                  outputBlock:
         ^ {
             char name[64] = { }; // namelengthmax is 63 as of MATLAB R2013a
             if (length > sizeof(name)) {
                 @throw [NSError errorWithDomain:vMAT_ErrorDomain
                                            code:vMAT_ErrorCodeUnsupportedMATv5Element
                                        userInfo:
                         @{ NSLocalizedFailureReasonErrorKey:
                         [NSString stringWithFormat:@"MATv5 array element name is %u bytes (can only read up to %ld).",
                          length, sizeof(name)],
                         }];
             }
             [self readComplete:name length:length];
             *nameOut = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
         }];
    }
}

- (void)readElementType:(vMAT_MIType *)typeInOut
                 length:(uint32_t *)lengthInOut
            outputBlock:(void(^)())outputBlock;
{
    uint32_t smallElementBytes = ~0;
    BOOL isSmallElement = NO;
    [self matchTagType:typeInOut
                length:lengthInOut
     smallElementBytes:&smallElementBytes
             handleEOS:unexpectedEOS];
    vMAT_MIType type = *typeInOut;
    uint32_t length = *lengthInOut;
    if (length <= 4 && smallElementBytes != ~0) {
        isSmallElement = YES;
        NSData * smallElementData = [NSData dataWithBytes:&smallElementBytes length:length];
        NSInputStream * delegateStream = [NSInputStream inputStreamWithData:smallElementData];
        NSInputStream * originalStream = _stream;
        long savedElementRemainingLength = _elementRemainingLength;
        _stream = delegateStream;
        [delegateStream open];
        outputBlock();
        [delegateStream close];
        _stream = originalStream;
        _elementRemainingLength = savedElementRemainingLength;
        return;
    }
    // The Matlab documentation is a bit obscure on this point, but seems to be saying:
    long actualLength = (type != miCOMPRESSED
                         ? ((unsigned long)((length) + (8) - 1)) & ~((unsigned long)((8) - 1))
                         : length);
    if (actualLength != length) NSLog(@"%d rounded up to %ld", length, actualLength);
    outputBlock();
    if (actualLength > length) {
        [self skipPadBytes:actualLength - length];
    }
}

- (void)readElement;
{
    __block vMAT_MIType type = 0; // Match any
    __block uint32_t length = 0;  // Match any
    [self readElementType:&type
                   length:&length
              outputBlock:
     ^ {
         [_delegate operation:self
                handleElement:type
                       length:length
                       stream:_stream];
     }];
}

- (void)readToplevelElement;
{
    NSAssert(_elementRemainingLength == 0,
             @"elementRemainingLength is %ld; expecting 0!", _elementRemainingLength);
    vMAT_MIType type = 0; // Match any (really miCOMPRESSED or miMATRIX)
    uint32_t length = 0;  // Match any
    [self matchTagType:&type
                length:&length
     smallElementBytes:NULL
             handleEOS:
     ^ {
         self.isFinished = YES;
     }];
    if (self.isFinished) return;
    // The Matlab documentation is a bit obscure on this point, but seems to be saying:
    long actualLength = (type != miCOMPRESSED
                         ? ((unsigned long)((length) + (8) - 1)) & ~((unsigned long)((8) - 1))
                         : length);
    if (actualLength != length) NSLog(@"%d rounded up to %ld", length, actualLength);
    _elementRemainingLength = length;
    [_elementHandler operation:self
                 handleElement:type
                        length:length
                        stream:_stream];
    if (actualLength > length) {
        [self skipPadBytes:actualLength - length];
    }
    NSAssert(_elementRemainingLength <= 0 && _elementRemainingLength > -7,
             @"elementRemainingLength is %ld; expecting {-7..0}!", _elementRemainingLength);
    _elementRemainingLength = 0;
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
    handleElement:(vMAT_MIType)type
           length:(uint32_t)byteLength
           stream:(NSInputStream *)stream;
{
    NSAssert(operation == self, @"I'm not myself right now!");
    if (_variable == nil) {
        NSAssert(type == miMATRIX, @"Top-level element is not an miMATRIX; implementation not complete!");
        uint32_t flags[2] = { };
        NSArray * dimensions = nil;
        NSString * name = nil;
        [self matchArrayFlags:flags dimensions:&dimensions name:&name];
        _variable = [vMAT_MATv5Variable variableWithMXClass:flags[0] & 0xff
                                                 arrayFlags:flags[0]
                                                 dimensions:dimensions
                                                       name:name];
        [_delegate operation:self
              handleVariable:_variable];
    }
    
    NSMutableData * data = [NSMutableData dataWithCapacity:_elementRemainingLength];
    data.length = _elementRemainingLength;
    [self readComplete:[data mutableBytes] length:_elementRemainingLength];
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
        _operation.delegate = self;
    }
    return self;
}

- (void)start;
{
    [_operation start];
//    NSOperationQueue * queue = [[NSOperationQueue alloc] init];
//    [queue setName:@"com.ohmware.vMAT_MATv5ReadOperationDelegate"];
//    [queue addOperation:_operation];
//    [queue waitUntilAllOperationsAreFinished];
    _completionBlock(@{ }, nil);
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
   handleVariable:(vMAT_MATv5Variable *)variable;
{
    vMAT_MATv5NumericArray * array = [variable toNumericArray];
    [array loadFromOperation:operation
                 withMXClass:mxUINT8_CLASS];
}

- (void)operation:(vMAT_MATv5ReadOperation *)operation
      handleError:(NSError *)error;
{
    _completionBlock(@{ }, error);
    _completionBlock = nil;
}

@end
