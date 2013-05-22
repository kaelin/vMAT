//
//  vMAT_MATv5Variable.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/31/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5Variable.h"

#import "vMAT_Private.h"


@implementation vMAT_MATv5Variable

+ (vMAT_MATv5Variable *)variableWithArray:(vMAT_Array *)matrix
                               arrayFlags:(uint32_t)flags
                                     name:(NSString *)name;
{
    vMAT_MATv5Variable * variable = [[vMAT_MATv5NumericArray alloc] init];
    variable->_isComplex = (flags & 0x800) == 0x800;
    variable->_isGlobal  = (flags & 0x400) == 0x400;
    variable->_isLogical = (flags & 0x200) == 0x200;
    variable->_mxClass = vMAT_MITypeClass(matrix.type);
    variable->_size = matrix.size;
    variable->_name = name;
    return variable;
}

+ (vMAT_MATv5Variable *)variableWithMXClass:(vMAT_MXClass)mxClass
                                 arrayFlags:(uint32_t)flags
                                 dimensions:(vMAT_Size)size
                                       name:(NSString *)name;
{
    vMAT_MATv5Variable * variable = nil;
    switch (mxClass) {
        case mxCHAR_CLASS:
        case mxDOUBLE_CLASS:
        case mxINT16_CLASS:
        case mxINT32_CLASS:
        case mxINT64_CLASS:
        case mxINT8_CLASS:
        case mxSINGLE_CLASS:
        case mxUINT16_CLASS:
        case mxUINT32_CLASS:
        case mxUINT64_CLASS:
        case mxUINT8_CLASS: {
            variable = [[vMAT_MATv5NumericArray alloc] init];
            variable->_isComplex = (flags & 0x800) == 0x800;
            variable->_isGlobal  = (flags & 0x400) == 0x400;
            variable->_isLogical = (flags & 0x200) == 0x200;
            variable->_mxClass = mxClass;
            variable->_size = size;
            variable->_name = name;
            break;
        }
            
        case mxCELL_CLASS:
        case mxOBJECT_CLASS:
        case mxSPARSE_CLASS:
        case mxSTRUCT_CLASS: {
            break;
        }
            
        default: {
            break;
        }
    }
    return variable;
}

- (NSString *)description;
{
    NSString * prefix = [super description];
    NSString * string = [NSString stringWithFormat:@"%.*s; mxClass: %@, size: %@, name: '%@'>",
                         (int)[prefix length] - 1, [prefix UTF8String],
                         vMAT_MXClassDescription(_mxClass),
                         vMAT_StringFromSize(_size),
                         _name];
    return string;
}

- (void)loadFromOperation:(vMAT_MATv5LoadOperation *)operation;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility
}

- (vMAT_Array *)matrix;
{
    return nil;                           // Subclass responsibility
}

- (void)saveFromOperation:(vMAT_MATv5SaveOperation *)operation;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility    
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return nil;                           // Subclass responsibility
}

@end

@implementation NSDictionary (Workspace)

- (vMAT_MATv5Variable *)variable:(NSString *)name;
{
    return [self objectForKey:name];      // Gets type right for ARC
}

@end

@implementation vMAT_MATv5NumericArray

- (uint32_t)arrayFlags;
{
    uint32_t result = _mxClass;
    if (_isComplex) result |= 0x800;
    if (_isGlobal)  result |= 0x400;
    if (_isLogical) result |= 0x200;
    return result;
}

- (vMAT_Array *)matrix;
{
    return _array;
}

- (void)saveFromOperation:(vMAT_MATv5SaveOperation *)operation;
{
    NSOutputStream * header = [NSOutputStream outputStreamToMemory];
    [header open];
    uint32_t tag[2] = { miMATRIX, 0 };
    [header write:(void *)tag maxLength:sizeof(tag)];
    tag[0] = miUINT32; tag[1] = 8;
    [header write:(void *)tag maxLength:sizeof(tag)];
    tag[0] = [self arrayFlags]; tag[1] = 0;
    [header write:(void *)tag maxLength:sizeof(tag)];
    vDSP_Length ndims = vMAT_ndims(_array);
    tag[0] = miINT32; tag[1] = (uint32_t)(4 * ndims);
    [header write:(void *)tag maxLength:sizeof(tag)];
    tag[0] = (uint32_t)_size[0]; tag[1] = (uint32_t)_size[1];
    [header write:(void *)tag maxLength:sizeof(tag)];
    if (ndims > 2) {
        tag[0] = (uint32_t)_size[2]; tag[1] = (uint32_t)_size[3];
        [header write:(void *)tag maxLength:sizeof(tag)];
    }
    NSMutableData * nameData = [[_name dataUsingEncoding:NSASCIIStringEncoding] mutableCopy];
    tag[0] = miINT8; tag[1] = (uint32_t)nameData.length;
    [header write:(void *)tag maxLength:sizeof(tag)];
    [nameData setLength:((unsigned long)((nameData.length) + (8) - 1)) & ~((unsigned long)((8) - 1))];
    [header write:nameData.bytes maxLength:nameData.length];
    tag[0] = _mxClass; tag[1] = (uint32_t)_array.data.length;
    [header write:(void *)tag maxLength:sizeof(tag)];
    NSMutableData * headerData = [header propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    uint32_t * fix = headerData.mutableBytes;
    long actualLength = ((unsigned long)((_array.data.length) + (8) - 1)) & ~((unsigned long)((8) - 1));
    fix[1] = (uint32_t)(headerData.length + actualLength - 8);
    [operation writeComplete:headerData.bytes length:headerData.length];
    [header close];
    [operation writeComplete:_array.data.bytes length:_array.data.length];
    if (actualLength > _array.data.length) {
        char pad[8] = { 0, 'N', 'a', 'k', '!', '!', '!', '!' };
        [operation writeComplete:pad length:actualLength - _array.data.length];
    }
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return self;
}

@end
