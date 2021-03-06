//
//  vMAT_Types.mm
//  vMAT
//
//  Created by Kaelin Colclasure on 4/5/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import <string>


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
        NSRange r1 = [matches[0] rangeAtIndex:1];
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
        NSRange r1 = [matches[0] rangeAtIndex:1];
        NSRange r2 = [matches[1] rangeAtIndex:1];
        NSString * genericCmdString = [NSString stringWithFormat:format,
                                    [descriptions substringWithRange:r1], [descriptions substringWithRange:r2]];
        return NSSelectorFromString(genericCmdString);
    }
    
    // Explicit template expansions. (I suppose it beats the old template code bloat.)
    template SEL genericCmd(NSString * format, vMAT_MIType type);
    template SEL genericCmd(NSString * format, vMAT_MIType typeA, vMAT_MIType typeB);
    template SEL genericCmd(NSString * format, vMAT_MIType type, vMAT_MXClass mxClass);
    
    double     DOUBLE;
    float      SINGLE;
    int8_t     INT8;
    uint8_t    UINT8;
    int16_t    INT16;
    uint16_t   UINT16;
    int32_t    INT32;
    uint32_t   UINT32;
    int64_t    INT64;
    uint64_t   UINT64;
    vMAT_idx_t INDEX;
    
}

void
vMAT_byteswap16(void * vector,
                vDSP_Length vectorLength)
{
    uint16_t * vswap = (uint16_t *)vector;
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
    uint32_t * vswap = (uint32_t *)vector;
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
    uint64_t * vswap = (uint64_t *)vector;
    for (long i = 0;
         i < vectorLength;
         i++) {
        vswap[i] = OSSwapConstInt64(vswap[i]);
    }
}

NSString *
vMAT_StringFromSize(vMAT_Size size)
{
    NSMutableString * string = [NSMutableString stringWithString:@"["];
    std::string sep = "";
    for (int i = 0;
         i < vMAT_MAXDIMS;
         i++) {
        if (size[i] > 0) [string appendFormat:@"%s%ld", sep.c_str(), (long)size[i]];
        else break;
        sep = " ";
    }
    [string appendString:@"]"];
    return string;
}

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
    else if (type == '~') return @"[~]SUPPRESSED";
    else return nil;
}

vMAT_MIType
vMAT_MITypeNamed(NSString * name)
{
    static dispatch_once_t onceToken;
    static NSDictionary * namedTypes = nil;
    dispatch_once(&onceToken, ^{
        namedTypes =
        @{ @"double":  [NSNumber numberWithInt:miDOUBLE],
           @"single":  [NSNumber numberWithInt:miSINGLE],
           @"int8":    [NSNumber numberWithInt:miINT8],
           @"uint8":   [NSNumber numberWithInt:miUINT8],
           @"int16":   [NSNumber numberWithInt:miINT16],
           @"uint16":  [NSNumber numberWithInt:miUINT16],
           @"int32":   [NSNumber numberWithInt:miINT32],
           @"uint32":  [NSNumber numberWithInt:miUINT32],
           @"int64":   [NSNumber numberWithInt:miINT64],
           @"uint64":  [NSNumber numberWithInt:miUINT64],
           @"index":   [NSNumber numberWithInt:vMAT::MIType(vMAT::INDEX)],
           @"logical": [NSNumber numberWithInt:vMAT::MIType(true)],
           };
    });
    return (vMAT_MIType)[[namedTypes objectForKey:[name lowercaseString]] intValue];
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
    else if (type == '~') return ~0;
    else return 0;
}

NSString *
vMAT_MXClassDescription(vMAT_MXClass mxClass)
{
    static NSString * const desc[mxRANGE_LIMIT] = {
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
    if (mxClass > 0 && mxClass < 16) return desc[mxClass];
    else return nil;
}

vMAT_MIType
vMAT_MXClassType(vMAT_MXClass mxClass)
{
    static vMAT_MIType type[mxRANGE_LIMIT] = {
        miNONE,
        miNONE,
        miNONE,
        miNONE,
        miUTF8,
        miNONE,
        miDOUBLE,
        miSINGLE,
        miINT8,
        miUINT8,
        miINT16,
        miUINT16,
        miINT32,
        miUINT32,
        miINT64,
        miUINT64,
    };
    if (mxClass > 0 && mxClass < 16) return type[mxClass];
    else return miNONE;
}

vMAT_MXClass
vMAT_MITypeClass(vMAT_MIType type)
{
    static vMAT_MXClass mxClass[miRANGE_LIMIT] = {
        mxNONE,
        mxINT8_CLASS,
        mxUINT8_CLASS,
        mxINT16_CLASS,
        mxUINT16_CLASS,
        mxINT32_CLASS,
        mxUINT32_CLASS,
        mxSINGLE_CLASS,
        mxNONE,
        mxDOUBLE_CLASS,
        mxNONE,
        mxNONE,
        mxINT64_CLASS,
        mxUINT64_CLASS,
        mxNONE,
        mxNONE,
        mxUINT8_CLASS,
        mxUINT16_CLASS,
        mxUINT32_CLASS,
    };
    if (type > 0 && type < miRANGE_LIMIT) return mxClass[type];
    else return mxNONE;
}

#pragma mark - Constants

NSNull * const vMAT_ALL = [NSNull null];
vMAT_Array * const vMAT_SUPPRESSED = [vMAT_Array arrayWithSize:vMAT_MakeSize(0, 0) type:(vMAT_MIType)'~'];

extern double vMATVersionNumber; // From vMAT_vers.c
NSString * const vMAT_VersionTag = [NSString stringWithFormat:@"%g", vMATVersionNumber];

NSString * const vMAT_ErrorDomain = @"com.ohmware.vMAT";
