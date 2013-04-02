//
//  vMAT.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT.h"

#import "vMAT_StreamDelegate.h"

#import <BlocksKit/BlocksKit.h>


void
vMAT_eye(vMAT_Size mxn,
         void (^outputBlock)(float output[],
                             vDSP_Length outputLength,
                             bool * keepOutput))
{
    if (mxn[1] == 0) mxn[1] = mxn[0];
    long lenE = mxn[0] * mxn[1];
    NSCAssert(lenE > 0, @"Invalid size parameter");
    float * E = calloc(lenE, sizeof(*E));
    long diag = MIN(mxn[0], mxn[1]);
    for (int n = 0;
         n < diag;
         n++) {
        E[n * mxn[0] + n] = 1.f;
    }
    bool keepOutput = false;
    outputBlock(E, lenE, &keepOutput);
    if (!keepOutput) {
        free(E);
    }
}

void
vMAT_fread(NSInputStream * stream,
           vDSP_Length rows,
           vDSP_Length cols,
           NSDictionary * options,
           void (^asyncOutputBlock)(float output[],
                                    vDSP_Length outputLength,
                                    NSData * outputData,
                                    NSError * error))
{
    vMAT_StreamDelegate * reader = [[vMAT_StreamDelegate alloc] initWithStream:stream
                                                                        rows:rows
                                                                        cols:cols
                                                                     options:options];
    reader.outputBlock = asyncOutputBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [reader startReading];
    });
}

void
vMAT_fwrite(NSOutputStream * stream,
            const float matrix[],
            vDSP_Length rows,
            vDSP_Length cols,
            NSDictionary * options,
            void (^asyncCompletionBlock)(vDSP_Length outputLength,
                                         NSError * error))
{
    vMAT_StreamDelegate * writer = [[vMAT_StreamDelegate alloc] initWithStream:stream
                                                                          rows:rows
                                                                          cols:cols
                                                                       options:options];
    long lenD = rows * cols * sizeof(*matrix);
    writer.bufferData = [NSMutableData dataWithCapacity:lenD];
    [writer.bufferData setLength:lenD];
    // Matlab reads data in column order, whereas C stores it in row order.
    vDSP_mtrans((float *)matrix, 1, [writer.bufferData mutableBytes], 1, cols, rows);
    writer.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [writer startWriting];
    });
}

