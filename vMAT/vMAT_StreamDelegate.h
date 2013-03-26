//
//  vMAT_StreamDelegate.h
//  vMAT
//
//  Created by Kaelin Colclasure on 3/25/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import <Accelerate/Accelerate.h>


@interface vMAT_StreamDelegate : NSObject <NSStreamDelegate> {
    long lenD;
    uint8_t * D;
    long idxD;
}

@property (readonly, retain) NSMutableData * bufferData;
@property (copy) void (^ outputBlock)(float output[], vDSP_Length outputLength, NSData * outputData, NSError * error);
@property (readonly, retain) NSStream * stream;

- (id)initWithStream:(NSStream *)stream
                rows:(vDSP_Length)rows
                cols:(vDSP_Length)cols
             options:(NSDictionary *)options;

- (void)startReading;

@end
