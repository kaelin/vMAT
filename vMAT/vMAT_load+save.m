//
//  vMAT_load+save.m
//  vMAT
//
//  Created by Kaelin Colclasure on 5/1/13.
//  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.
//

#import "vMAT_Private.h"

#import "vMAT_StreamDelegate.h"


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

NSDictionary *
vMAT_load(NSURL * inputURL,
          NSArray * variableNames,
          NSError ** errorOut)
{
    NSInputStream * stream = [NSInputStream inputStreamWithURL:inputURL];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSDictionary * ws = nil;
    vMAT_load_async(stream, variableNames, ^(NSDictionary * workspace, NSError * error) {
        ws = workspace;
        if (errorOut != NULL) {
            *errorOut = error;
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return ws;
}

void
vMAT_load_async(NSInputStream * stream,
                NSArray * variableNames,
                void (^asyncCompletionBlock)(NSDictionary * workspace,
                                             NSError * error))
{
    vMAT_MATv5LoadOperation * operation = [[vMAT_MATv5LoadOperation alloc] initWithInputStream:stream];
    vMAT_MATv5LoadOperationDelegate * reader = [[vMAT_MATv5LoadOperationDelegate alloc] initWithLoadOperation:operation];
    reader.variableNames = variableNames;
    reader.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [reader start];
    });
}

void
vMAT_save(NSURL * outputURL,
          NSDictionary * workspace,
          NSError ** errorOut)
{
    NSOutputStream * stream = [NSOutputStream outputStreamWithURL:outputURL append:NO];
    [stream open];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    vMAT_save_async(stream, workspace, ^(NSDictionary * workspace, NSError * error) {
        if (errorOut != NULL) {
            *errorOut = error;
        }
        [stream close];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

void
vMAT_save_async(NSOutputStream * stream,
                NSDictionary * workspace,
                void (^asyncCompletionBlock)(NSDictionary * workspace,
                                             NSError * error))
{
    vMAT_MATv5SaveOperation * operation = [[vMAT_MATv5SaveOperation alloc] initWithOutputStream:stream];
    vMAT_MATv5SaveOperationDelegate * writer = [[vMAT_MATv5SaveOperationDelegate alloc] initWithSaveOperation:operation];
    writer.workspace = workspace;
    writer.completionBlock = asyncCompletionBlock;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        [writer start];
    });
}
