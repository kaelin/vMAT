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

namespace {
    
    using namespace vMAT;

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
