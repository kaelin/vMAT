//
//  vMAT_pick+place.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/16/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"


typedef struct vMAT_FlexIndexes {
    int32_t scalarIndex[2];
    int32_t * M;
    vDSP_Length lenM;
    int32_t * N;
    vDSP_Length lenN;
} vMAT_FlexIndexes;

static void
initFlexIndexesFromArgs(vMAT_FlexIndexes * flexidxs,
                        vMAT_Array ** matMOut,
                        vMAT_Array ** matNOut,
                        va_list args)
{
    long argM = va_arg(args, long);
    long argN = -1;
    if (argM >= 0 && argM < 0x100) {
        flexidxs->scalarIndex[0] = (int32_t)argM;
        flexidxs->M = &flexidxs->scalarIndex[0];
        flexidxs->lenM = 1;
        argN = va_arg(args, long);
    }
    else {
        vMAT_Array * matM = (__bridge vMAT_Array *)(void *)argM;
        if (matM.isLogical) {
            matM = vMAT_find(matM, nil);
            argN = 0;
        }
        else {
            matM = vMAT_coerce(matM, @[ @"int32" ]);
            argN = va_arg(args, long);
        }
        flexidxs->M = (int32_t *)matM.data.bytes;
        flexidxs->lenM = vMAT_numel(matM);
        *matMOut = matM;
    }
    if (argN >= 0 && argN < 0x100) {
        flexidxs->scalarIndex[1] = (int32_t)argN;
        flexidxs->N = &flexidxs->scalarIndex[1];
        flexidxs->lenN = 1;
    }
    else {
        vMAT_Array * matN = vMAT_coerce((__bridge vMAT_Array *)(void *)argN, @[ @"int32" ]);
        flexidxs->N = (int32_t *)matN.data.bytes;
        flexidxs->lenN = vMAT_numel(matN);
        *matNOut = matN;
    }
}

vMAT_Array *
vMAT_pick(vMAT_Array * matrix,
          ...)
{
    vMAT_FlexIndexes flexidxs = { };
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    va_list args;
    va_start(args, matrix);
    initFlexIndexesFromArgs(&flexidxs, &matM, &matN, args);
    va_end(args);
    return vMAT_pick_idxvs(matrix, flexidxs.M, flexidxs.lenM, flexidxs.N, flexidxs.lenN);
}

vMAT_Array *
vMAT_pick_idxvs(vMAT_Array * matrix,
                int32_t * M,
                vDSP_Length lenM,
                int32_t * N,
                vDSP_Length lenN)
{
    vMAT_Array * array = vMAT_zeros(vMAT_MakeSize((int32_t)lenM, (int32_t)lenN), @[ @"like:", matrix ]);
    for (vDSP_Length idxN = 0;
         idxN < lenN;
         idxN++) {
        for (vDSP_Length idxM = 0;
             idxM < lenM;
             idxM++) {
            [array setElement:[matrix elementAtIndex:vMAT_MakeIndex(M[idxM], N[idxN])]
                      atIndex:vMAT_MakeIndex((int32_t)idxM, (int32_t)idxN)];
        }
    }
    return array;
}

vMAT_Array *
vMAT_place(vMAT_Array * matrixA,
           vMAT_Array * matrixB,
           ...)
{
    vMAT_FlexIndexes flexidxs = { };
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    va_list args;
    va_start(args, matrixB);
    initFlexIndexesFromArgs(&flexidxs, &matM, &matN, args);
    va_end(args);
    
    return nil;
}