void
vMAT_linkage(const float pdistv[],
             vDSP_Length pdistvLength,
             void (^outputBlock)(float output[],
                                 vDSP_Length outputLength,
                                 bool * keepOutput))
{
    long n = ceil(sqrt(pdistvLength));
    long idx;
    // First we need to reduce distanceMatrix to a vector (Y).
    // (The order is the same as Matlab's pdist results.)
    long lenY = n * (n - 1) / 2;
    float * Y = calloc(lenY, sizeof(*Y));
    // We also need a vector of indexes for keeping track of the cluster assignments (R).
    long * R = calloc(n, sizeof(*R));
    idx = 0;
    for (long row = 0;
         row < n;
         row++) {
        for (long col = row + 1;
             col < n;
             col++) {
            Y[idx] = pdistv[row * n + col];
            ++idx;
        }
        R[row] = row;
    }
    // Now build the cluster tree in an (n-1)x3 matrix (Z).
    long lenZ = 3 * (n - 1);
    float * Z = calloc(lenZ, sizeof(*Z));
    @autoreleasepool {
        NSMutableIndexSet * I1 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I2 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I3 = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * U = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * I = [NSMutableIndexSet indexSet];
        NSMutableIndexSet * J = [NSMutableIndexSet indexSet];
        long m = n;
        float fm = m;
        for (idx = 0;  // row of Z we are updating
             idx < (n - 1);
             idx++) {
            float minDist = NAN;
            vDSP_Length minIdx = -1;
            vDSP_minvi(Y, 1, &minDist, &minIdx, lenY);
            // Calculate indexes of clusters to merge into a new cluster (i and j).
            float fk = minIdx + 1;
            float fi = floor(fm + 1 / 2.f - sqrtf(powf(fm, 2.f) - fm + 1 / 4.f - 2.f * (fk - 1)));
            long i = lrintf(fi) - 1;
            float fj = fk - (fi - 1) * (fm - fi / 2.f) + fi;
            long j = lrintf(fj) - 1;
            // Update the row of Z with the cluster numbers and the distance between them.
            Z[idx * 3 + 0] = fminf(R[i], R[j]); Z[idx * 3 + 1] = fmaxf(R[i], R[j]); Z[idx * 3 + 2] = minDist;
            // Update Y.
            [I1 removeAllIndexes]; [I2 removeAllIndexes]; [I3 removeAllIndexes];
            [U removeAllIndexes];
            [I removeAllIndexes]; [J removeAllIndexes];
            if (i > 0) [I1 addIndexesInRange:NSMakeRange(0, i)];
            [I2 addIndexesInRange:NSMakeRange(i + 1, j - i - 1)];
            [I3 addIndexesInRange:NSMakeRange(j + 1, m - j - 1)];
            [U addIndexes:I1]; [U addIndexes:I2]; [U addIndexes:I3];
            [I addIndexes:[I1 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fi) - 1;
            }]];
            [I addIndexes:[I2 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fi * (fm - (fi + 1) / 2.f) - fm + findex) - 1;
            }]];
            [I addIndexes:[I3 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fi * (fm - (fi + 1) / 2.f) - fm + findex) - 1;
            }]];
            [J addIndexes:[I1 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fj) - 1;
            }]];
            [J addIndexes:[I2 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (findex * (fm - (findex + 1) / 2.f) - fm + fj) - 1;
            }]];
            [J addIndexes:[I3 map:^NSUInteger(NSUInteger index) {
                const float findex = index + 1;
                return (fj * (fm - (fj + 1) / 2.f) - fm + findex) - 1;
            }]];
            __block NSUInteger idxJ = [J firstIndex];
            [I enumerateIndexesUsingBlock:^(NSUInteger idxI,
                                            BOOL * stop) {
                Y[idxI] = fminf(Y[idxI], Y[idxJ]);
                idxJ = [J indexGreaterThanIndex:idxJ];
            }];
            [J addIndex:(fi * (m - (fi + 1) / 2) - m + fj) - 1];
            long idxY = 0;
            for (long col = 0;
                 col < lenY;
                 col++) {
                if ([J containsIndex:col]) continue;
                Y[idxY] = Y[col];
                ++idxY;
            }
            lenY = idxY;
            --m; fm = m;
            R[i] = n + idx;
            for (long idxR = j;
                 idxR < n - 1;
                 idxR++) {
                R[idxR] = R[idxR + 1];
            }
        }
    }
    free(Y);
    free(R);
    bool keepOutput = false;
    outputBlock(Z, lenZ, &keepOutput);
    if (!keepOutput) {
        free(Z);
    }
}

void
vMAT_load(NSInputStream * stream,
          NSArray * variableNames,
          void (^asyncCompletionBlock)(NSDictionary * workspace,
                                       NSError * error))
{
    NSCAssert([variableNames isEqual:@[]], @"Actually loading something is not yet implemented!!!");
    vMAT_MATv5ReadOperation * operation = [[vMAT_MATv5ReadOperation alloc] initWithInputStream:stream];
    vMAT_MATv5ReadOperationDelegate * reader = [[vMAT_MATv5ReadOperationDelegate alloc] initWithReadOperation:operation];
    reader.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [reader start];
    });
}

