//
//  vMAT_Array+UnaryOps.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_PrivateArray.h"

#import <algorithm>
#import <sstream>
#import <vector>


@implementation vMAT_Array (UnaryOps)

- (NSString *)dump;
{
    return [self description];
}

- (vMAT_Array *)mtrans;
{
    return nil; // Subclass responsibility
}

@end

namespace {
    
    using namespace std;
    using namespace vMAT;
    
    template <typename T>
    struct render {
        NSMutableString * dump;
        const int columns;
        long count;
        render(NSMutableString * dump, int columns) : dump(dump), columns(columns), count(0) { }
        void operator()(T a)
        {
            stringstream out;
            out.width(13);
            out.fill(' ');
            out << a;
            if (++count % columns == 0) out << "\n";
            else out << " ";
            [dump appendFormat:@"%s", out.str().c_str()];
        }
    };
    
    template <typename T>
    NSString *
    dump(NSString * prefix, T * A, vMAT_Size sizeA)
    {
        NSMutableString * dump = [NSMutableString stringWithString:prefix];
        [dump appendString:@" = \n"];
        vector<T> vecA(A, A + vMAT_Size_prod(sizeA));
        render<T> renderer(dump, sizeA[0]);
        for_each(vecA.begin(), vecA.end(), renderer);
        return dump;
    }
    
}

@implementation vMAT_DoubleArray (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (double *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    double * A = (double *)self.data.mutableBytes;
    double * C = (double *)array.data.mutableBytes;
    vDSP_mtransD(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end

@implementation vMAT_SingleArray (UnaryOps)

- (NSString *)dump;
{
    return dump([self description], (float *)self.data.bytes, self.size);
}

- (vMAT_Array *)mtrans;
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:vMAT_MakeSize(self.size[1], self.size[0]) type:self.type];
    float * A = (float *)self.data.mutableBytes;
    float * C = (float *)array.data.mutableBytes;
    vDSP_mtrans(A, 1, C, 1, self.size[0], self.size[1]);
    return array;
}

@end
