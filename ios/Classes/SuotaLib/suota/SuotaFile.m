/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import "SuotaFile.h"
#import <zlib.h>
#import "HeaderInfo.h"
#import "HeaderInfoBuilder.h"
#import "SuotaLibConfig.h"
#import "SuotaLibLog.h"

@implementation SuotaFile

static NSString* const TAG = @"SuotaFile";

- (instancetype) init {
    self = [super init];
    if (!self)
        return nil;
    self.blockSize = SuotaLibConfig.DEFAULT_BLOCK_SIZE;
    self.chunkSize = SuotaLibConfig.DEFAULT_CHUNK_SIZE;
    return self;
}

- (instancetype) initWithAbsoluteFilePath:(NSString*)file {
    self = [self init];
    if (!self)
        return nil;
    self.file = file;
    self.filename = [file lastPathComponent];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.file]) {
        SuotaLog(TAG, @"File does not exist in path: %@", self.file);
        return nil;
    }
    return self;
}

- (instancetype) initWithFilename:(NSString*)filename {
    return [self initWithPath:SuotaLibConfig.DEFAULT_FIRMWARE_PATH filename:filename];
}

- (instancetype) initWithPath:(NSString*)path filename:(NSString*)filename {
    self = [self init];
    if (!self)
        return nil;
    self.file = [NSString pathWithComponents:@[path, filename]];
    self.filename = filename;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.file]) {
        SuotaLog(TAG, @"File does not exist in path: %@", self.file);
        return nil;
    }
    return self;
}

- (instancetype) initWithURL:(NSURL*)url {
    self = [self init];
    if (!self)
        return nil;
    self.url = url;
    self.filename = url.lastPathComponent;
    return self;
}

- (instancetype) initWithFirmwareBuffer:(NSData*)firmware {
    self = [self init];
    if (!self)
        return nil;
    self.firmwareSize = (int) firmware.length;
    self.data = [NSMutableData data];
    [self.data appendData:firmware];
    self.crc = [self calculateCrc];
    const uint8_t crc = self.crc;
    [self.data appendBytes:&crc length:1];
    return self;
}

+ (NSArray<SuotaFile*>*) listFilesInPathList:(NSArray<NSString*>*)pathList extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders withHeaderInfo:(BOOL)withHeaderInfo {
    SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"List files%@: %@ %@", (extension && extension.length != 0  ? [NSString stringWithFormat:@" (*%@)", extension] : @""), pathList, searchSubFolders ? @" (recursive)" : @"");
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSMutableArray<SuotaFile*>* files = [NSMutableArray array];
    BOOL isDirectory;
    for (NSString* path in pathList) {
        if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
            SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"Can't find directory: %@", path);
            continue;
        }

        NSError *error;
        NSArray<NSString*>* currentDirFiles = [fileManager contentsOfDirectoryAtPath:path error:&error];
        if (!currentDirFiles) {
            SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"Error reading contents of directory: %@ %@", path, error.localizedDescription);
            continue;
        }
        if (currentDirFiles.count == 0)
            continue;

        for (NSString* currentFile in currentDirFiles) {
            NSString* fullFilePath = [NSString pathWithComponents:@[path, currentFile]];
            if (![fileManager fileExistsAtPath:fullFilePath isDirectory:&isDirectory]) {
                SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"Unexpected error. Can' find file: %@", fullFilePath);
                continue;
            }
            if (isDirectory && searchSubFolders) {
                [files addObjectsFromArray:[self listFilesInPath:fullFilePath extension:extension searchSubFolders:true withHeaderInfo:withHeaderInfo]];
            } else if (!isDirectory && ((!extension || extension.length == 0) || [currentFile hasSuffix:[extension lowercaseString]])) {
                SuotaFile* suotaFile = [[SuotaFile alloc] initWithAbsoluteFilePath:fullFilePath];
                if (withHeaderInfo)
                    suotaFile.headerInfo = [HeaderInfoBuilder headerWithFilePath:fullFilePath];
                [files addObject:suotaFile];
            }
        }
    }
    SuotaLogOpt(SuotaLibLog.SUOTA_FILE, TAG, @"Found %lu files", (unsigned long)files.count);
    return [files sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:true selector:@selector(localizedCaseInsensitiveCompare:)]]];
}

+ (NSArray<SuotaFile*>*) listFilesInPathList:(NSArray<NSString*>*)pathList {
    return [self listFilesInPathList:pathList extension:nil searchSubFolders:false withHeaderInfo:SuotaLibConfig.FILE_LIST_HEADER_INFO];
}

+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders withHeaderInfo:(BOOL)withHeaderInfo {
    return [self listFilesInPathList:@[path] extension:extension searchSubFolders:searchSubFolders withHeaderInfo:withHeaderInfo];
}

+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path {
    return [self listFilesInPath:path extension:nil searchSubFolders:false withHeaderInfo:SuotaLibConfig.FILE_LIST_HEADER_INFO];
}

+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path withHeaderInfo:(BOOL)withHeaderInfo {
    return [self listFilesInPath:path extension:nil searchSubFolders:false withHeaderInfo:withHeaderInfo];
}

+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension {
    return [self listFilesInPath:path extension:extension searchSubFolders:false withHeaderInfo:SuotaLibConfig.FILE_LIST_HEADER_INFO];
}

+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders {
    return [self listFilesInPathList:@[path] extension:extension searchSubFolders:searchSubFolders withHeaderInfo:SuotaLibConfig.FILE_LIST_HEADER_INFO];
}

