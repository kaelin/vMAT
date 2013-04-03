//
//  vMAT_MATv5Variable.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/31/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5Variable.h"


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
    NSString * string = [NSString stringWithFormat:@"%.*s; mxClass: %@, size: %@, name: \"%@\">",
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

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return nil;                           // Subclass responsibility
}

@end

@implementation vMAT_MATv5NumericArray

- (SEL)loadCmdForType:(vMAT_MIType)type
              mxClass:(vMAT_MXClass)mxClass;
{
    const int m = mxRANGE_LIMIT;
    const int n = miRANGE_LIMIT;
    static SEL cache[m * n];
    SEL loadCmd = nil;
    @synchronized ([self class]) {
        loadCmd = cache[mxClass * m + type];
        if (loadCmd == nil) {
            NSString * descriptions = [vMAT_MITypeDescription(type) stringByAppendingString:vMAT_MXClassDescription(mxClass)];
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:NULL];
            NSArray * matches = [regex matchesInString:descriptions options:0 range:NSMakeRange(0, [descriptions length])];
            NSAssert([matches count] == 2, @"Couldn't make loadCmd from %@", descriptions);
            NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
            NSRange r2 = [[matches objectAtIndex:1] rangeAtIndex:1];
            NSString * loadCmdString = [NSString stringWithFormat:@"_load_%@_%@_fromOperation:",
                                        [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
            loadCmd = NSSelectorFromString(loadCmdString);
            cache[mxClass * m + type] = loadCmd;
        }
    }
    return loadCmd;
}

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    [self loadFromOperation:operation
                withMXClass:_mxClass];
}

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation
              withMXClass:(vMAT_MXClass)mxClass;
{
    const int numericClasses = 0b1111111111010000;
    NSAssert(numericClasses & (1 << mxClass), @"%@ is not a numeric class", vMAT_MXClassDescription(mxClass));
    _mxClass = mxClass;
    __block vMAT_MIType type = 0;
    __block uint32_t length = 0;
    [operation readElementType:&type
                        length:&length
                   outputBlock:
     ^ {
         SEL loadCmd = [self loadCmdForType:type mxClass:_mxClass];
         NSLog(@"Loading %@", self);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
         [self performSelector:loadCmd withObject:operation];
#pragma clang diagnostic pop
     }];
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return self;
}

void
vMAT_Size123Iterator(vMAT_Size size,
                     void (^ block)(int32_t n, int32_t o, int32_t p))
{
    int32_t limP = size[3] ? : 1;
    int32_t limO = size[2] ? : 1;
    int32_t limN = size[1] ? : 1;
    for (int32_t p = 0;
         p < limP;
         p++) {
        for (int32_t o = 0;
             o < limO;
             o++) {
            for (int32_t n = 0;
                 n < limN;
                 n++) {
                block(n, o, p);
            }
        }
    }
}

- (void)_load_miDOUBLE_mxDOUBLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
#define SwapA(A, lenA) vMAT_swapbytes(A, lenA);
#define TypeA double
#define TypeB double
    long lenC = _size[0] * sizeof(TypeA);
    TypeA * C = malloc(lenC);
    long lenD = vMAT_Size_prod(_size) * sizeof(TypeB);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    TypeB * D = [_arrayData mutableBytes];
    __block long idxD = 0;
    vMAT_Size123Iterator(_size, ^(int32_t n, int32_t o, int32_t p) {
        [operation readComplete:C
                         length:lenC];
        if (operation.swapBytes) { SwapA(C, lenC / sizeof(TypeA)); }
        for (int m = 0;
             m < _size[0];
             m++) {
            D[idxD] = C[m];
            ++idxD;
        }
    });
    free(C);
#undef SwapA
#undef TypeA
#undef TypeB
}

- (void)_load_miSINGLE_mxSINGLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
#define SwapA(A, lenA) vMAT_swapbytes(A, lenA);
#define TypeA float
#define TypeB float
    long lenC = _size[0] * sizeof(TypeA);
    TypeA * C = malloc(lenC);
    long lenD = vMAT_Size_prod(_size) * sizeof(TypeB);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    TypeB * D = [_arrayData mutableBytes];
    __block long idxD = 0;
    vMAT_Size123Iterator(_size, ^(int32_t n, int32_t o, int32_t p) {
        [operation readComplete:C
                         length:lenC];
        if (operation.swapBytes) { SwapA(C, lenC / sizeof(TypeA)); }
        for (int m = 0;
             m < _size[0];
             m++) {
            D[idxD] = C[m];
            ++idxD;
        }
    });
    free(C);
#undef SwapA
#undef TypeA
#undef TypeB
}

- (void)_load_miUINT8_mxDOUBLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
#define SwapA(A, lenA) ; // No need for swapping with 1-byte elements.
#define TypeA uint8_t
#define TypeB double
    long lenC = _size[0] * sizeof(TypeA);
    TypeA * C = malloc(lenC);
    long lenD = vMAT_Size_prod(_size) * sizeof(TypeB);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    TypeB * D = [_arrayData mutableBytes];
    __block long idxD = 0;
    vMAT_Size123Iterator(_size, ^(int32_t n, int32_t o, int32_t p) {
        [operation readComplete:C
                         length:lenC];
        if (operation.swapBytes) { SwapA(C, lenC / sizeof(TypeA)); }
        for (int m = 0;
             m < _size[0];
             m++) {
            D[idxD] = C[m];
            ++idxD;
        }
    });
    free(C);
#undef SwapA
#undef TypeA
#undef TypeB
}

- (void)_load_miUINT8_mxSINGLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
#define SwapA(A, lenA) ; // No need for swapping with 1-byte elements.
#define TypeA uint8_t
#define TypeB float
    long lenC = _size[0] * sizeof(TypeA);
    TypeA * C = malloc(lenC);
    long lenD = vMAT_Size_prod(_size) * sizeof(TypeB);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    TypeB * D = [_arrayData mutableBytes];
    __block long idxD = 0;
    vMAT_Size123Iterator(_size, ^(int32_t n, int32_t o, int32_t p) {
        [operation readComplete:C
                         length:lenC];
        if (operation.swapBytes) { SwapA(C, lenC / sizeof(TypeA)); }
        for (int m = 0;
             m < _size[0];
             m++) {
            D[idxD] = C[m];
            ++idxD;
        }
    });
    free(C);
#undef SwapA
#undef TypeA
#undef TypeB
}

- (void)_load_miUINT8_mxUINT8_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
#define SwapA(A, lenA) ; // No need for swapping with 1-byte elements.
#define TypeA uint8_t
#define TypeB uint8_t
    long lenC = _size[0] * sizeof(TypeA);
    TypeA * C = malloc(lenC);
    long lenD = vMAT_Size_prod(_size) * sizeof(TypeB);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    TypeB * D = [_arrayData mutableBytes];
    __block long idxD = 0;
    vMAT_Size123Iterator(_size, ^(int32_t n, int32_t o, int32_t p) {
        [operation readComplete:C
                         length:lenC];
        if (operation.swapBytes) { SwapA(C, lenC / sizeof(TypeA)); }
        for (int m = 0;
             m < _size[0];
             m++) {
            D[idxD] = C[m];
            ++idxD;
        }
    });
    free(C);
#undef SwapA
#undef TypeA
#undef TypeB
}

@end
