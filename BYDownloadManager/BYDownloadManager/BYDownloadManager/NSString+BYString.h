//
//  NSString+BYString.h
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BYString)
@property (readonly) NSString *by_md5String;
@property (readonly) NSString *by_sha1String;
@property (readonly) NSString *by_sha256String;
@property (readonly) NSString *by_sha512String;

- (NSString *)by_SHA1StringWithKey:(NSString *)key;
- (NSString *)by_SHA256StringWithKey:(NSString *)key;
- (NSString *)by_SHA512StringWithKey:(NSString *)key;
- (NSString *)by_deleteAllSpaceAndNewline;
@end
