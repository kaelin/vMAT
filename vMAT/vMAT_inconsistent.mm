//
//  vMAT_inconsistent.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <cmath>
#import <vector>


namespace {
    
    using namespace std;
    using namespace vMAT;
    
    void
    traceTree(Matrix<double> Z, double s[3], int k, unsigned int depth)
    {
        int m = Z.size(1) + 1;
        // See <http://stackoverflow.com/questions/15868193/why-does-using-an-stl-stdvector-as-a-block-variable-cause-memory-corruption>.
        // __block vector<int> klist(m, 0);
        int klist[m]; int * klistPtr = klist;
        klist[0] = k;
        // __block vector<int> dlist(1, depth);
        int dlist[depth]; int * dlistPtr = dlist;
        dlist[0] = depth;
        __block int topk = 0;
        int currk = 0;
        
        void (^ subtree)(int i) = ^(int i) {
            if (i >= m) {                // If it's not a leaf...
                topk += 1;
                klistPtr[topk] = i - m;
                dlistPtr[topk] = depth - 1;
            }
        };
        
        while (currk <= topk) {
            k = klist[currk];
            depth = dlist[currk];
            s[0] += Z[{2,k}];            // Sum of the edge lengths so far
            s[1] += Z[{2,k}] * Z[{2,k}]; // ... and the sum of the squares
            s[2] += 1;                   // ... and the count of the edges
            if (depth > 0) {
                subtree(Z[{0,k}]);       // Consider left subtree
                subtree(Z[{1,k}]);       // Consider right subtree
            }
            currk += 1;
        }
    }
    
}

vMAT_Array *
vMAT_inconsistent(vMAT_Array * matZ,
                  unsigned int depth)
{
    if (depth == 0) depth = 1;
    Matrix<double> Z = vMAT_double(matZ);
    int32_t n = Z.size(1);
    Matrix<double> Y = vMAT_zeros(vMAT_MakeSize(4, n), nil);
    double s[3] = { };
    for (int k = 0;
         k < n;
         k++) {
        traceTree(Z, s, k, depth);
        Y[{0,k}] = s[0] / s[2];          // Compute the average edge length
        double v = (s[1] - (s[0] * s[0]) / s[2]) / (s[2] - (s[2] != 1));
        Y[{1,k}] = sqrt(max(0.0, v));    // Standard deviation (avoid roundoff to negative number)
        Y[{2,k}] = s[2];                 // Count of the edges
        if (Y[{1,k}] > 0) {
            Y[{3,k}] = (Z[{2,k}] - Y[{0,k}]) / Y[{1,k}];
        }
        s[0] = s[1] = s[2] = 0;
    }
    return Y;
}
