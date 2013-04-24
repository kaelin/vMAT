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
        for (vMAT_idx_t i = 0;
             i < lenA;
             i++) {
            A[i] = static_cast<TypeA>(B[i]);
        }
    }

}

@end

@implementation vMAT_Array (GeneratedMethods)

// vMATCodeMonkey's work; do not edit by hand!

- (void)_copy_miINT8_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, INT8);
}

- (void)_copy_miINT8_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, UINT8);
}

- (void)_copy_miINT8_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, INT16);
}

- (void)_copy_miINT8_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, UINT16);
}

- (void)_copy_miINT8_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, INT32);
}

- (void)_copy_miINT8_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, UINT32);
}

- (void)_copy_miINT8_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, SINGLE);
}

- (void)_copy_miINT8_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, DOUBLE);
}

- (void)_copy_miINT8_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, INT64);
}

- (void)_copy_miINT8_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT8, UINT64);
}

- (void)_copy_miUINT8_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, INT8);
}

- (void)_copy_miUINT8_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, UINT8);
}

- (void)_copy_miUINT8_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, INT16);
}

- (void)_copy_miUINT8_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, UINT16);
}

- (void)_copy_miUINT8_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, INT32);
}

- (void)_copy_miUINT8_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, UINT32);
}

- (void)_copy_miUINT8_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, SINGLE);
}

- (void)_copy_miUINT8_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, DOUBLE);
}

- (void)_copy_miUINT8_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, INT64);
}

- (void)_copy_miUINT8_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT8, UINT64);
}

- (void)_copy_miINT16_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, INT8);
}

- (void)_copy_miINT16_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, UINT8);
}

- (void)_copy_miINT16_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, INT16);
}

- (void)_copy_miINT16_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, UINT16);
}

- (void)_copy_miINT16_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, INT32);
}

- (void)_copy_miINT16_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, UINT32);
}

- (void)_copy_miINT16_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, SINGLE);
}

- (void)_copy_miINT16_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, DOUBLE);
}

- (void)_copy_miINT16_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, INT64);
}

- (void)_copy_miINT16_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT16, UINT64);
}

- (void)_copy_miUINT16_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, INT8);
}

- (void)_copy_miUINT16_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, UINT8);
}

- (void)_copy_miUINT16_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, INT16);
}

- (void)_copy_miUINT16_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, UINT16);
}

- (void)_copy_miUINT16_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, INT32);
}

- (void)_copy_miUINT16_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, UINT32);
}

- (void)_copy_miUINT16_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, SINGLE);
}

- (void)_copy_miUINT16_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, DOUBLE);
}

- (void)_copy_miUINT16_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, INT64);
}

- (void)_copy_miUINT16_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT16, UINT64);
}

- (void)_copy_miINT32_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, INT8);
}

- (void)_copy_miINT32_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, UINT8);
}

- (void)_copy_miINT32_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, INT16);
}

- (void)_copy_miINT32_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, UINT16);
}

- (void)_copy_miINT32_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, INT32);
}

- (void)_copy_miINT32_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, UINT32);
}

- (void)_copy_miINT32_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, SINGLE);
}

- (void)_copy_miINT32_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, DOUBLE);
}

- (void)_copy_miINT32_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, INT64);
}

- (void)_copy_miINT32_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT32, UINT64);
}

- (void)_copy_miUINT32_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, INT8);
}

- (void)_copy_miUINT32_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, UINT8);
}

- (void)_copy_miUINT32_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, INT16);
}

- (void)_copy_miUINT32_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, UINT16);
}

- (void)_copy_miUINT32_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, INT32);
}

- (void)_copy_miUINT32_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, UINT32);
}

- (void)_copy_miUINT32_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, SINGLE);
}

- (void)_copy_miUINT32_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, DOUBLE);
}

- (void)_copy_miUINT32_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, INT64);
}

- (void)_copy_miUINT32_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT32, UINT64);
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

- (void)_copy_miSINGLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, SINGLE);
}

- (void)_copy_miSINGLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, DOUBLE);
}

- (void)_copy_miSINGLE_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, INT64);
}

- (void)_copy_miSINGLE_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, UINT64);
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

- (void)_copy_miDOUBLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, SINGLE);
}

- (void)_copy_miDOUBLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, DOUBLE);
}

- (void)_copy_miDOUBLE_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, INT64);
}

- (void)_copy_miDOUBLE_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, UINT64);
}

- (void)_copy_miINT64_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, INT8);
}

- (void)_copy_miINT64_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, UINT8);
}

- (void)_copy_miINT64_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, INT16);
}

- (void)_copy_miINT64_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, UINT16);
}

- (void)_copy_miINT64_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, INT32);
}

- (void)_copy_miINT64_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, UINT32);
}

- (void)_copy_miINT64_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, SINGLE);
}

- (void)_copy_miINT64_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, DOUBLE);
}

- (void)_copy_miINT64_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, INT64);
}

- (void)_copy_miINT64_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, INT64, UINT64);
}

- (void)_copy_miUINT64_from_miINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, INT8);
}

- (void)_copy_miUINT64_from_miUINT8:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, UINT8);
}

- (void)_copy_miUINT64_from_miINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, INT16);
}

- (void)_copy_miUINT64_from_miUINT16:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, UINT16);
}

- (void)_copy_miUINT64_from_miINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, INT32);
}

- (void)_copy_miUINT64_from_miUINT32:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, UINT32);
}

- (void)_copy_miUINT64_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, SINGLE);
}

- (void)_copy_miUINT64_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, DOUBLE);
}

- (void)_copy_miUINT64_from_miINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, INT64);
}

- (void)_copy_miUINT64_from_miUINT64:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, UINT64, UINT64);
}

@end
