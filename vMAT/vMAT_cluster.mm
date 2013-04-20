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
    typedef Mat<double> MatA;             // Result is Mx(N+1) assignment matrix
    
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
    
    vMAT_Array *
    checkCut(MatZ Z, double cutoff, VectorXd crit)
    {
        double n = Z.size(1);               // Indexes are zero-based, so no need to add one
        vMAT::Map<Array<bool, Dynamic, 1>> conn = (crit.array() < cutoff).eval();
        Array<bool, Dynamic, 1> notLeaf = Z.array().row(0) > n || Z.array().row(1) > n;
        vMAT::Map<Array<bool, Dynamic, 1>> todo = (conn && notLeaf).eval();
        while(todo.any()) {
            Mat<vMAT_idx_t, Dynamic, 1> rows = vMAT_find(todo.matA, nil);
            Mat<bool, Dynamic, 2> cdone = vMAT_ones(vMAT_MakeSize(rows.size(), 2), @[ @"logical" ]);
            for (vMAT_idx_t j : { 0, 1 }) { // 0 is left child, 1 is right child
                Mat<double, Dynamic, 1> crows = vMAT_pick(Z.matA, @[ [NSNumber numberWithLong:j], rows.matA ]).mtrans;
                cerr << "crows = " << crows << endl;
                Array<bool, Dynamic, 1> t = (crows.array() > n);
                vMAT_Array * matT = vMAT_cast(t);
                if (t.any()) {
                    Mat<double, Dynamic, 1> child = vMAT_pick(crows.matA, @[ matT ]);
                    child.array() -= n;
                    vMAT::Map<Array<bool, Dynamic, 1>> childTodo = vMAT_pick(todo.matA, @[ child.matA ]);
                    vMAT::Map<Array<bool, Dynamic, 1>> childNotTodo = childTodo.unaryExpr([](bool elt) { return !elt; }).eval();
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
    
    MatZ Z = vMAT_double(matZ);
    vMAT_idx_t n = Z.size(1) + 1;
    if (opts.useCutoff) {
        vMAT_idx_t m = static_cast<vMAT_idx_t>(opts.cutoff.size());
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
            vMAT_Array * matC = checkCut(Z, cutoff, crit);
            NSLog(@"%@", matC.dump);
        }
    }
    return nil;
}
