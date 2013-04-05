//
//  vMAT_Types.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Types.h"


namespace vMAT {
    
    NSString *
    genericDescription(vMAT_MIType type)
    {
        return vMAT_MITypeDescription(type);
    }
    
    NSString *
    genericDescription(vMAT_MXClass mxClass)
    {
        return vMAT_MXClassDescription(mxClass);
    }
    
    template <typename A>
    SEL
    genericCmd(NSString * format, A a)
    {
        NSString * description = genericDescription(a);
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:NULL];
        NSArray * matches = [regex matchesInString:description options:0 range:NSMakeRange(0, [description length])];
        NSCAssert([matches count] == 1, @"Couldn't make genericCmd from %@", description);
        NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
        NSString * genericCmdString = [NSString stringWithFormat:format,
                                       [description substringWithRange:r1]];
        return NSSelectorFromString(genericCmdString);
    }
    
    template <typename A, typename B>
    SEL
    genericCmd(NSString * format, A a, B b)
    {
        NSString * descriptions = [genericDescription(a) stringByAppendingString:genericDescription(b)];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[0-9]+\\]([A-Z0-9]+)"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:NULL];
        NSArray * matches = [regex matchesInString:descriptions options:0 range:NSMakeRange(0, [descriptions length])];
        NSCAssert([matches count] == 2, @"Couldn't make genericCmd from %@", descriptions);
        NSRange r1 = [[matches objectAtIndex:0] rangeAtIndex:1];
        NSRange r2 = [[matches objectAtIndex:1] rangeAtIndex:1];
        NSString * genericCmdString = [NSString stringWithFormat:format,
                                    [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
        return NSSelectorFromString(genericCmdString);
    }
    
    // Explicit template expansions. (I suppose it beats the old template code bloat.)
    template SEL genericCmd(NSString * format, vMAT_MIType type);
    template SEL genericCmd(NSString * format, vMAT_MIType typeA, vMAT_MIType typeB);
    template SEL genericCmd(NSString * format, vMAT_MIType type, vMAT_MXClass mxClass);
    
    double   DOUBLE;
    float    SINGLE;
    int8_t   INT8;
    uint8_t  UINT8;
    int16_t  INT16;
    uint16_t UINT16;
    int32_t  INT32;
    uint32_t UINT32;
    int64_t  INT64;
    uint64_t UINT64;
    
}
