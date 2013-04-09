//
//  vMAT_cluster.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <vector>


namespace {
    
    using namespace std;
    using namespace vMAT;
    
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
        Options opts = { YES, YES, 2, { 0.5 }, { } };
        return opts;
    }
    
}

vMAT_Array *
vMAT_cluster(vMAT_Array * matZ,
             NSArray * options)
{
    Options opts = clusterOptions(options);
    Matrix<double> Z = vMAT_double(matZ);
    int n = Z.size(1) + 1;
    if (opts.useCutoff) {
        Matrix<double> T = vMAT_zeros(vMAT_MakeSize(static_cast<int>(opts.cutoff.size()), n), nil);
        if (opts.useInconsistent) {
            Matrix<double> Y = vMAT_inconsistent(Z, opts.depth);
        }
    }
    return nil;
}
