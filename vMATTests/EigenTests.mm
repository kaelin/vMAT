//
//  EigenTests.m
//  vMAT
//
//  Created by Kaelin Colclasure on 4/16/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "EigenTests.h"

#import "vMAT.h"


namespace {
    
    using namespace Eigen;
    using namespace vMAT;
    
}

@implementation EigenTests

- (void)test_vMAT_pick_logical;
{
    vMAT_Array * matM = vMAT_cast(VectorXd::LinSpaced(40, 1.0, 40.0).eval());
    [matM reshape:vMAT_MakeSize(5, 8)];
    Mat<double> M = matM;
    Array<bool, Dynamic, Dynamic> sel = M.unaryExpr([](double elt) { return (int)elt % 3 == 0; }).cast<bool>();
    vMAT_Array * vecN = vMAT_pick(matM, vMAT_cast(sel));
    NSLog(@"%@", vecN.dump);
    vMAT_Array * vecNv = vMAT_cast(VectorXd::LinSpaced(13, 3.0, 39.0).eval());
    STAssertEqualObjects(vecN, vecNv, @"Logical indexing broken");
}

@end
