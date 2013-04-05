//
//  vMAT_Array+Transpose.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Array.h"


@implementation vMAT_Array (Transpose)

+ (SEL)mtransCmdForType:(vMAT_MIType)type;
{
    const int m = miRANGE_LIMIT;
    static SEL cache[m];
    SEL mtransCmd = nil;
    @synchronized (self) {
        mtransCmd = cache[type];
        if (mtransCmd == nil) {
            mtransCmd = vMAT::genericCmd(@"_mtrans_%@", type);
            cache[type] = mtransCmd;
        }
    }
    return mtransCmd;
}

- (vMAT_Array *)mtrans;
{
    SEL mtransCmd = [vMAT_Array mtransCmdForType:self.type];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:mtransCmd];
#pragma clang diagnostic pop
}

- (vMAT_Array *)_mtrans_miDOUBLE;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    double * A = (double *)self.data.mutableBytes;
    double * C = (double *)array.data.mutableBytes;
    vDSP_mtransD(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

- (vMAT_Array *)_mtrans_miSINGLE;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    float * A = (float *)self.data.mutableBytes;
    float * C = (float *)array.data.mutableBytes;
    vDSP_mtrans(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end
