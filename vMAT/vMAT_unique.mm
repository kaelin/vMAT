//
//  vMAT_unique.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/22/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"


namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
    typedef Mat<int64_t> MatSIType;
    typedef Mat<vMAT_idx_t, Dynamic, 1> MatX1idx;

}

// TODO: All types besides signed integers & implement @"-want:" options.

NSArray *
vMAT_unique(vMAT_Array * matrix,
            NSArray * options)
{
    vMAT_Array * matC = vMAT_SUPPRESSED;
    vMAT_Array * matIA = vMAT_SUPPRESSED;
    vMAT_Array * matIC = vMAT_SUPPRESSED;
    MatSIType A = vMAT_int64(matrix);
    sort(A.begin(), A.end());
    NSLog(@"A = %@", A.matA.dump);
    MatSIType::iterator uniqueEnd = unique(A.begin(), A.end());
    vMAT_idx_t lenC = uniqueEnd - A.begin();
    MatSIType C = [vMAT_Array arrayWithSize:vMAT_MakeSize(lenC, 1)
                                       type:A.matA.type
                                       data:[NSMutableData dataWithBytes:A.begin()
                                                                  length:lenC * sizeof(*uniqueEnd)]];
    NSLog(@"C = %@", C.matA.dump);
    MatX1idx IA = vMAT_zeros(C.matsize(), @[ @"index" ]);
    IA.fill(-1);
    [A.matA copyFrom:matrix]; // Restore unsorted matrix data
    vMAT_idx_t idxA = 0;
    for (auto & elt : A) {
        MatSIType::iterator pos = find(C.begin(), C.end(), elt);
        vMAT_idx_t idxC = pos - C.begin();
        if (IA[idxC] == -1) IA[idxC] = idxA;
        elt = idxC;
        ++idxA;
    }
    matC  = vMAT_coerce(C, @[ @"like:", matrix ]);
    matIA = IA;
    matIC = vMAT_coerce(A, @[ @"index" ]);
    return @[ matC, matIA, matIC ];
}
