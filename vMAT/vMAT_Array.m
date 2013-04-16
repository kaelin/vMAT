//
//  vMAT_Array.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/3/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_PrivateArray.h"

#import <objc/objc-class.h>


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

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type
              data:(NSMutableData *)data;
{
    static dispatch_once_t onceToken;
    static Class privateClass[miRANGE_LIMIT] = { };
    dispatch_once(&onceToken, ^ {
        privateClass[miDOUBLE] = objc_getClass("vMAT_DoubleArray");
        privateClass[miSINGLE] = objc_getClass("vMAT_SingleArray");
        privateClass[miINT8] = objc_getClass("vMAT_Int8Array");
        privateClass[miUINT8] = objc_getClass("vMAT_UInt8Array");
        privateClass[miINT16] = objc_getClass("vMAT_Int16Array");
        privateClass[miUINT16] = objc_getClass("vMAT_UInt16Array");
        privateClass[miINT32] = objc_getClass("vMAT_Int32Array");
        privateClass[miUINT32] = objc_getClass("vMAT_UInt32Array");
        privateClass[miINT64] = objc_getClass("vMAT_Int64Array");
        privateClass[miUINT64] = objc_getClass("vMAT_UInt64Array");
    });
    long lenA = vMAT_Size_prod(size) * vMAT_MITypeSizeof(type);
    NSParameterAssert(lenA >= 0);
    NSParameterAssert(vMAT_MITypeSizeof(type) != 0);
    if ((self = [super init]) != nil) {
        _size = size;
        _length = vMAT_Size_prod(_size);
        _multidxs = vMAT_MakeIndex(1,
                                   _size[0],
                                   _size[0] * _size[1],
                                   _size[0] * _size[1] * _size[2]);
        _type = type;
        _data = data ? : [NSMutableData dataWithCapacity:lenA];
        if (_data.length == 0) _data.length = lenA;
        else NSParameterAssert(_data.length == lenA);
        if (privateClass[type] != nil) {
            object_setClass(self, privateClass[type]);
        }
    }
    return self;
}

- (id)initWithSize:(vMAT_Size)size
              type:(vMAT_MIType)type;
{
    return [self initWithSize:size type:type data:nil];
}

- (NSString *)description;
{
    NSString * prefix = [super description];
    NSString * miType = (object_getClass(self) == objc_getClass("vMAT_Array")
                         ? [NSString stringWithFormat:@"type: %@, ", vMAT_MITypeDescription(_type)]
                         : @"");
    NSString * string = [NSString stringWithFormat:@"%.*s; %@size: %@>",
                         (int)[prefix length] - 1, [prefix UTF8String],
                         miType,
                         vMAT_StringFromSize(_size)];
    return string;
}

- (NSNumber *)elementAtIndex:(vMAT_Index)idxs;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility
    return nil;
}

- (void)setElement:(NSNumber *)value
           atIndex:(vMAT_Index)idxs;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility
}

- (BOOL)isEqual:(id)object;
{
    if ([object isKindOfClass:[self class]]) {
        vMAT_Array * array = object;
        if (_type == array.type &&
            vMAT_Size_cmp(_size, array.size) == 0) {
            return [_data isEqual:array.data];
        }
    }
    return NO;
}

- (void)reshape:(vMAT_Size)size;
{
    NSParameterAssert(vMAT_Size_prod(size) * vMAT_MITypeSizeof(_type) == _data.length);
    _size = size;
    _multidxs = vMAT_MakeIndex(1,
                               _size[0],
                               _size[0] * _size[1],
                               _size[0] * _size[1] * _size[2]);
}

@end

@implementation vMAT_DoubleArray

- (NSNumber *)elementAtIndex:(vMAT_Index)idxs;
{
    double * A = (double *)_data.bytes;
    long idxA = vMAT_Index_dot(_multidxs, idxs);
    NSCParameterAssert(idxA >= 0 && idxA < _length);
    return [NSNumber numberWithDouble:A[idxA]];
}

- (void)setElement:(NSNumber *)value
           atIndex:(vMAT_Index)idxs;
{
    double * A = (double *)_data.bytes;
    long idxA = vMAT_Index_dot(_multidxs, idxs);
    NSCParameterAssert(idxA >= 0 && idxA < _length);
    A[idxA] = [value doubleValue];
}

@end

@implementation vMAT_SingleArray

- (NSNumber *)elementAtIndex:(vMAT_Index)idxs;
{
    float * A = (float *)_data.bytes;
    long idxA = vMAT_Index_dot(_multidxs, idxs);
    NSCParameterAssert(idxA >= 0 && idxA < _length);
    return [NSNumber numberWithFloat:A[idxA]];
}

- (void)setElement:(NSNumber *)value
           atIndex:(vMAT_Index)idxs;
{
    float * A = (float *)_data.bytes;
    long idxA = vMAT_Index_dot(_multidxs, idxs);
    NSCParameterAssert(idxA >= 0 && idxA < _length);
    A[idxA] = [value floatValue];
}

@end

@implementation vMAT_Int8Array

@end

@implementation vMAT_Int32Array

@end
