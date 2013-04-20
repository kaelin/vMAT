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
    
    typedef Mat<double, Dynamic, 3> MatZ; // Input is a Mx3 hierarchical cluster tree (after Z gets transposed!)
    typedef Mat<double, Dynamic, 4> MatY; // Result is a (M+1)x4 inconsistancy matrix (after Y gets transposed!)
    typedef Mat<double> MatA;             // Result is (M+1)xN assignment matrix (after Z gets transposed!)
    
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
    
    typedef Array<bool, Dynamic, 1> ArrayX1b;
    typedef vMAT::Map<ArrayX1b> MatArrayX1b;
    typedef Mat<double, Dynamic, 1> MatX1d;
    
    vMAT_Array *
    checkCut(MatZ Z, double cutoff, VectorXd crit)
    {
        double n = Z.size(0);               // Indexes are zero-based, so no need to add one
        MatArrayX1b conn = (crit.array() < cutoff).eval();
        ArrayX1b notLeaf = Z.array().col(0) > n || Z.array().col(1) > n;
        MatArrayX1b todo = (conn && notLeaf).eval();
        while(todo.any()) {
            Mat<vMAT_idx_t, Dynamic, 1> rows = vMAT_find(todo.matA, nil);
            Mat<bool, Dynamic, 2> cdone = vMAT_ones(vMAT_MakeSize(rows.size(), 2), @[ @"logical" ]);
            for (vMAT_idx_t j : { 0, 1 }) { // 0 is left child, 1 is right child
                MatX1d crows = vMAT_pick(Z.matA, @[ rows.matA, [NSNumber numberWithLong:j] ]);
                cerr << "crows = " << crows << endl;
                ArrayX1b t = (crows.array() > n);
                vMAT_Array * matT = vMAT_cast(t);
                if (t.any()) {
                    MatX1d child = vMAT_pick(crows.matA, @[ matT ]);
                    child.array() -= n;
                    MatArrayX1b childTodo = vMAT_pick(todo.matA, @[ child.matA ]);
                    MatArrayX1b childNotTodo = childTodo.unaryExpr([](bool elt) { return !elt; }).eval();
                    vMAT_place(cdone.matA, @[ matT, [NSNumber numberWithLong:j] ], childNotTodo.matA);
                    NSLog(@"%@", cdone.matA.dump);
                }
            }
            todo.fill(false);
        }
        return conn;
    }
    
}

vMAT_Array *
vMAT_cluster(vMAT_Array * matZ,
             NSArray * options)
{
    Options opts = clusterOptions(options);
    
    MatZ Z = vMAT_double(matZ.mtrans); // Note mtrans!
    vMAT_idx_t m = Z.size(0) + 1;
    if (opts.useCutoff) {
        vMAT_idx_t n = static_cast<vMAT_idx_t>(opts.cutoff.size());
        VectorXd crit(m - 1);
        MatA A = vMAT_zeros(vMAT_MakeSize(m, n), nil);
        if (opts.useInconsistent) {
            MatY Y = vMAT_inconsistent(Z.matA.mtrans, opts.depth).mtrans; // Note double mtrans!
            crit = Y.col(3);
        }
        else {
            crit = Z.col(2);
        }
        for (auto cutoff : opts.cutoff) {
            vMAT_Array * matC = checkCut(Z, cutoff, crit);
            NSLog(@"%@", matC.dump);
        }
    }
    return nil;
}
