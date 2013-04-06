//
//  vMAT.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import "vMAT_StreamDelegate.h"


vMAT_Array *
vMAT_eye(vMAT_Size mxn)
{
    if (mxn[1] == 0) mxn[1] = mxn[0];
    vMAT_Array * array = vMAT_zeros(mxn, nil);
    double * A = array.data.mutableBytes;
    long diag = MIN(mxn[0], mxn[1]);
    for (int n = 0;
         n < diag;
         n++) {
        A[n * mxn[0] + n] = 1;
    }
    return array;
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

void
vMAT_load(NSInputStream * stream,
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
