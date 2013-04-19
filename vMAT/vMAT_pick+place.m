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
                         vMAT_Size dims,
                         NSArray * args)
{
    id argM = [args objectAtIndex:0];
    if (argM == [NSNull null]) {
        vMAT_Array * matM = vMAT_idxstep(0, dims[0], 1);
        flexidxs->M = (int32_t *)matM.data.bytes;
        flexidxs->lenM = vMAT_numel(matM);
        *matMOut = matM;
    }
    else if ([argM respondsToSelector:@selector(intValue)]) {
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
    else if ([argM respondsToSelector:@selector(objectAtIndex:)]) {
        vMAT_Array * matM = vMAT_coerce(argM, @[ @"int32" ]);
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
    initFlexIndexesFromArray(&flexidxs, &matM, &matN, matrix.size, indexes);
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
vMAT_place(vMAT_Array * matrix,
           NSArray * indexes,
           id source)
{
    vMAT_FlexIndexes flexidxs = { };
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    initFlexIndexesFromArray(&flexidxs, &matM, &matN, matrix.size, indexes);
    return vMAT_place_idxvs(matrix, flexidxs.M, flexidxs.lenM, flexidxs.N, flexidxs.lenN, source);
}

vMAT_Array *
vMAT_place_idxvs(vMAT_Array * matrix,
                 int32_t * M,
                 vDSP_Length lenM,
                 int32_t * N,
                 vDSP_Length lenN,
                 id source)
{
    vMAT_Array * array = matrix; // Don't make a new matrix; too much code assumes otherwise!
    long lenB = 0;
    
    NSNumber * (^nextElement)() = nil;
    
    if ([source respondsToSelector:@selector(doubleValue)]) {
        nextElement = ^ { return source; };
    }
    else if ([source respondsToSelector:@selector(elementAtIndex:)]) {
        vMAT_Array * matB = source;
        lenB = [matB length];
        if (lenB != 1) {         // A 1x1 matrix is treated like a scalar
            if (matB.size[0] != lenM ||
                matB.size[1] != lenN) {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                        reason:[NSString stringWithFormat:@"Dimension mismatch in %s", __func__]
                                             userInfo:@{ @"matrix": matrix, @"source": source }];
            }
        }
        __block vMAT_Index idxs = vMAT_MakeIndex(0);
        nextElement = ^ {
            NSNumber * elt = [matB elementAtIndex:idxs];
            if (++idxs.d[0] >= lenB) idxs.d[0] = 0;
            return elt;
        };
    }
    else if ([source respondsToSelector:@selector(objectAtIndex:)]) {
        NSArray * arrB = source;
        lenB = [arrB count];
        __block NSUInteger idx = 0;
        nextElement = ^ {
            NSNumber * elt = [arrB objectAtIndex:idx];
            if (++idx >= lenB) idx = 0;
            return elt;
        };
    }
    for (vDSP_Length idxN = 0;
         idxN < lenN;
         idxN++) {
        for (vDSP_Length idxM = 0;
             idxM < lenM;
             idxM++) {
            [array setElement:nextElement()
                      atIndex:vMAT_MakeIndex(M[idxM], N[idxN])];
        }
    }
    return array;
}