void
vMAT_pdist(const float sample[],
           vMAT_Size mxn,
           void (^outputBlock)(float output[],
                               vDSP_Length outputLength,
                               bool * keepOutput))
{
    __block float * D = NULL;
    __block long lenD = 0;
    vMAT_pdist2(sample, mxn, sample, mxn, ^(float * output,
                                            vDSP_Length outputLength,
                                            bool * keepOutput) {
        D = output;
        lenD = outputLength;
        *keepOutput = true;
    });
    // Now reduce the full distance matrix to a vector of lengths (Y).
    // (The order is the same as Matlab's pdist results.)
    long n = ceil(sqrt(lenD));
    long lenY = n;
    float * Y = calloc(lenY, sizeof(*Y));
    long idxY = 0;
    for (long row = 0;
         row < n;
         row++) {
        for (long col = row + 1;
             col < n;
             col++) {
            Y[idxY] = D[row * n + col];
            ++idxY;
        }
    }
    free(D);
    bool keepOutput = false;
    outputBlock(Y, lenY, &keepOutput);
    if (!keepOutput) {
        free(Y);
    }
}

void
vMAT_pdist2(const float sampleA[],
            vMAT_Size mxnA,
            const float sampleB[],
            vMAT_Size mxnB,
            void (^outputBlock)(float output[],
                                vDSP_Length outputLength,
                                bool * keepOutput))
{
    NSCAssert(mxnA[1] == mxnB[1], @"Mismatched n dimensions");
    // We need space to store a full distance matrix (D).
    long lenD = mxnA[0] * mxnB[0];
    float * D = calloc(lenD, sizeof(*D));
    long idxD = 0;
    for (long idxA = 0;
         idxA < mxnA[0];
         idxA++) {
        for (long idxB = 0;
             idxB < mxnB[0];
             idxB++) {
            vDSP_distancesq(&sampleA[idxA], mxnA[0], &sampleB[idxB], mxnB[0], &D[idxD], mxnA[1]);
            D[idxD] = sqrtf(D[idxD]);
            ++idxD;
        }
    }
    bool keepOutput = false;
    outputBlock(D, lenD, &keepOutput);
    if (!keepOutput) {
        free(D);
    }
}

void
vMAT_swapbytes(void * vector32,
               vDSP_Length vectorLength)
{
    uint32_t * vswap = vector32;
    for (long i = 0;
         i < vectorLength;
         i++) {
        vswap[i] = OSSwapConstInt32(vswap[i]);
    }
}

NSString * const vMAT_ErrorDomain = @"com.ohmware.vMAT";

NSString *
vMAT_MITypeDescription(vMAT_MIType type)
{
    static NSString * const desc[] = {
        nil,
        @"[1]miINT8",
        @"[2]miUINT8",
        @"[3]miINT16",
        @"[4]miUINT16",
        @"[5]miINT32",
        @"[6]miUINT32",
        @"[7]miSINGLE",
        nil,
        @"[9]miDOUBLE9",
        nil,
        nil,
        @"[12]miINT64",
        @"[13]miUINT64",
        @"[14]miMATRIX",
        @"[15]miCOMPRESSED",
        @"[16]miUTF8",
        @"[17]miUTF16",
        @"[18]miUTF32",
    };
    if (type > 0 && type < 19) return desc[type];
    else return nil;
}

NSString *
vMAT_MXClassDescription(vMAT_MXClass class)
{
    static NSString * const desc[] = {
        nil,
        @"[1]mxCELL_CLASS",
        @"[2]mxSTRUCT_CLASS",
        @"[3]mxOBJECT_CLASS",
        @"[4]mxCHAR_CLASS",
        @"[5]mxSPARSE_CLASS",
        @"[6]mxDOUBLE_CLASS",
        @"[7]mxSINGLE_CLASS",
        @"[8]mxINT8_CLASS",
        @"[9]mxUINT8_CLASS",
        @"[10]mxINT16_CLASS",
        @"[11]mxUINT16_CLASS",
        @"[12]mxINT32_CLASS",
        @"[13]mxUINT32_CLASS",
        @"[14]mxINT64_CLASS",
        @"[15]mxUINT64_CLASS",
    };
    if (class > 0 && class < 16) return desc[class];
    else return nil;
}
