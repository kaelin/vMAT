//
//  vMAT_MATv5Variable.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/4/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5Variable.h"

#import "vMAT_Private.h"


@implementation vMAT_MATv5NumericArray (LoadFromOperation)

+ (SEL)loadCmdForType:(vMAT_MIType)type
              mxClass:(vMAT_MXClass)mxClass;
{
    const int m = mxRANGE_LIMIT;
    const int n = miRANGE_LIMIT;
    static SEL cache[m * n];
    SEL loadCmd = nil;
    @synchronized ([self class]) {
        loadCmd = cache[mxClass * m + type];
        if (loadCmd == nil) {
            loadCmd = vMAT::genericCmd(@"_load_%@_%@_fromOperation:", type, mxClass);
            cache[mxClass * m + type] = loadCmd;
        }
    }
    return loadCmd;
}

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    [self loadFromOperation:operation
                withMXClass:_mxClass];
}

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation
              withMXClass:(vMAT_MXClass)mxClass;
{
    const int numericClasses = 0b1111111111010000;
    NSAssert(numericClasses & (1 << mxClass), @"%@ is not a numeric class", vMAT_MXClassDescription(mxClass));
    _mxClass = mxClass;
    _array = [vMAT_Array arrayWithSize:self.size
                                  type:vMAT_MXClassType(self.mxClass)];
    __block vMAT_MIType type = miNONE;
    __block uint32_t length = 0;
    [operation readElementType:&type
                        length:&length
                   outputBlock:
     ^ {
         SEL loadCmd = [vMAT_MATv5NumericArray loadCmdForType:type mxClass:_mxClass];
         NSLog(@"Loading %@", self);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
         [self performSelector:loadCmd withObject:operation];
#pragma clang diagnostic pop
     }];
}

static void
vMAT_Size123Iterator(vMAT_Size size,
                     void (^ block)(int32_t n, int32_t o, int32_t p))
{
    int32_t limP = size[3] ? : 1;
    int32_t limO = size[2] ? : 1;
    int32_t limN = size[1] ? : 1;
    for (int32_t p = 0;
         p < limP;
         p++) {
        for (int32_t o = 0;
             o < limO;
             o++) {
            for (int32_t n = 0;
                 n < limN;
                 n++) {
                block(n, o, p);
            }
        }
    }
}

namespace {
    
    using namespace vMAT;
    
    typedef void (* swapFn)(void * vector, vDSP_Length vectorLength);
    
    // Functor used for template arguments.
    template <typename TypeA>
    struct swapbytes {
        swapFn fn;
        
        swapbytes()
        {
            if      (sizeof(TypeA) == 8) fn = vMAT_byteswap64;
            else if (sizeof(TypeA) == 4) fn = vMAT_byteswap32;
            else if (sizeof(TypeA) == 2) fn = vMAT_byteswap16;
            else if (sizeof(TypeA) == 1) fn = NULL;
            else NSCAssert(NO, @"Oops!");
        }
        
        // See <http://stackoverflow.com/questions/15819151/why-does-this-functors-operator-need-the-trailing-const-modifier>.
        void operator()(void * vector, vDSP_Length vectorLength) const
        {
            if (fn != NULL) fn(vector, vectorLength);
        }
    };
    
    template <typename TypeA, typename ClassB>
    void
    loadFromOperation(vMAT_MATv5NumericArray * self,
                      vMAT_MATv5ReadOperation * operation,
                      TypeA a,
                      ClassB b)
    {
        swapbytes<TypeA> SwapA;
        long lenC = self.size[0] * sizeof(TypeA);
        TypeA * C = (TypeA *)malloc(lenC);
        long lenD = vMAT_Size_prod(self.size) * sizeof(ClassB);
        NSCAssert(self.array.data.length == lenD, @"Oops!");
        ClassB * D = (ClassB *)[self.array.data mutableBytes];
        __block long idxD = 0;
        vMAT_Size123Iterator(self.size, ^(int32_t n, int32_t o, int32_t p) {
            [operation readComplete:C
                             length:lenC];
            if (operation.swapBytes) { SwapA((void *)C, lenC / sizeof(TypeA)); }
            for (int m = 0;
                 m < self.size[0];
                 m++) {
                D[idxD] = C[m];
                ++idxD;
            }
        });
        free(C);
    }
    
}

- (void)_load_miDOUBLE_mxDOUBLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    loadFromOperation(self, operation, DOUBLE, DOUBLE);
}

- (void)_load_miSINGLE_mxSINGLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    loadFromOperation(self, operation, SINGLE, SINGLE);
}

- (void)_load_miUINT8_mxDOUBLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    loadFromOperation(self, operation, UINT8, DOUBLE);
}

- (void)_load_miUINT8_mxSINGLE_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    loadFromOperation(self, operation, UINT8, SINGLE);
}

- (void)_load_miUINT8_mxUINT8_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    loadFromOperation(self, operation, UINT8, UINT8);
}

@end
