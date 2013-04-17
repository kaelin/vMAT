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
initFlexIndexesFromArray(vMAT_FlexIndexes * flexidxs,
                         vMAT_Array ** matMOut,
                         vMAT_Array ** matNOut,
                         NSArray * args)
{
    id argM = [args objectAtIndex:0];
    if ([argM respondsToSelector:@selector(intValue)]) {
        flexidxs->scalarIndex[0] = [argM intValue];
        flexidxs->M = &flexidxs->scalarIndex[0];
        flexidxs->lenM = 1;
    }
    else if ([argM respondsToSelector:@selector(isLogical)]) {
        vMAT_Array * matM = argM;
        if (matM.isLogical) {
            matM = vMAT_find(matM, nil);
        }
        else {
            matM = vMAT_coerce(matM, @[ @"int32" ]);
        }
        flexidxs->M = (int32_t *)matM.data.bytes;
        flexidxs->lenM = vMAT_numel(matM);
        *matMOut = matM;
    }
    if (args.count >= 2) {
        id argN = [args objectAtIndex:1];
        if ([argN respondsToSelector:@selector(intValue)]) {
            flexidxs->scalarIndex[1] = [argN intValue];
            flexidxs->N = &flexidxs->scalarIndex[1];
            flexidxs->lenN = 1;
        }
        else if ([argN respondsToSelector:@selector(isLogical)]) {
            vMAT_Array * matN = argN;
            if (matN.isLogical) {
                matN = vMAT_find(matN, nil);
            }
            else {
                matN = vMAT_coerce(matN, @[ @"int32" ]);
            }
            flexidxs->N = (int32_t *)matN.data.bytes;
            flexidxs->lenN = vMAT_numel(matN);
            *matNOut = matN;
        }
    }
    else {
        flexidxs->scalarIndex[1] = 0;
        flexidxs->N = &flexidxs->scalarIndex[1];
        flexidxs->lenN = 1;
    }
}

vMAT_Array *
vMAT_pick(vMAT_Array * matrix,
          NSArray * indexes)
{
    vMAT_FlexIndexes flexidxs = { };
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    initFlexIndexesFromArray(&flexidxs, &matM, &matN, indexes);
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
           NSArray * indexes,
           vMAT_Array * matrixB)
{
    vMAT_FlexIndexes flexidxs = { };
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    initFlexIndexesFromArray(&flexidxs, &matM, &matN, indexes);
    
    return nil;
}