+ (NSArray<SuotaFile*>*) listFiles {
    return [self listFilesInPath:SuotaLibConfig.DEFAULT_FIRMWARE_PATH];
}

+ (NSArray<SuotaFile*>*) listFilesWithHeaderInfo {
    return [self listFilesInPath:SuotaLibConfig.DEFAULT_FIRMWARE_PATH withHeaderInfo:true];
}

- (NSString*) fileName {
    return (!self.filename || self.filename.length == 0) ? @"Unknown" : self.filename;
}

- (BOOL) hasHeaderInfo {
    return self.headerInfo != nil;
}

- (int) uploadSize {
    return (int)self.data.length;
}

- (BOOL) isLastBlockShorter {
    return self.lastBlockSize != 0;
}

- (NSArray<NSData*>*) getBlock:(int)index {
    return self.blocks[index];
}

- (NSData*) getChunk:(int)index {
    int block = index / self.chunksPerBlock;
    int chunk = index % self.chunksPerBlock;
    return self.blocks[block][chunk];
}

- (int) getBlockSize:(int)index {
    return index < self.totalBlocks - 1 || self.lastBlockSize == 0 ? self.blockSize : self.lastBlockSize;
}

- (int) getBlockChunks:(int)index {
    return (int)self.blocks[index].count;
}

- (BOOL) isLastBlock:(int)index {
    return index == self.totalBlocks - 1;
}

- (BOOL) isLastChunk:(int)index {
    return index % self.chunksPerBlock == self.blocks[index / self.chunksPerBlock].count - 1;
}

- (BOOL) isLastChunk:(int)block chunk:(int)chunk {
    return chunk == self.blocks[block].count - 1;
}

- (void) load {
    NSFileHandle* file = self.file ? [NSFileHandle fileHandleForReadingAtPath:self.file] : [NSFileHandle fileHandleForReadingFromURL:self.url error:nil];
    if (!file) {
        SuotaLog(TAG, @"Failed to load firmware: %@", self.file);
        self.data = nil;
        return;
    }
    self.data = [NSMutableData dataWithData:[file readDataToEndOfFile]];
    [file closeFile];
    self.firmwareSize = (int)self.data.length;
    self.crc = [self calculateCrc];
    const uint8_t crc = self.crc;
    [self.data appendBytes:&crc length:1];
}

- (BOOL) isLoaded {
    return self.data != nil;
}

- (uint8_t) calculateCrc {
    uint8_t crc_code = 0;
    const uint8_t* bytes = self.data.bytes;
    for (int i = 0; i < self.firmwareSize; i++) {
        crc_code ^= bytes[i];
    }
    crc_code &= 0xff;
    return crc_code;
}

- (uint64_t) calculatePayloadCrc {
    uint8_t headerBytes[self.headerInfo.payloadSize];
    [self.data getBytes:&headerBytes range:NSMakeRange(self.headerInfo.payloadOffset, self.headerInfo.payloadSize)];
    unsigned long crc = crc32(0L, Z_NULL, 0);
    return crc32(crc, headerBytes, (int)self.headerInfo.payloadSize);
}

- (BOOL) isHeaderCrcValid {
    return self.firmwareSize - self.headerInfo.payloadOffset >= self.headerInfo.payloadSize && self.headerInfo.payloadCrc == [self calculatePayloadCrc];
}

- (void) initBlocks:(int)blockSize chunkSize:(int)chunkSize {
    self.blockSize = blockSize;
    self.chunkSize = chunkSize;
    [self initBlocks];
}

- (void) initBlocks {
    if (self.blockSize < self.chunkSize)
        self.blockSize = self.chunkSize;
    if (self.blockSize > self.data.length) {
        self.blockSize = (int)self.data.length;
        if (self.chunkSize > self.blockSize)
            self.chunkSize = self.blockSize;
    }
    
    self.totalBlocks = ((int)self.data.length) / self.blockSize + ((int)self.data.length % self.blockSize != 0 ? 1 : 0);
    self.chunksPerBlock = self.blockSize / self.chunkSize + (self.blockSize % self.chunkSize != 0 ? 1 : 0);
    self.lastBlockSize = self.data.length % self.blockSize;
    self.totalChunks = 0;
    
    // Loop through all the bytes and split them into pieces of the default chunk size
    self.blocks = [NSMutableArray arrayWithCapacity:self.totalBlocks];
    int offset = 0;
    for (int i = 0; i < self.totalBlocks; i++) {
        int currBlockSize = self.blockSize;
        int chunksInBlock = self.chunksPerBlock;
        // Check if the last block needs to be smaller
        if (offset + self.blockSize > self.data.length) {
            currBlockSize = self.data.length % self.blockSize;
            chunksInBlock = currBlockSize / self.chunkSize + (currBlockSize % self.chunkSize != 0 ? 1 : 0);
        }
        self.blocks[i] = [NSMutableArray arrayWithCapacity:chunksInBlock];
        for (int j = 0; j < chunksInBlock; j++) {
            // Default chunk size
            int currChunkSize = self.chunkSize;
            // Check if last chunk in block needs to be smaller
            if ((j + 1) * self.chunkSize > currBlockSize) {
                currChunkSize = currBlockSize % self.chunkSize;
            }
            uint8_t chunk[currChunkSize];
            [self.data getBytes:&chunk range:NSMakeRange(offset, currChunkSize)];
            self.blocks[i][j] = [NSData dataWithBytes:chunk length:currChunkSize];
            offset += currChunkSize;
            self.totalChunks++;
        }
    }
}

@end
