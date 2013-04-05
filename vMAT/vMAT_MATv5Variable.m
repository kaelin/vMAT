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

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility
}

- (vMAT_Array *)matrix;
{
    return nil;                           // Subclass responsibility
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

- (vMAT_Array *)matrix;
{
    return _array;
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return self;
}

@end
