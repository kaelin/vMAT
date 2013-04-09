//
//  vMAT_inconsistent.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <algorithm>
#import <vector>


namespace {
    
    using namespace std;
    using namespace vMAT;
    
    void
    traceTree(Matrix<double> Z, double s[3], int k, unsigned int depth)
    {
        int m = Z.size(1) + 1;
        __block vector<int> klist(m, k);
        __block vector<int> dlist(m, depth);
        __block int topk = 0;
        int currk = 0;
        
        void (^ subtree)(int i) = ^(int i) {
            if (i >= m) {                // If it's not a leaf...
                topk += 1;
                klist[topk] = i - m;
                dlist[topk] = depth - 1;
            }
        };
        
        while (currk <= topk) {
            k = klist[currk];
            depth = dlist[currk];
            s[0] += Z[{2,k}];            // Sum of the edge lengths so far
            s[1] += Z[{2,k}] * Z[{2,k}]; // ... and the sum of the squares
            s[2] += 1;                   // ... and the count of the edges
            if (depth > 1) {
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
    if (depth == 0) depth = 2;
    Matrix<double> Z = vMAT_double(matZ);
    int32_t n = Z.size(1);
    Matrix<double> Y = vMAT_zeros(vMAT_MakeSize(4, n), nil);
    double s[3] = { };
    for (int k = 0;
         k < n;
         k++) {
        traceTree(Z, s, k, depth);
        double mean = s[0] / s[2];       // Compute the average edge length
        double v = (s[1] - (s[0] * s[0]) / s[2]) / (s[2] - (s[2] != 1));
        double std = sqrt(max(0.0, v));  // Standard deviation (avoid roundoff to negative number)
        Y[{0,k}] = mean;
        Y[{1,k}] = std;
        Y[{2,k}] = s[2];                 // Count of the edges
        if (std > 0) {
            Y[{3,k}] = (Z[{2,k}] - mean) / std;
        }
        s[0] = s[1] = s[2] = 0;
    }
    return Y;
}
