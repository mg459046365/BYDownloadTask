//
//  BYDownloadManager.h
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BYDownloadTask.h"

@interface BYDownloadManager : NSObject

/**
 下载进程BYDownloadTask数组
 */
@property (nonatomic, readonly) NSArray<BYDownloadTask *> *taskArray;

/**
 下载进程集合，key-value形式。
 key为BYDownloadTask的identifier，value为BYDownloadTask实例
 */
@property (nonatomic, readonly) NSDictionary<NSString *, BYDownloadTask *> *taskDictionary;

/**
 下载文件缓存路径
 */
@property (nonatomic, readonly) NSString *cacheDir;

/**
 下载管理器

 @return 下载管理器BYDownloadManager实例
 */
+ (instancetype)manager;

/*!
 * @brief 添加下载进程
 */
- (void)addTask:(BYDownloadTask *)task;

/*!
 * @brief 移除下载进程
 */
- (void)removeTaskWithIdentifer:(NSString *)identifer;
/**
 取消下载任务

 @param identifer 下载进程的唯一标志
 @param deleteTemp YES - 删除临时文件，NO-保留下载临时文件
 */
- (void)cancelTaskWithIdentifer:(NSString*)identifer deleteTempFile:(BOOL)deleteTemp;

/**
 通过下载任务唯一标志获取下载进程

 @param identifier 下载任务唯一标志
 @return BYDownloadTask实例
 */
- (BYDownloadTask *)taskWithIdentifier:(NSString*)identifier;

@end
