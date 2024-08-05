/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "HeaderInfoBuilder.h"
#import "HeaderInfo.h"
#import "HeaderInfo58x.h"
#import "HeaderInfo68x.h"
#import "HeaderInfo69x.h"
#import "SuotaLibLog.h"

@implementation HeaderInfoBuilder

static NSString* const TAG = @"HeaderInfoBuilder";

+ (HeaderInfo*) headerWithRawBuffer:(NSData*)rawBuffer {
    const uint8_t* rawBufferBytes = rawBuffer.bytes;
    int signature = rawBufferBytes[0] << 8 | rawBufferBytes[1];
    
    if (signature == HeaderInfo58x.SIGNATURE) {
        return [[HeaderInfo58x alloc] initWithRawBuffer:rawBuffer];
    } else if (signature == HeaderInfo68x.SIGNATURE) {
        return [[HeaderInfo68x alloc] initWithRawBuffer:rawBuffer];
    } else if (signature == HeaderInfo69x.SIGNATURE) {
        return [[HeaderInfo69x alloc] initWithRawBuffer:rawBuffer];
    } else {
        return nil;
    }
}

+ (HeaderInfo*) headerWithFilePath:(NSString*)filePath {
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!file) {
        SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"Failed to read firmware header: %@", file);
        return nil;
    }
    NSData* fileData = [file readDataToEndOfFile];
    [file closeFile];
    NSUInteger totalBytes = fileData.length;

    if (totalBytes < HeaderInfo.SIGNATURE_LENGTH)
        return nil;
    uint8_t headerSignature[HeaderInfo.SIGNATURE_LENGTH];
    [fileData getBytes:&headerSignature length:HeaderInfo.SIGNATURE_LENGTH];
    int signature = headerSignature[0] << 8 | headerSignature[1];

    int headerSize;
    if (signature == HeaderInfo58x.SIGNATURE) {
        headerSize = HeaderInfo58x.HEADER_SIZE;
    } else if (signature == HeaderInfo68x.SIGNATURE) {
        headerSize = HeaderInfo68x.HEADER_SIZE;
    } else if (signature == HeaderInfo69x.SIGNATURE) {
        headerSize = HeaderInfo69x.HEADER_SIZE;
    } else {
        return nil;
    }

    if (totalBytes < headerSize)
        return nil;
    NSData* header = [fileData subdataWithRange:NSMakeRange(0, headerSize)];

    if (signature == HeaderInfo58x.SIGNATURE) {
        return [[HeaderInfo58x alloc] initWithHeader:header totalBytes:totalBytes];
    } else if (signature == HeaderInfo68x.SIGNATURE) {
        return [[HeaderInfo68x alloc] initWithHeader:header totalBytes:totalBytes];
    } else {
        return [[HeaderInfo69x alloc] initWithHeader:header totalBytes:totalBytes];
    }
}

@end
