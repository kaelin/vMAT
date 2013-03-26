//
//  vMAT_StreamDelegate.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/25/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT.h"


#define vMAT_LIMIT_CONCURRENT_STREAMS (4)

@interface vMAT_StreamDelegate : NSObject <NSStreamDelegate> {
    long lenD;
    uint8_t * D;
    long idxD;
}

@property (retain) NSMutableData * bufferData;
@property (copy) void (^ completionBlock)(vDSP_Length outputLength, NSError * error);
@property (copy) void (^ outputBlock)(float output[], vDSP_Length outputLength, NSData * outputData, NSError * error);
@property (readonly, retain) NSStream * stream;
@property (assign) vDSP_Length rows;
@property (assign) vDSP_Length cols;
@property (readonly, retain) NSDictionary * options;


- (id)initWithStream:(NSStream *)stream
                rows:(vDSP_Length)rows
                cols:(vDSP_Length)cols
             options:(NSDictionary *)options;

- (void)startReading;
- (void)startWriting;

@end
