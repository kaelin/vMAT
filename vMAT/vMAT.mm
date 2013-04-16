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
vMAT_eye(vMAT_Size mxn)
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

vMAT_Array *
vMAT_pick(vMAT_Array * matrix,
          ...)
{
    va_list args;
    va_start(args, matrix);
    long argM = va_arg(args, long);
    long argN = va_arg(args, long);
    va_end(args);
    int32_t indexBuffer[2] = { };
    int32_t * M = NULL;
    int32_t * N = NULL;
    vDSP_Length lenM = 0, lenN = 0;
    vMAT_Array * matM = nil;
    vMAT_Array * matN = nil;
    if (argM >= 0 && argM < 0x100) {
        indexBuffer[0] = (int32_t)argM;
        M = &indexBuffer[0];
        lenM = 1;
    }
    else {
        matM = vMAT_coerce((__bridge vMAT_Array *)(void *)argM, @[ @"int32" ]);
        M = (int32_t *)matM.data.bytes;
        lenM = vMAT_numel(matM);
    }
    if (argN >= 0 && argN < 0x100) {
        indexBuffer[1] = (int32_t)argN;
        N = &indexBuffer[1];
        lenN = 1;
    }
    else {
        matN = vMAT_coerce((__bridge vMAT_Array *)(void *)argN, @[ @"int32" ]);
        N = (int32_t *)matN.data.bytes;
        lenN = vMAT_numel(matN);
    }
    return vMAT_pick_idxvs(matrix, M, lenM, N, lenN);
}

vMAT_Array *
vMAT_pick_idxvs(vMAT_Array * matrix,
                int32_t * M,
                vDSP_Length lenM,
                int32_t * N,
                vDSP_Length lenN)
{
    vMAT_Array * array = vMAT_zeros(vMAT_MakeSize((int32_t)lenM, (int32_t)lenN), @[ @"like:", matrix ]);
    for (vDSP_Length idxN = 0;
         idxN < lenN;
         idxN++) {
        for (vDSP_Length idxM = 0;
             idxM < lenM;
             idxM++) {
            [array setElement:[matrix elementAtIndex:vMAT_MakeIndex(M[idxM], N[idxN])]
                      atIndex:vMAT_MakeIndex((int32_t)idxM, (int32_t)idxN)];
        }
    }
    return array;
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
vMAT_coerce(vMAT_Array * matrix,
            NSArray * options)
{
    vMAT_Array * array = nil;
    vMAT_MIType type = arrayTypeOptions(options);
    if (matrix.type != type) {
        array = [vMAT_Array arrayWithSize:matrix.size type:type];
        [array copyFrom:matrix];
    }
    else array = matrix;
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
