/*
 *******************************************************************************
 *
 * Copyright (C) 2019-2020 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

/*!
 @header SuotaFile.h
 @brief Header file for the SuotaFile class.
 
 This header file contains method and property declaration for the SuotaFile class.
 
 @copyright 2019 Dialog Semiconductor
 */

#import <Foundation/Foundation.h>

@class HeaderInfo;

/*!
 * @class SuotaFile
 *
 * @discussion Representation of a firmware file.
 *
 */
@interface SuotaFile : NSObject

/*!
 * @property file
 *
 * @discussion {@link NSString} containing the absolute file path.
 */
@property NSString* file;

/*!
 * @property url
 *
 * @discussion {@link NSURL} containing the file URL.
 */
@property NSURL* url;

/*!
 * @property filename
 *
 * @discussion {@link NSString} containing the Filename.
 */
@property NSString* filename;

/*!
 * @property headerInfo
 *
 * @discussion {@link HeaderInfo} object containing information about the file header.
 */
@property HeaderInfo* headerInfo;

/*!
 * @property firmwareSize
 *
 * @discussion Size of the firmware file.
 */
@property int firmwareSize;

/*!
 * @property blockSize
 *
 * @discussion SUOTA file block size in bytes.
 */
@property int blockSize;

/*!
 * @property chunkSize
 *
 * @discussion SUOTA file chunk size in bytes.
 */
@property int chunkSize;

/*!
 * @property totalBlocks
 *
 * @discussion SUOTA file total block number.
 */
@property int totalBlocks;

/*!
 * @property totalChunks
 *
 * @discussion SUOTA file total chunk number.
 */
@property int totalChunks;

/*!
 * @property chunksPerBlock
 *
 * @discussion Chunk number in each block.
 *
 */
@property int chunksPerBlock;

@property int lastBlockSize;
@property NSMutableData* data;
@property NSMutableArray<NSMutableArray<NSData*>*>* blocks;
@property uint8_t crc;

/*!
 * @method initWithAbsoluteFilePath:
 *
 * @param file Absolute file path.
 *
 * @discussion Creates a new {@link SuotaFile} instance by opening the file at the absolute file path.
 *
 */
- (instancetype) initWithAbsoluteFilePath:(NSString*)file;

/*!
 * @method initWithFilename:
 *
 * @param filename The name of the SUOTA file.
 *
 * @discussion Creates a new {@link SuotaFile} instance by opening the file with the given filename in the default directory. Default directory is the app Documents directory.
 *
 */
- (instancetype) initWithFilename:(NSString*)filename;

/*!
 * @method initWithPath:filename:
 *
 * @param path The path of the SUOTA file.
 * @param filename The name of the SUOTA file.
 *
 * @discussion Creates a new {@link SuotaFile} instance by converting the given path and filename.
 *
 */
- (instancetype) initWithPath:(NSString*)path filename:(NSString*)filename;

/*!
 * @method initWithURL:
 *
 * @param url The URL of the SUOTA file.
 *
 * @discussion Creates a new {@link SuotaFile} instance by opening the file with the given URL.
 *
 */
- (instancetype) initWithURL:(NSURL*)url;

/*!
 * @method initWithFirmwareBuffer:
 *
 * @param firmware Firmware raw buffer.
 *
 * @discussion Creates a new {@link SuotaFile} instance by converting the given buffer.
 *
 */
- (instancetype) initWithFirmwareBuffer:(NSData*)firmware;

