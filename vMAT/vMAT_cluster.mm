//
//  vMAT_cluster.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <iostream>
#import <vector>

#import <Eigen/Dense>


namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
    typedef Mat<double, 3, Dynamic> MatZ; // Input is a 3xN hierarchical cluster tree
    typedef Mat<double, 4, Dynamic> MatY; // Result is a 4x(N+1) inconsistancy matrix
    typedef Mat<double, Dynamic, Dynamic> MatA; // Result is Mx(N+1) assignment matrix
    
    struct Options {
        BOOL useCutoff;
        BOOL useInconsistent;
        int depth;
        vector<double> cutoff;
        vector<int> maxclust;
    };
    
    Options
    clusterOptions(NSArray * options)
    {
        Options opts = { YES, YES, 2, { 0.5, 0.75 }, { } };
        return opts;
    }
    
    void
    checkCut(MatZ Z, double cutoff, VectorXd crit)
    {
        double n = Z.size(1); // Indexes are zero-based, so no need to add one
        Array<bool, Dynamic, 1> conn = crit.array() < cutoff;
        Array<bool, Dynamic, 1> notLeaf = Z.array().row(0) > n || Z.array().row(1) > n;
        Array<bool, Dynamic, 1> todo = conn && notLeaf;
        cerr << "todo = " << todo << endl;
        while(todo.any()) {
            Mat<long, Dynamic, 1> rows = vMAT_find(vMAT_cast(todo), nil);
            for (int j : { 0, 1 }) {
                cerr << "j = " << j << endl;
            }
            todo.fill(false);
        }
        
    }
    
}

vMAT_Array *
vMAT_cluster(vMAT_Array * matZ,
             NSArray * options)
{
    Options opts = clusterOptions(options);
    
    MatZ Z = vMAT_double(matZ);
    int n = Z.size(1) + 1;
    if (opts.useCutoff) {
        int m = static_cast<int>(opts.cutoff.size());
        VectorXd crit(n - 1);
        MatA A = vMAT_zeros(vMAT_MakeSize(m, n), nil);
        if (opts.useInconsistent) {
            MatY Y = vMAT_inconsistent(Z, opts.depth);
            crit = Y.row(3);
        }
        else {
            crit = Z.row(2);
        }
        for (auto cutoff : opts.cutoff) {
            checkCut(Z, cutoff, crit);
        }
    }
    return nil;
}
