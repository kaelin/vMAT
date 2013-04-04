//
//  vMAT.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/24/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import "vMAT_StreamDelegate.h"


NSString *
vMAT_StringFromSize(vMAT_Size size)
{
    NSMutableString * string = [NSMutableString stringWithString:@"["];
    char * sep = "";
    for (int i = 0;
         i < vMAT_MAXDIMS;
         i++) {
        if (size[i] > 0) [string appendFormat:@"%s%d", sep, size[i]];
        else break;
        sep = " ";
    }
    [string appendString:@"]"];
    return string;
}

vMAT_Array *
vMAT_eye(vMAT_Size mxn)
{
    if (mxn[1] == 0) mxn[1] = mxn[0];
    vMAT_Array * array = [vMAT_Array arrayWithSize:mxn type:miDOUBLE];
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
vMAT_linkage(const float pdistv[],
             vDSP_Length pdistvLength,
             void (^outputBlock)(float output[],
                                 vDSP_Length outputLength,
                                 bool * keepOutput))
{ // TODO: Use pdist output vector
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
    vMAT_MATv5ReadOperation * operation = [[vMAT_MATv5ReadOperation alloc] initWithInputStream:stream];
    vMAT_MATv5ReadOperationDelegate * reader = [[vMAT_MATv5ReadOperationDelegate alloc] initWithReadOperation:operation];
    reader.variableNames = variableNames;
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
    long lenN = ceil(sqrt(lenD));
    long lenY = lenN * (lenN - 1) / 2;
    float * Y = calloc(lenY, sizeof(*Y));
    long idxY = 0;
    for (long n = 0;
         n < lenN;
         n++) {
        for (long m = n + 1;
             m < lenN;
             m++) {
            Y[idxY] = D[n * lenN + m];
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
    NSCAssert(mxnA[0] == mxnB[0], @"Mismatched m dimensions");
    // We need space to store a full distance matrix (D).
    long lenD = mxnA[1] * mxnB[1];
    float * D = calloc(lenD, sizeof(*D));
    long idxD = 0;
    for (long idxB = 0;
         idxB < mxnB[1];
         idxB++) {
        for (long idxA = 0;
             idxA < mxnA[1];
             idxA++) {
            vDSP_distancesq(&sampleA[idxA * mxnA[0]], 1, &sampleB[idxB * mxnB[0]], 1, &D[idxD], mxnA[0]);
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

vMAT_Array *
vMAT_single(vMAT_Array * matrix)
{
    vMAT_Array * array = [vMAT_Array arrayWithSize:matrix.size type:miSINGLE];
    [array copyFrom:matrix];
    return array;
}

void
vMAT_byteswap16(void * vector,
                vDSP_Length vectorLength)
{
    uint16_t * vswap = vector;
    for (long i = 0;
         i < vectorLength;
         i++) {
        vswap[i] = OSSwapConstInt16(vswap[i]);
    }
}

void
vMAT_byteswap32(void * vector,
                vDSP_Length vectorLength)
{
    uint32_t * vswap = vector;
    for (long i = 0;
         i < vectorLength;
         i++) {
        vswap[i] = OSSwapConstInt32(vswap[i]);
    }
}

void
vMAT_byteswap64(void * vector,
                vDSP_Length vectorLength)
{
    uint64_t * vswap = vector;
    for (long i = 0;
         i < vectorLength;
         i++) {
        vswap[i] = OSSwapConstInt64(vswap[i]);
    }
}

NSString * const vMAT_ErrorDomain = @"com.ohmware.vMAT";

NSString *
vMAT_MITypeDescription(vMAT_MIType type)
{
    static NSString * const desc[miRANGE_LIMIT] = {
        nil,
        @"[1]miINT8",
        @"[2]miUINT8",
        @"[3]miINT16",
        @"[4]miUINT16",
        @"[5]miINT32",
        @"[6]miUINT32",
        @"[7]miSINGLE",
        nil,
        @"[9]miDOUBLE",
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
    if (type > 0 && type < miRANGE_LIMIT) return desc[type];
    else return nil;
}

size_t
vMAT_MITypeSizeof(vMAT_MIType type)
{
    static const size_t size[miRANGE_LIMIT] = {
        0,
        sizeof(int8_t),
        sizeof(uint8_t),
        sizeof(int16_t),
        sizeof(uint16_t),
        sizeof(int32_t),
        sizeof(uint32_t),
        sizeof(float),
        0,
        sizeof(double),
        0,
        0,
        sizeof(int64_t),
        sizeof(uint64_t),
        0,
        0,
        sizeof(uint8_t),
        sizeof(uint16_t),
        sizeof(uint32_t),
    };
    if (type > 0 && type < miRANGE_LIMIT) return size[type];
    else return 0;
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
