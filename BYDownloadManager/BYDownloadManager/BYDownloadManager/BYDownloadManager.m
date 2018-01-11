//
//  BYDownloadManager.m
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import "BYDownloadManager.h"

@interface BYDownloadManager()

/**
 下载进程集合，key-value形式。
 key为BYDownloadTask的identifier，value为BYDownloadTask实例
 */
@property (nonatomic, strong) NSMutableDictionary *taskKeyValues;
@property (nonatomic, strong) NSString *cacheDir;
@end

@implementation BYDownloadManager

+ (instancetype)manager
{
    static BYDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BYDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _taskKeyValues = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary<NSString *,BYDownloadTask *> *)taskDictionary
{
    return [NSDictionary dictionaryWithDictionary:self.taskKeyValues];
}

- (NSArray<BYDownloadTask *> *)taskArray
{
    return [self.taskKeyValues allValues];
}

/*!
 * @brief 添加下载进程
 */
- (void)addTask:(BYDownloadTask *)task
{
    if (!task) {
        return;
    }
    if (!task.identifier) {
        return;
    }
    [self.taskKeyValues setValue:task forKey:task.identifier];
}

- (void)removeTaskWithIdentifer:(NSString *)identifer
{
    if (!identifer) {
        return;
    }
    [self.taskKeyValues setValue:nil forKey:identifer];
}

/**
 取消下载任务
 
 @param identifer 下载进程的唯一标志
 @param deleteTemp YES - 删除临时文件，NO-保留下载临时文件
 */
- (void)cancelTaskWithIdentifer:(NSString*)identifer deleteTempFile:(BOOL)deleteTemp
{
    if (!identifer) {
        return;
    }
    BYDownloadTask *task = self.taskKeyValues[identifer];
    if (!task) {
        return;
    }
    if (deleteTemp) {
        [task cancelAndDeleteTempFile];
    }else{
        [task cancel];
    }
}

/**
 通过下载任务唯一标志获取下载进程
 
 @param identifier 下载任务唯一标志
 @return BYDownloadTask实例
 */
- (BYDownloadTask *)taskWithIdentifier:(NSString*)identifier
{
    if (!identifier) {
        return nil;
    }
    return self.taskKeyValues[identifier];
}

/**
 文件下载缓存目录路径

 @return NSString 文件下载缓存目录路径
 */
- (NSString *)cacheDir {
    if (!_cacheDir) {
        NSFileManager *fmg = [[NSFileManager alloc] init];//default不是线程安全的，故这里直接创建实例
        _cacheDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"BYDownloadCacheDir"];
        BOOL isDir = NO;
        BOOL isExist = [fmg fileExistsAtPath:_cacheDir isDirectory:&isDir];
        if (!isExist || !isDir) {
            NSError *error = nil;
            if (![fmg createDirectoryAtPath:_cacheDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create cache directory at %@", _cacheDir);
                _cacheDir = nil;
            }
        }
    }
    return _cacheDir;
}

@end
