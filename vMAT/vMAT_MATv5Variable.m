//
//  vMAT_MATv5Variable.m
//  vMAT
//
//  Created by Kaelin Colclasure on 3/31/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_MATv5Variable.h"


@implementation vMAT_MATv5Variable

+ (vMAT_MATv5Variable *)variableWithMXClass:(vMAT_MXClass)mxClass
                                 arrayFlags:(uint32_t)flags
                                 dimensions:(NSArray *)dimensions
                                       name:(NSString *)name;
{
    vMAT_MATv5Variable * variable = nil;
    switch (mxClass) {
        case mxCHAR_CLASS:
        case mxDOUBLE_CLASS:
        case mxINT16_CLASS:
        case mxINT32_CLASS:
        case mxINT64_CLASS:
        case mxINT8_CLASS:
        case mxSINGLE_CLASS:
        case mxUINT16_CLASS:
        case mxUINT32_CLASS:
        case mxUINT64_CLASS:
        case mxUINT8_CLASS: {
            variable = [[vMAT_MATv5NumericArray alloc] init];
            variable->_isComplex = (flags & 0x800) == 0x800;
            variable->_isGlobal  = (flags & 0x400) == 0x400;
            variable->_isLogical = (flags & 0x200) == 0x200;
            variable->_mxClass = mxClass;
            variable->_dimensions = dimensions;
            variable->_name = name;
            break;
        }
            
        case mxCELL_CLASS:
        case mxOBJECT_CLASS:
        case mxSPARSE_CLASS:
        case mxSTRUCT_CLASS: {
            break;
        }
            
        default: {
            break;
        }
    }
    return variable;
}

- (NSString *)description;
{
    NSString * prefix = [super description];
    NSMutableString * size = [NSMutableString stringWithString:@"["];
    char * sep = "";
    for (NSNumber * number in _dimensions) {
        [size appendFormat:@"%s%@", sep, number];
        sep = " ";
    }
    [size appendString:@"]"];
    NSString * string = [NSString stringWithFormat:@"%.*s; mxClass: %@, size: %@, name: \"%@\">",
                         (int)[prefix length] - 1, [prefix UTF8String],
                         vMAT_MXClassDescription(_mxClass),
                         size,
                         _name];
    return string;
}

- (void)loadFromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    [self doesNotRecognizeSelector:_cmd]; // Subclass responsibility
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return nil;                           // Subclass responsibility
}

@end

@implementation vMAT_MATv5NumericArray

- (SEL)loadCmdForType:(vMAT_MIType)type
              mxClass:(vMAT_MXClass)mxClass;
{
    const int rows = mxRANGE_LIMIT;
    const int cols = miRANGE_LIMIT;
    static SEL cache[rows * cols];
    SEL loadCmd = nil;
    @synchronized ([self class]) {
        loadCmd = cache[mxClass * rows + type];
        if (loadCmd == nil) {
            NSString * descriptions = [vMAT_MITypeDescription(type) stringByAppendingString:vMAT_MXClassDescription(mxClass)];
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:NULL];
            NSArray * matches = [regex matchesInString:descriptions options:0 range:NSMakeRange(0, [descriptions length])];
            NSAssert([matches count] == 2, @"Couldn't make loadCmd from %@", descriptions);
            NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
            NSRange r2 = [[matches objectAtIndex:1] rangeAtIndex:1];
            NSString * loadCmdString = [NSString stringWithFormat:@"_load_%@_%@_fromOperation:",
                                        [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
            loadCmd = NSSelectorFromString(loadCmdString);
            cache[mxClass * rows + type] = loadCmd;
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
    __block vMAT_MIType type = 0;
    __block uint32_t length = 0;
    [operation readElementType:&type
                        length:&length
                   outputBlock:
     ^ {
         SEL loadCmd = [self loadCmdForType:type mxClass:_mxClass];
         NSLog(@"Loading %@", self);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
         [self performSelector:loadCmd withObject:operation];
#pragma clang diagnostic pop
     }];
}

- (vMAT_MATv5NumericArray *)toNumericArray;
{
    return self;
}

- (void)_load_miUINT8_mxUINT8_fromOperation:(vMAT_MATv5ReadOperation *)operation;
{
    long rows = [[_dimensions objectAtIndex:0] longValue];
    long cols = [[_dimensions objectAtIndex:1] longValue];
    // MATLAB writes data in column order, whereas C stores it in row order.
    long lenC = rows * sizeof(uint8_t);
    uint8_t * C = malloc(lenC);
    long lenD = rows * cols * sizeof(uint8_t);
    _arrayData = [NSMutableData dataWithCapacity:lenD];
    _arrayData.length = lenD;
    uint8_t * D = [_arrayData mutableBytes];
    for (int col = 0;
         col < cols;
         col++) {
        [operation readComplete:C
                         length:lenC];
        // No need for swapping with 1-byte elements. 
        for (int row = 0;
             row < rows;
             row++) {
            D[row * cols + col] = C[row]; // Note this transposes D!
        }
    }
}

@end