/*!
 * @method listFilesInPathList:extension:searchSubFolders:withHeaderInfo:
 *
 * @param pathList Search path list.
 * @param extension File extension. If nil, all files are included in the returned list.
 * @param searchSubFolders Indicates if the method shall search for files in each path sub-folder. If <code>false</code>, the path sub-folders are ignored.
 * @param withHeaderInfo Indicates if the method shall initialize the header info of each {@link SuotaFile} object. If <code>false</code>, {@link SuotaFile} header info initialization is ignored.
 *
 * @discussion Returns a list of {@link SuotaFile} objects found in the given list of paths, with the given extension, sorted by filename.
 *
 * @return List of {@link SuotaFile} objects.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPathList:(NSArray<NSString*>*)pathList extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders withHeaderInfo:(BOOL)withHeaderInfo;

/*!
 * @method listFilesInPathList:
 *
 * @param pathList Search path list.
 * @return List of {@link SuotaFile} objects.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, sorted by filename. Path sub-folders are ignored. {@link SuotaFile} header info initialization is ignored.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPathList:(NSArray<NSString*>*)pathList;

/*!
 * @method listFilesInPath:extension:searchSubFolders:withHeaderInfo:
 *
 * @param path Search path.
 * @param extension File extension. If nil, all files are included in the returned list.
 * @param searchSubFolders Indicates if the method shall search for files in each path sub-folder. If <code>false</code>, the path sub-folders are ignored.
 * @param withHeaderInfo Indicates if the method shall initialize the header info of each {@link SuotaFile} object. If <code>false</code>, {@link SuotaFile} header info initialization is ignored.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, with the given extention, sorted by filename. {@link SuotaFile} header info initialization is ignored.
 *
 * @return List of {@link SuotaFile} objects.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders withHeaderInfo:(BOOL)withHeaderInfo;

/*!
 * @method listFilesInPath:
 *
 * @param path Search path.
 * @return List of {@link SuotaFile} objects.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, sorted by filename. Path sub-folders are ignored. {@link SuotaFile} header info initialization is ignored.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path;

/*!
 * @method listFilesInPath:withHeaderInfo:
 *
 * @param path Search path.
 * @param withHeaderInfo Indicates if the method shall initialize the header info of each {@link SuotaFile} object.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, sorted by filename. Path sub-folders are ignored.
 *
 * @return List of {@link SuotaFile} objects.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path withHeaderInfo:(BOOL)withHeaderInfo;

/*!
 * @method listFilesInPath:extension:
 *
 * @param path Search path.
 * @param extension File extension. If nil, all files are included in the returned list.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, with the given extension, sorted by filename. Path sub-folders are ignored. {@link SuotaFile} header info initialization is ignored.
 *
 * @return List of {@link SuotaFile} objects.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension;

/*!
 * @method listFilesInPath:extension:searchSubFolders:withHeaderInfo:
 *
 * @param path Search path.
 * @param extension File extension. If nil, all files are included in the returned list.
 * @param searchSubFolders Indicates if the method shall search for files in each path sub-folder. If <code>false</code>, the path sub-folders are ignored.
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the given path, with the given extention, sorted by filename.
 *
 * @return List of {@link SuotaFile} objects.
 *
 */
+ (NSArray<SuotaFile*>*) listFilesInPath:(NSString*)path extension:(NSString*)extension searchSubFolders:(BOOL)searchSubFolders;

/*!
 * @method listFiles
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the default directory. Default directory is the app Documents directory.
 *
 * @return List of {@link SuotaFile} objects.
 */
+ (NSArray<SuotaFile*>*) listFiles;

/*!
 * @method listFilesWithHeaderInfo
 *
 * @discussion Returns a list of {@link SuotaFile} objects for each SUOTA file found in the default directory. Default directory is the app Documents directory. Also initializes the header info of each {@link SuotaFile} object in the list.
 *
 * @return List of {@link SuotaFile} objects.
 */
+ (NSArray<SuotaFile*>*) listFilesWithHeaderInfo;

/*!
 * @method fileName
 *
 * @discussion Returns the name of the SUOTA file or <code>"Unknown"</code> if there is no name specified.
 *
 * @return The name of the SUOTA file.
 *
 */
- (NSString*) fileName;

- (BOOL) hasHeaderInfo;
- (int) uploadSize;
- (BOOL) isLastBlockShorter;
- (NSArray<NSData*>*) getBlock:(int)index;
- (NSData*) getChunk:(int)index;
- (int) getBlockSize:(int)blockCount;
- (int) getBlockChunks:(int)index;
- (BOOL) isLastBlock:(int)index;
- (BOOL) isLastChunk:(int)index;
- (BOOL) isLastChunk:(int)block chunk:(int)chunk;
- (void) load;
- (BOOL) isLoaded;
/*!
 * @method isHeaderCrcValid
 *
 * @discussion Checks if the file header CRC is valid.
 *
 * @return A {@link BOOL} value indicating if the header CRC is valid.
 */
- (BOOL) isHeaderCrcValid;
- (void) initBlocks:(int)blockSize chunkSize:(int)chunkSize;
- (void) initBlocks;

@end
