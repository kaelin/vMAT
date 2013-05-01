//
//  vMAT_MATv5SaveOperation.m
//  vMAT
//
//  Created by Kaelin Colclasure on 5/1/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5SaveOperation.h"

#import "vMAT_Private.h"


@implementation vMAT_MATv5SaveOperation

- (id)initWithOutputStream:(NSOutputStream *)stream;
{
    NSParameterAssert(stream != nil);
    if ((self = [super init]) != nil) {
        _stream = stream;
    }
    return self;
}

@end
