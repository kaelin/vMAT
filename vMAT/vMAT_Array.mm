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

- (void)copyFrom:(vMAT_Array *)matrix;
{
    SEL copyCmd = [vMAT_Array copyCmdForType:self.type fromType:matrix.type];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:copyCmd withObject:matrix];
#pragma clang diagnostic pop
}

static float SINGLE;
static double DOUBLE;

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

- (void)_copy_miDOUBLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, DOUBLE);
}

- (void)_copy_miDOUBLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, DOUBLE, SINGLE);
}

- (void)_copy_miSINGLE_from_miDOUBLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, DOUBLE);
}

- (void)_copy_miSINGLE_from_miSINGLE:(vMAT_Array *)matrix;
{
    copyFrom(self, matrix, SINGLE, SINGLE);
}

@end
