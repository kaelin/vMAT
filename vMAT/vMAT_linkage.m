//
//  vMAT_linkage.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"


vMAT_Array *
vMAT_linkage(vMAT_Array * matY)
{
    NSCParameterAssert(matY.size[1] == 1);
    NSCParameterAssert(matY.type == miSINGLE);
    // We will be updating the contents of Y so make our own mutable copy of matY first.
    matY = [vMAT_Array arrayWithSize:matY.size type:matY.type data:matY.data];
    long lenY = matY.size[0];
    long n = ceil(sqrt(2.0 * lenY));
    // We need a vector of indexes for keeping track of the cluster assignments (R).
    long * R = calloc(n, sizeof(*R));
    for (long idxN = 0;
         idxN < n;
         idxN++) {
        R[idxN] = idxN;
    }
    // Now build the cluster tree in an 3x(n-1) matrix (Z).
    vMAT_Array * matZ = [vMAT_Array arrayWithSize:vMAT_MakeSize(3, (vMAT_idx_t)n - 1) type:miSINGLE];
    float * Y = matY.data.mutableBytes;
    float * Z = matZ.data.mutableBytes;
    @autoreleasepool {
        NSMutableIndexSet * I1 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I2 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I3 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * U = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * J = [NSMutableIndexSet indexSet];
        long m = n;
        float fm = m;
        for (long idxZ = 0;
             idxZ < (n - 1);
             idxZ++) {
            float minDist = NAN;
            vDSP_Length minIdx = -1;
            vDSP_minvi(Y, 1, &minDist, &minIdx, lenY);
            // Calculate indexes of clusters to merge into a new cluster (i and j).
            float fk = minIdx + 1;
            float fi = floor(fm + 1 / 2.f - sqrtf(powf(fm, 2.f) - fm + 1 / 4.f - 2.f * (fk - 1)));
            long i = lrintf(fi) - 1;
            float fj = fk - (fi - 1) * (fm - fi / 2.f) + fi;
            long j = lrintf(fj) - 1;
            // Update the row of Z with the cluster numbers and the distance between them.
            Z[idxZ * 3 + 0] = fminf(R[i], R[j]); Z[idxZ * 3 + 1] = fmaxf(R[i], R[j]); Z[idxZ * 3 + 2] = minDist;
            // Update Y.
            [I1 removeAllIndexes]; [I2 removeAllIndexes]; [I3 removeAllIndexes];
            [U removeAllIndexes];
            [I removeAllIndexes]; [J removeAllIndexes];
            if (i > 0) [I1 addIndexesInRange:NSMakeRange(0, i)];
            [I2 addIndexesInRange:NSMakeRange(i + 1, j - i - 1)];
            [I3 addIndexesInRange:NSMakeRange(j + 1, m - j - 1)];
            [U addIndexes:I1]; [U addIndexes:I2]; [U addIndexes:I3];
            [I addIndexes:[I1 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fi) - 1;
            }]];
            [I addIndexes:[I2 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fi * (fm - (fi + 1) / 2.f) - fm + findex) - 1;
            }]];
            [I addIndexes:[I3 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fi * (fm - (fi + 1) / 2.f) - fm + findex) - 1;
            }]];
            [J addIndexes:[I1 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fj) - 1;
            }]];
            [J addIndexes:[I2 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fj) - 1;
            }]];
            [J addIndexes:[I3 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fj * (fm - (fj + 1) / 2.f) - fm + findex) - 1;
            }]];
            __block NSUInteger idxJ = [J firstIndex];
            [I enumerateIndexesUsingBlock:^(NSUInteger idxI,
                                            BOOL * stop) {
                Y[idxI] = fminf(Y[idxI], Y[idxJ]);
                idxJ = [J indexGreaterThanIndex:idxJ];
            }];
            [J addIndex:(fi * (m - (fi + 1) / 2) - m + fj) - 1];
            long idxY = 0;
            for (long col = 0;
                 col < lenY;
                 col++) {
                if ([J containsIndex:col]) continue;
                Y[idxY] = Y[col];
                ++idxY;
            }
            lenY = idxY;
            --m; fm = m;
            R[i] = n + idxZ;
            for (long idxR = j;
                 idxR < n - 1;
                 idxR++) {
                R[idxR] = R[idxR + 1];
            }
        }
    }
    free(R);
    return matZ;
}
