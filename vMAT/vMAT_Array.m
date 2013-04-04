//
//  vMAT_Array.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/3/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Array.h"


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

- (void)reshape:(vMAT_Size)size;
{
    NSParameterAssert(vMAT_Size_prod(size) * vMAT_MITypeSizeof(_type) == _data.length);
    _size = size;
}

@end
