//
//  vMAT.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"


#import "arrayTypeOptions.mki"

namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
}

vMAT_Array *
vMAT_eye(vMAT_Size mxn,
         NSArray * options)
{
    if (mxn[1] == 0) mxn[1] = mxn[0];
    vMAT_Array * array = vMAT_zeros(mxn, nil);
    double * A = (double *)array.data.mutableBytes;
    long diag = MIN(mxn[0], mxn[1]);
    for (vMAT_idx_t n = 0;
         n < diag;
         n++) {
        A[n * mxn[0] + n] = 1;
    }
    return array;
}

void
foreach_index(Matrix<bool, Dynamic, Dynamic> selected, function<void(long, bool &)> lambda)
{
    long end = selected.size();
    bool stop = false;
    for (long idx = 0; !stop && idx < end; idx++) {
        if (selected(idx)) lambda(idx, stop);
    }
}

vMAT_Array *
vMAT_find(vMAT_Array * matrix,
          NSArray * options)
{
    Mat<bool, Dynamic, Dynamic> S = matrix;
    vMAT_idx_t count = S.cast<vMAT_idx_t>().sum();
    Mat<vMAT_idx_t, Dynamic, 1> indexes = vMAT_zeros(vMAT_MakeSize(count, 1), @[ @"index" ]);
    vMAT_idx_t idx = 0;
    foreach_index(S, [&indexes, &idx] (vMAT_idx_t idxS, bool & stop) {
        indexes[idx++] = idxS;
    });
    return indexes;
}

vMAT_Array *
vMAT_idxstep(vMAT_idx_t start,
             vMAT_idx_t limit,
             vMAT_idx_t step)
{
    vMAT_Array * array = vMAT_cast(Matrix<vMAT_idx_t, Dynamic, 1>::LinSpaced(limit - start, start, limit - 1).eval());
    return array;
}

BOOL
vMAT_isempty(vMAT_Array * matrix)
{
    return vMAT_numel(matrix) == 0;
}

vMAT_Array *
vMAT_mtrans(vMAT_Array * matrix)
{
    return [matrix mtrans];
}

vDSP_Length
vMAT_ndims(vMAT_Array * matrix)
{
    return 2 + (matrix.size[3] > 1 ? 2 : matrix.size[2] > 1);
}

vDSP_Length
vMAT_numel(vMAT_Array * matrix)
{
    return vMAT_Size_prod(matrix.size);
}

vMAT_Array *
vMAT_ones(vMAT_Size size,
          NSArray * options)
{
    WITH_arrayTypeOptions(options, opts);
    vMAT_Array * array = [vMAT_Array arrayWithSize:size type:opts.type];
    vMAT_place(array, @[ vMAT_ALL, vMAT_ALL ], @1);
    return array;
}

vMAT_Array *
vMAT_zeros(vMAT_Size size,
           NSArray * options)
{
    WITH_arrayTypeOptions(options, opts);
    vMAT_Array * array = [vMAT_Array arrayWithSize:size type:opts.type];
    return array;
}

#pragma mark - Matrix Type Coercion

vMAT_Array *
vMAT_coerce(id source,
            NSArray * options)
{
    WITH_arrayTypeOptions(options, opts);
    vMAT_Array * array = nil;
    BOOL copyFlag = [opts.remainingOptions containsObject:@"-copy"];
    NSCParameterAssert(opts.type != miNONE);
    if ([source respondsToSelector:@selector(doubleValue)]) {
        array = [vMAT_Array arrayWithSize:vMAT_MakeSize(1, 1) type:opts.type];
        [array setElement:source
                  atIndex:vMAT_MakeIndex(0, 0)];
    }
    else if ([source respondsToSelector:@selector(elementAtIndex:)]) {
        vMAT_Array * matrix = source;
        if (copyFlag || matrix.type != opts.type) {
            array = [vMAT_Array arrayWithSize:matrix.size type:opts.type];
            [array copyFrom:matrix];
        }
        else array = matrix;
    }
    else if ([source respondsToSelector:@selector(objectAtIndex:)]) {
        array = [vMAT_Array arrayWithSize:vMAT_MakeSize((vMAT_idx_t)[source count], 1) type:opts.type];
        vMAT_place(array, @[ vMAT_ALL ], source);
    }
    return array;
}

#import "namedCoercions.mki"
