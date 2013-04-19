//
//  vMAT.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import "vMAT_StreamDelegate.h"


namespace {
    
    using namespace Eigen;
    using namespace std;
    using namespace vMAT;
    
}

vMAT_Array *
vMAT_eye(vMAT_Size mxn,
         NSArray * options)
{
    if (mxn[1] == 0) mxn[1] = mxn[0];
    vMAT_Array * array = vMAT_zeros(mxn, nil);
    double * A = (double *)array.data.mutableBytes;
    long diag = MIN(mxn[0], mxn[1]);
    for (int n = 0;
         n < diag;
         n++) {
        A[n * mxn[0] + n] = 1;
    }
    return array;
}

void
foreach_index(Matrix<bool, Dynamic, Dynamic> selected, function<void(long, bool &)> lambda)
{
    long end = selected.size();
    bool stop = false;
    for (long idx = 0; !stop && idx < end; idx++) {
        if (selected(idx)) lambda(idx, stop);
    }
}

vMAT_Array *
vMAT_find(vMAT_Array * matrix,
          NSArray * options)
{
    Mat<bool, Dynamic, Dynamic> S = matrix;
    int count = S.cast<int>().sum();
    Mat<int, Dynamic, 1> indexes = vMAT_zeros(vMAT_MakeSize(count, 1), @[ @"int32" ]);
    int idx = 0;
    foreach_index(S, [&indexes, &idx] (int idxS, bool & stop) {
        indexes[idx++] = idxS;
    });
    return indexes;
}

void
vMAT_fread(NSInputStream * stream,
           vMAT_Array * matrix,
           NSDictionary * options,
           void (^asyncOutputBlock)(vMAT_Array * matrix,
                                    NSError * error))
{
    vMAT_StreamDelegate * reader = [[vMAT_StreamDelegate alloc] initWithStream:stream
                                                                        matrix:matrix
                                                                       options:options];
    reader.outputBlock = asyncOutputBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [reader startReading];
    });
}

void
vMAT_fwrite(NSOutputStream * stream,
            vMAT_Array * matrix,
            NSDictionary * options,
            void (^asyncCompletionBlock)(vDSP_Length outputLength,
                                         NSError * error))
{
    vMAT_StreamDelegate * writer = [[vMAT_StreamDelegate alloc] initWithStream:stream
                                                                        matrix:matrix
                                                                       options:options];
    writer.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [writer startWriting];
    });
}

vMAT_Array *
vMAT_idxstep(int32_t start,
             int32_t limit,
             int32_t step)
{
    vMAT_Array * array = vMAT_cast(VectorXi::LinSpaced(limit - start, start, limit - 1).eval());
    return array;
}

NSDictionary *
vMAT_load(NSURL * inputURL,
          NSArray * variableNames,
          NSError ** errorOut)
{
    NSInputStream * stream = [NSInputStream inputStreamWithURL:inputURL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDictionary * ws = nil;
    vMAT_load_async(stream, variableNames, ^(NSDictionary * workspace, NSError * error) {
        ws = workspace;
        if (errorOut != NULL) {
            *errorOut = error;
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return ws;
}

void
vMAT_load_async(NSInputStream * stream,
                NSArray * variableNames,
                void (^asyncCompletionBlock)(NSDictionary * workspace,
                                             NSError * error))
{
    vMAT_MATv5ReadOperation * operation = [[vMAT_MATv5ReadOperation alloc] initWithInputStream:stream];
    vMAT_MATv5ReadOperationDelegate * reader = [[vMAT_MATv5ReadOperationDelegate alloc] initWithReadOperation:operation];
    reader.variableNames = variableNames;
    reader.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [reader start];
    });
}

vMAT_Array *
vMAT_mtrans(vMAT_Array * matrix)
{
    return [matrix mtrans];
}

vDSP_Length
vMAT_numel(vMAT_Array * matrix)
{
    return vMAT_Size_prod(matrix.size);
}

static vMAT_MIType
arrayTypeOptions(NSArray * options)
{
    vMAT_MIType type = miDOUBLE;
    if ([options count] != 0) {
        NSString * spec = [options objectAtIndex:0];
        NSCParameterAssert([spec respondsToSelector:@selector(caseInsensitiveCompare:)]);
        NSComparisonResult cmp = [spec caseInsensitiveCompare:@"like:"];
        if (cmp == 0) {
            NSCParameterAssert([options count] == 2);
            vMAT_Array * like = [options objectAtIndex:1];
            NSCParameterAssert([like respondsToSelector:@selector(type)]);
            type = like.type;
        }
        else type = vMAT_MITypeNamed(spec);
    }
    return type;
}

vMAT_Array *
vMAT_zeros(vMAT_Size size,
           NSArray * options)
{
    vMAT_MIType type = arrayTypeOptions(options);
    vMAT_Array * array = [vMAT_Array arrayWithSize:size type:type];
    return array;
}

#pragma mark - Matrix Type Coercion

vMAT_Array *
vMAT_coerce(id source,
            NSArray * options)
{
    vMAT_Array * array = nil;
    vMAT_MIType type = arrayTypeOptions(options);
    if ([source respondsToSelector:@selector(doubleValue)]) {
        array = [vMAT_Array arrayWithSize:vMAT_MakeSize(1, 1) type:type];
        [array setElement:source
                  atIndex:vMAT_MakeIndex(0, 0)];
    }
    else if ([source respondsToSelector:@selector(elementAtIndex:)]) {
        vMAT_Array * matrix = source;
        if (matrix.type != type) {
            array = [vMAT_Array arrayWithSize:matrix.size type:type];
            [array copyFrom:matrix];
        }
        else array = matrix;
    }
    else if ([source respondsToSelector:@selector(objectAtIndex:)]) {
        array = [vMAT_Array arrayWithSize:vMAT_MakeSize((int32_t)[source count], 1) type:type];
        vMAT_place(array, @[ [NSNull null] ], source);
    }
    return array;
}

vMAT_Array *
vMAT_double(vMAT_Array * matrix)
{
    return vMAT_coerce(matrix, @[ @"double" ]);
}

vMAT_Array *
vMAT_single(vMAT_Array * matrix)
{
    return vMAT_coerce(matrix, @[ @"single" ]);
}
