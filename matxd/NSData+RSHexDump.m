//
//  NSData+RSHexDump.m
//  RSFoundation
//
//  Created by Daniel Jalkut on 2/14/07.
//  Copyright 2007 Red Sweater Software. All rights reserved.
//
//	Based on code from Dan Wood 
//	http://gigliwood.com/weblog/Cocoa/Better_description_.html
//
//  Modified by Kaelin Colclasure on 3/26/13.
//  - Use long instead of int for offsets to clean up warnings under LP64.
//  - Minor tweaks to description formatting.
//

#import "NSData+RSHexDump.h"


const unsigned int kDefaultMaxBytesToHexDump = 1024;

@implementation NSData ( RSHexDump )

- (NSString *)description
{
	return [self descriptionFromOffset:0];
}

- (NSString *)descriptionFromOffset:(NSInteger)startOffset;
{
	return [self descriptionFromOffset:startOffset limitingToByteCount:kDefaultMaxBytesToHexDump];
}

- (NSString *)descriptionFromOffset:(NSInteger)startOffset limitingToByteCount:(NSUInteger)maxBytes;
{
    unsigned char *bytes = (unsigned char *)[self bytes];
    NSUInteger stopOffset = [self length];

	// Translate negative offset to positive, by subtracting from end
	if (startOffset < 0)
	{
		startOffset = [self length] + startOffset;
	}

	// Do we have more data than the caller wants?
	BOOL curtailOutput = NO;
	if ((stopOffset - startOffset) > maxBytes)
	{
		curtailOutput = YES;
		stopOffset = startOffset + maxBytes;
	}

	// If we're showing a subset, we'll tack in info about that
	NSString* curtailInfo = @"";
	if ((startOffset > 0) || (stopOffset < [self length]))
	{
		curtailInfo = [NSString stringWithFormat:@" (showing bytes %ld through %ld)", (unsigned long)startOffset, (unsigned long)stopOffset];
	}
	
	// Start the hexdump out with an overview of the content
	NSMutableString *buf = [NSMutableString stringWithFormat:@"NSData %ld bytes%@:\n", (unsigned long)[self length], curtailInfo];
	
	// One row of 16-bytes at a time ...
    NSInteger i, j;
    for ( i = startOffset ; i < stopOffset ; i += 16 )
    {
		// Show the row in Hex first
        [buf appendString:@"  | "];
        for ( j = 0 ; j < 16 ; j++ )    
        {
            NSInteger rowOffset = i+j;
            if (rowOffset < stopOffset)
            {
                [buf appendFormat:@"%02x ", bytes[rowOffset]];
            }
            else
            {
                [buf appendFormat:@"   "];
            }
        }
		
		// Now show in ASCII
        [buf appendString:@"| "];   
        for ( j = 0 ; j < 16 ; j++ )
        {
            NSInteger rowOffset = i+j;
            if (rowOffset < stopOffset)
            {
                unsigned char theChar = bytes[rowOffset];
                if (theChar < 32 || theChar > 127)
                {
                    theChar ='.';
                }
                [buf appendFormat:@"%c", theChar];
            }
        }
		
		// If we're not on the last row, tack on a newline
		if (i+16 < stopOffset)
		{
			[buf appendString:@"\n"];
		}
	}
	
    return buf;	
}

@end
