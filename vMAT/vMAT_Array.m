//
//  vMAT_Array.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/3/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Array.h"


@interface vMAT_Array (Private)

+ (SEL)copyCmdForType:(vMAT_MIType)typeA
             fromType:(vMAT_MIType)typeB;

@end

@implementation vMAT_Array

+ (vMAT_Array *)arrayWithSize:(vMAT_Size)size
                         type:(vMAT_MIType)type;
{
    return [[vMAT_Array alloc] initWithSize:size
                                       type:type];
}

+ (vMAT_Array *)arrayWithSize:(vMAT_Size)size
                         type:(vMAT_MIType)type
                         data:(NSData *)data;
{
    return [[vMAT_Array alloc] initWithSize:size
                                       type:type
                                       data:[data mutableCopy]];
}

+ (SEL)copyCmdForType:(vMAT_MIType)typeA
             fromType:(vMAT_MIType)typeB;
{
    const int m = miRANGE_LIMIT;
    const int n = miRANGE_LIMIT;
    static SEL cache[m * n];
    SEL copyCmd = nil;
    @synchronized ([self class]) {
        copyCmd = cache[typeA * m + typeB];
        if (copyCmd == nil) {
            NSString * descriptions = [vMAT_MITypeDescription(typeA) stringByAppendingString:vMAT_MITypeDescription(typeB)];
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:NULL];
            NSArray * matches = [regex matchesInString:descriptions options:0 range:NSMakeRange(0, [descriptions length])];
            NSAssert([matches count] == 2, @"Couldn't make copyCmd from %@", descriptions);
            NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
            NSRange r2 = [[matches objectAtIndex:1] rangeAtIndex:1];
            NSString * copyCmdString = [NSString stringWithFormat:@"_copy_%@_from_%@:",
                                        [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
            copyCmd = NSSelectorFromString(copyCmdString);
            cache[typeA * m + typeB] = copyCmd;
        }
    }
    return copyCmd;
}

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type
              data:(NSMutableData *)data;
{
    long lenA = vMAT_Size_prod(size) * vMAT_MITypeSizeof(type);
    NSParameterAssert(lenA >= 0);
    NSParameterAssert(vMAT_MITypeSizeof(type) != 0);
    if ((self = [super init]) != nil) {
        _size = size;
        _type = type;
        _data = data ? : [NSMutableData dataWithCapacity:lenA];
        if (_data.length == 0) _data.length = lenA;
        else NSParameterAssert(_data.length == lenA);
    }
    return self;
}

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type;
{
    return [self initWithSize:size type:type data:nil];
}

- (void)copyFrom:(vMAT_Array *)matrix;
{
    SEL copyCmd = [vMAT_Array copyCmdForType:_type fromType:matrix.type];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:copyCmd withObject:matrix];
#pragma clang diagnostic pop
}

- (void)_copy_miSINGLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
#define TypeA float
#define TypeB double
    long lenA = vMAT_Size_prod(_size);
    long lenB = vMAT_Size_prod(matrix.size);
    NSParameterAssert(lenA == lenB);
    TypeA * A = _data.mutableBytes;
    const TypeB * B = matrix.data.bytes;
    for (int i = 0;
         i < lenA;
         i++) {
        A[i] = B[i];
    }
#undef TypeA
#undef TypeB
}

- (void)reshape:(vMAT_Size)size;
{
    NSParameterAssert(vMAT_Size_prod(size) * vMAT_MITypeSizeof(_type) == _data.length);
    _size = size;
}

@end
