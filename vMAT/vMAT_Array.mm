//
//  vMAT_Array.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/4/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Array.h"


@implementation vMAT_Array (CopyFrom)

+ (SEL)copyCmdForType:(vMAT_MIType)typeA
             fromType:(vMAT_MIType)typeB;
{
    const int m = miRANGE_LIMIT;
    const int n = miRANGE_LIMIT;
    static SEL cache[m * n];
    SEL copyCmd = nil;
    @synchronized (self) {
        copyCmd = cache[typeA * m + typeB];
        if (copyCmd == nil) {
            copyCmd = vMAT::genericCmd(@"_copy_%@_from_%@:", typeA, typeB);
            cache[typeA * m + typeB] = copyCmd;
        }
    }
    return copyCmd;
}

- (void)copyFrom:(vMAT_Array *)matrix;
{
    SEL copyCmd = [vMAT_Array copyCmdForType:self.type fromType:matrix.type];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:copyCmd withObject:matrix];
#pragma clang diagnostic pop
}

namespace vMAT {
    
    NSString *
    genericDescription(vMAT_MIType type)
    {
        return vMAT_MITypeDescription(type);
    }
    
    NSString *
    genericDescription(vMAT_MXClass mxClass)
    {
        return vMAT_MXClassDescription(mxClass);
    }
    
    template <typename A, typename B>
    SEL
    genericCmd(NSString * format, A a, B b)
    {
        NSString * descriptions = [genericDescription(a) stringByAppendingString:genericDescription(b)];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:NULL];
        NSArray * matches = [regex matchesInString:descriptions options:0 range:NSMakeRange(0, [descriptions length])];
        NSCAssert([matches count] == 2, @"Couldn't make genericCmd from %@", descriptions);
        NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
        NSRange r2 = [[matches objectAtIndex:1] rangeAtIndex:1];
        NSString * copyCmdString = [NSString stringWithFormat:format,
                                    [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
        return NSSelectorFromString(copyCmdString);
    }
    
    // Explicit template expansion. (I suppose it beats the old template code bloat.)
    template SEL genericCmd(NSString * format, vMAT_MIType type, vMAT_MXClass mxClass);
    
    double   DOUBLE;
    float    SINGLE;
    int8_t   INT8;
    uint8_t  UINT8;
    int16_t  INT16;
    uint16_t UINT16;
    int32_t  INT32;
    uint32_t UINT32;
    int64_t  INT64;
    uint64_t UINT64;

}

namespace {
    
    using vMAT::DOUBLE;
    using vMAT::SINGLE;
    using vMAT::INT8;
    using vMAT::UINT8;
    using vMAT::INT16;
    using vMAT::UINT16;
    using vMAT::INT32;
    using vMAT::UINT32;
    using vMAT::INT64;
    using vMAT::UINT64;

    template <typename TypeA, typename TypeB>
    void
    copyFrom(vMAT_Array * self, vMAT_Array * matrix, TypeA _A, TypeB _B)
    {
        TypeA * A = (TypeA *)self.data.mutableBytes;
        const TypeB * B = (const TypeB *)matrix.data.bytes;
        long lenA = vMAT_Size_prod(self.size);
        long lenB = vMAT_Size_prod(matrix.size);
        SEL _cmd = @selector(copyFrom:);
        NSParameterAssert(lenA == lenB);
        for (int i = 0;
             i < lenA;
             i++) {
            A[i] = B[i];
        }
    }

}

- (void)_copy_miDOUBLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, DOUBLE);
}

- (void)_copy_miDOUBLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, SINGLE);
}

- (void)_copy_miDOUBLE_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, INT8);
}

- (void)_copy_miDOUBLE_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, UINT8);
}

- (void)_copy_miDOUBLE_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, INT16);
}

- (void)_copy_miDOUBLE_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, UINT16);
}

- (void)_copy_miDOUBLE_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, INT32);
}

- (void)_copy_miDOUBLE_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, UINT32);
}

- (void)_copy_miDOUBLE_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, INT64);
}

- (void)_copy_miDOUBLE_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, UINT64);
}

- (void)_copy_miSINGLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, DOUBLE);
}

- (void)_copy_miSINGLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, SINGLE);
}

- (void)_copy_miSINGLE_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, INT8);
}

- (void)_copy_miSINGLE_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, UINT8);
}

- (void)_copy_miSINGLE_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, INT16);
}

- (void)_copy_miSINGLE_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, UINT16);
}

- (void)_copy_miSINGLE_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, INT32);
}

- (void)_copy_miSINGLE_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, UINT32);
}

- (void)_copy_miSINGLE_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, INT64);
}

- (void)_copy_miSINGLE_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, UINT64);
}

@end
