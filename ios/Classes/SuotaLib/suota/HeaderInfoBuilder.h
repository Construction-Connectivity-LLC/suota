/*
 *******************************************************************************
 *
 * Copyright (C) 2019 Dialog Semiconductor.
 * This computer program includes Confidential, Proprietary Information
 * of Dialog Semiconductor. All Rights Reserved.
 *
 *******************************************************************************
 */

#import <Foundation/Foundation.h>

@class HeaderInfo;

@interface HeaderInfoBuilder : NSObject

+ (HeaderInfo*) headerWithRawBuffer:(NSData*)rawBuffer;
+ (HeaderInfo*) headerWithFilePath:(NSString*)filePath;

@end
