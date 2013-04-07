//
//  vMAT_inconsistent.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/7/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <valarray>
#import <vector>

namespace {
    
    using namespace std;
    
    valarray<double>
    traceTree(vMAT_Array * matZ, int k, unsigned int depth)
    {
        valarray<double> s((size_t)4);
        size_t m = matZ.size[1] + 1;
        vector<int> klist(m, 0);
        klist[0] = k;
        vector<int> dlist(1, depth);
        int topk = 0;
        int currk = 0;
        while (currk <= topk) {
            k = klist[currk];
            depth = dlist[currk];
            s[0];
        }
        return s;
    }
    
}


vMAT_Array *
vMAT_inconsistent(vMAT_Array * matZ,
                  unsigned int depth)
{
    if (depth == 0) depth = 2;
    int32_t n = matZ.size[1];
    vMAT_Array * matY = vMAT_zeros(vMAT_MakeSize(4, n), nil);
    
    return matY;
}
