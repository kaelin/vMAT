//
//  vMAT_pdist.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"


vMAT_Array *
vMAT_pdist(vMAT_Array * sample)
{
    vMAT_Array * matD = vMAT_pdist2(sample, sample);
    // Now reduce the full distance matrix to a vector of lengths (Y).
    // (The order is the same as Matlab's pdist results.)
    const float * D = matD.data.bytes;
    long lenN = matD.size[0];
    long lenY = lenN * (lenN - 1) / 2;
    vMAT_Array * matY = [vMAT_Array arrayWithSize:vMAT_MakeSize((int32_t)lenY, 1) type:miSINGLE];
    float * Y = matY.data.mutableBytes;
    long idxY = 0;
    for (long n = 0;
         n < lenN;
         n++) {
        for (long m = n + 1;
             m < lenN;
             m++) {
            Y[idxY] = D[n * lenN + m];
            ++idxY;
        }
    }
    return matY;
}

vMAT_Array *
vMAT_pdist2(vMAT_Array * sampleA,
            vMAT_Array * sampleB)
{
    long mvars = sampleA.size[0];
    NSCParameterAssert(sampleB.size[0] == mvars);
    vMAT_Array * matD = [vMAT_Array arrayWithSize:vMAT_MakeSize(sampleB.size[1], sampleA.size[1])
                                             type:miSINGLE];
    const float * A = sampleA.data.bytes;
    const float * B = sampleB.data.bytes;
    float * D = matD.data.mutableBytes;
    long idxD = 0;
    for (long idxB = 0;
         idxB < sampleB.size[1];
         idxB++) {
        for (long idxA = 0;
             idxA < sampleA.size[1];
             idxA++) {
            vDSP_distancesq(&A[idxA * mvars], 1, &B[idxB * mvars], 1, &D[idxD], mvars);
            D[idxD] = sqrtf(D[idxD]);
            ++idxD;
        }
    }
    return matD;
}
