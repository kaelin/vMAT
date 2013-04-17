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

- (void)test_vMAT_pick;
{
    Mat<double> I = vMAT_eye(vMAT_MakeSize(10));
    Array<bool, Dynamic, Dynamic> sel = I.array() == 0.0;
    vMAT_Array * matS = vMAT_cast(sel);
    NSLog(@"%@", matS.dump);
}

@end
