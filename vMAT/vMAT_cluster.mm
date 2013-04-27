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


#import "clusterOptions.mki"

namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
    template <typename EigenObjectType>
    Array<bool, Dynamic, Dynamic> operator~(EigenObjectType matrix)
    {
        typedef typename EigenObjectType::Scalar Scalar;
        return matrix.unaryExpr([](Scalar elt) { return elt == 0; });
    }
    
    typedef Mat<double, Dynamic, 3> MatZ; // Input is a Mx3 hierarchical cluster tree (after Z gets transposed!)
    typedef Mat<double, Dynamic, 4> MatY; // Result is a (M+1)x4 inconsistancy matrix (after Y gets transposed!)
    typedef Mat<double> MatA;             // Result is (M+1)xN assignment matrix (after Z gets transposed!)
    
//    struct Options {
//        BOOL useCutoff;
//        BOOL useInconsistent;
//        int depth;
//        vector<double> cutoff;
//        vector<int> maxclust;
//    };
    
//    Options
//    clusterOptions(NSArray * options)
//    {
//        Options opts = { YES, YES, 2, { 0.5, 0.75 }, { } };
//        return opts;
//    }
    
    typedef Array<bool, Dynamic, 1> ArrayX1b;
    typedef vMAT::Map<ArrayX1b> MatArrayX1b;
    typedef Mat<double, Dynamic, 1> MatX1d;
    typedef Mat<vMAT_idx_t, Dynamic, 1> MatX1idx;
    
    vMAT_Array *
    checkCut(MatZ Z, double cutoff, VectorXd crit)
    {
        double n = Z.size(0) + 1;
        MatArrayX1b conn = (crit.array() <= cutoff).eval();
        ArrayX1b notLeaf = Z.array().col(0) >= n || Z.array().col(1) >= n;
        MatArrayX1b todo = (conn && notLeaf).eval();
        while(todo.any()) {
            MatX1idx rows = vMAT_find(todo, nil);
            Mat<bool, Dynamic, 2> cdone = vMAT_ones(vMAT_MakeSize(rows.size(), 2), @[ @"logical" ]);
            for (vMAT_idx_t j : { 0, 1 }) { // 0 is left child, 1 is right child
                MatX1d crows = vMAT_pick(Z, @[ rows, vMAT_idxNumber(j) ]);
                ArrayX1b t = (crows.array() > n);
                vMAT_Array * matT = vMAT_cast(t);
                if (t.any()) {
                    MatX1d child = vMAT_pick(crows, @[ matT ]);
                    child.array() -= n;
                    MatArrayX1b childTodo = vMAT_pick(todo, @[ child ]);
                    vMAT_place(cdone, @[ matT, vMAT_idxNumber(j) ], vMAT_cast(~childTodo));
                    MatArrayX1b childConn = vMAT_pick(conn, @[ child ]);
                    MatX1idx tRows = vMAT_pick(rows, @[ matT ]);
                    MatArrayX1b tRowsConn = vMAT_pick(conn, @[ tRows ]);
                    MatArrayX1b update = (tRowsConn && childConn).eval();
                    vMAT_place(conn, @[ tRows ], update);
                }
            }
            MatArrayX1b done = (cdone.col(0).array() && cdone.col(1).array()).eval();
            vMAT_place(todo, @[ vMAT_pick(rows, @[ done ]) ], @NO);
        }
        return conn;
    }
    
    vMAT_Array *
    labelTree(MatZ Z, vMAT_Array * matC)
    {
        vMAT_idx_t n = Z.size(0);
        vMAT_idx_t nleaves = n + 1;
        vMAT_Array * matA = vMAT_zeros(vMAT_MakeSize(nleaves, 1), @[ @"index" ]);
        MatArrayX1b conn = matC;
        MatArrayX1b todo = vMAT_ones(vMAT_MakeSize(n, 1), @[ @"logical" ]);
        vMAT_Array * matCN = vMAT_idxstep(0, 2 * n, 1);
        [matCN reshape:vMAT_MakeSize(n, 2)];
        while(todo.any()) {
            MatArrayX1b work = (todo && ~conn).eval();
            MatX1idx rows = vMAT_find(work, nil);
            if (vMAT_isempty(rows)) break;
            for (vMAT_idx_t j : { 0, 1 }) { // 0 is left child, 1 is right child
                MatX1d children = vMAT_pick(Z, @[ rows, vMAT_idxNumber(j) ]);
                MatArrayX1b leaf = (children.array() < nleaves).eval();
                if (leaf.any()) {
                    vMAT_place(matA, @[ vMAT_pick(children, @[ leaf ]) ],
                               vMAT_pick(matCN, @[ vMAT_pick(rows, @[ leaf ]), vMAT_idxNumber(j) ]));
                }
                MatArrayX1b joint = vMAT_cast(~leaf);
                MatX1d child = vMAT_pick(children, @[ joint ]);
                child.array() -= nleaves;
                vMAT_place(joint, @[ joint ], vMAT_pick(conn, @[ child ]));
                if (joint.any()) {
                    MatX1idx clustnum = vMAT_pick(matCN, @[ vMAT_pick(rows, @[ joint ]), vMAT_idxNumber(j) ]);
                    MatX1d childnum = vMAT_pick(children, @[ joint ]);
                    childnum.array() -= nleaves;
                    vMAT_place(matCN, @[ childnum, @0 ], clustnum);
                    vMAT_place(matCN, @[ childnum, @1 ], clustnum);
                    vMAT_place(conn, @[ childnum ], @NO);
                }
            }
            vMAT_place(todo, @[ rows ], @NO);
        }
        NSArray * result = vMAT_unique(matA, @[ @"-want:", @"[~,~,_]" ]);
        return result[2];
    }
    
}

vMAT_Array *
vMAT_cluster(vMAT_Array * matZ,
             NSArray * options)
{
    WITH_clusterOptions(options, opts);
    MatZ Z = vMAT_double(matZ.mtrans); // Note mtrans!
    vMAT_Array * matA = nil;
    vMAT_idx_t m = Z.size(0) + 1;
    if (opts.useCutoff) {
        vMAT_idx_t n = vMAT_numel(opts.cutoff);
        VectorXd crit(m - 1);
        matA = vMAT_zeros(vMAT_MakeSize(m, n), @[ @"index" ]);
        if (opts.useInconsistent) {
            Mat<vMAT_idx_t> depth = opts.depth;
            MatY Y = vMAT_inconsistent(Z.matA.mtrans, depth[0]).mtrans; // Note double mtrans!
            crit = Y.col(3);
        }
        else {
            crit = Z.col(2);
        }
        vMAT_idx_t idxA = 0;
        MatX1d cutoffv = opts.cutoff;
        for (auto cutoff : cutoffv) {
            vMAT_Array * matC = checkCut(Z, cutoff, crit);
            NSLog(@"%@", matC.dump);
            vMAT_place(matA, @[ vMAT_ALL, vMAT_idxNumber(idxA) ], labelTree(Z, matC));
            ++idxA;
        }
    }
    return matA;
}
