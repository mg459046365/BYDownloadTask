//
//  BYDownloadTask.h
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// 开始下载通知
FOUNDATION_EXPORT NSString *const BYDownloadStartNotification;
/// 暂停下载通知
FOUNDATION_EXPORT NSString *const BYDownloadPauseNotification;
/// 继续下载通知
FOUNDATION_EXPORT NSString *const BYDownloadResumeNotification;
/// 完成下载通知
FOUNDATION_EXPORT NSString *const BYDownloadFinishNotification;
/// 开始解压通知
FOUNDATION_EXPORT NSString *const BYDownloadUnzipStartNotification;
/// 解压完毕通知
FOUNDATION_EXPORT NSString *const BYDownloadUnzipFinishNotification;

/// 下载任务ID
FOUNDATION_EXPORT NSString *const BYDownloadKeyIdentifier;
/// 下载任务被手动取消
FOUNDATION_EXPORT NSString *const BYDownloadKeyManualCancel;
/// 下载任务扩展信息
FOUNDATION_EXPORT NSString *const BYDownloadKeyExtendInfo;
/// 下载任务目标路径
FOUNDATION_EXPORT NSString *const BYDownloadKeyTargetPath;
/// 下载任务问价大小
FOUNDATION_EXPORT NSString *const BYDownloadKeyFileSize;
/// 下载任务是否成功
FOUNDATION_EXPORT NSString *const BYDownloadkeySuccess;
/// 下载任务链接集合
FOUNDATION_EXPORT NSString *const BYDownloadKeyLinks;
/// 下载任务错误信息
FOUNDATION_EXPORT NSString *const BYDownloadKeyError;
/// 下载任务当前下载链接
FOUNDATION_EXPORT NSString *const BYDownloadKeyURL;

/**
 下载任务状态

 - BYDownloadTaskStateReady: 准备
 - BYDownloadTaskStateRunning: 下载中
 - BYDownloadTaskStateSuspended: 暂停
 - BYDownloadTaskStateCanceling: 取消
 - BYDownloadTaskStateCompleted: 完成
 */
typedef NS_ENUM(NSInteger, BYDownloadTaskState){
    BYDownloadTaskStateReady = 0,     //!< 等待开始
    BYDownloadTaskStateRunning = 1,   //!< 下载中
    BYDownloadTaskStateSuspended = 2, //!< 暂停
    BYDownloadTaskStateCanceling = 3, //!< 取消
    BYDownloadTaskStateCompleted = 4, //!< 完成
};

/**
 文件解压状态

 - BYDownloadTaskUnzipStateIdle: 空闲中
 - BYDownloadTaskUnzipStateRunning: 解压中
 - BYDownloadTaskUnzipStateCompleted: 解压完成
 */
typedef NS_ENUM(NSInteger, BYDownloadTaskUnzipState){
    BYDownloadTaskUnzipStateIdle = 0,      //!< 空闲中
    BYDownloadTaskUnzipStateRunning = 1,   //!< 解压中
    BYDownloadTaskUnzipStateCompleted = 2, //!< 解压完成
};

/**
 下载完成回调

 @param identifier 下载任务唯一标志
 @param extendInfo 扩展信息
 @param error 下载失败信息
 */
typedef void (^BYDownloadFinishedHandler)(NSString *identifier, NSDictionary *extendInfo, NSError *error);


/**
 下载进度回调

 @param identifier 下载任务唯一标志
 @param progress 下载进度
 @param extendInfo 扩展信息
 */
typedef void (^BYDownloadProgressHandler)(NSString *identifier, CGFloat progress, NSDictionary *extendInfo);

/**
 文件解压回调

 @param identifier 下载任务唯一标志
 @param extendInfo 扩展信息
 @param error 解压失败信息
 */
typedef void (^BYDownloadUnzipHandler)(NSString *identifier, NSDictionary *extendInfo, NSError *error);

/**
 解压完毕后是否删除原文件

 @param success 解压是否成功
 @return YES - 删除原文件，NO - 不删除原文件
 */
typedef BOOL(^BYUnzipFinishedDeleteFile)(BOOL success);


@interface BYDownloadTask : NSObject

/*!
 * @brief 下载进程的ID
 * 默认为下载链接md5字符串，当多个链接地址时以逗号拼接后再md5。
 */
@property (nonatomic, readonly) NSString *identifier;

/*!
 * @brief 下载链接集合(单个文件多个下载地址)，当第一个链接下载失败后会自动重试第二个下载链接，直到下载成功或所有下载链接均重试完毕，则下载完毕。
 */
@property (nonatomic, readonly) NSArray *downloadLinks;

/**
 server是否支持etag。默认不支持，使用Last-Modified校验。当erver支持etag时，优先使用etag。
 */
@property (nonatomic, assign) BOOL etagEnable;

/**
 下载进程当前状态
 */
@property (nonatomic, readonly) BYDownloadTaskState state;

/**
 文件解压状态
 */
@property (nonatomic, readonly) BYDownloadTaskUnzipState unzipState;

/*!
 * @brief 下载目标路径
 */
@property (nonatomic, readonly) NSString *targetPath;

/*!
 * @brief 下载后解压路径。只有设置此参数时，才会自动解压。
 */
@property (nonatomic, copy) NSString *unzipTargetPath;

/*!
 * @brief 当下载失败后，最大重试次数，默认为0，即不重试。
 * 此参数，仅当只有一个下载连接时有效。
 */
@property (nonatomic, assign) NSInteger maxRetries;

/**
 当下载完成后，空闲磁盘最小值。默认50*1024*1024。
 */
@property (nonatomic, assign) long long minRemainFreeSpace;

/**
 当手动取消下载任务时是否移除观察者，默认是YES，即移除。
 */
@property (nonatomic, assign) BOOL removeObserversWhenCancel;

/**
 解压完毕后是否删除原文件，默认无论解压成功或失败均删除原文件
 */
@property (nonatomic, copy) BYUnzipFinishedDeleteFile unzipFinishedDeleteFile;

/**
 下载进度回调线程。默认为主线程。
 */
@property (nonatomic, assign) dispatch_queue_t progressCallBackQueue;
/**
 下载完成回调线程。默认为主线程。
 */
@property (nonatomic, assign) dispatch_queue_t downloadFinishCallBackQueue;
/**
 解压完成回调线程。默认为主线程。
 */
@property (nonatomic, assign) dispatch_queue_t unzipFinishCallBackQueue;

/**
 外部参数，会在回调中传给外部
 */
@property (nonatomic, strong) NSDictionary *extendInfo;

/**
 初始化下载任务

 @param identifier 下载任务唯一标识。可为nil值，此时会使用默认identifier。
 @param links 下载地址集合
 @param targetPath 文件保存目的路径
 @return BYDownloadTask实例
 */
- (instancetype)initIdentifier:(NSString *)identifier links:(NSArray *)links targetPath:(NSString *)targetPath;

/**
 初始化下载任务

 @param identifier 下载任务唯一标识。可为nil值，此时会使用默认identifier。
 @param link 下载地址集合
 @param targetPath 文件保存目的路径
 @return BYDownloadTask实例
 */
- (instancetype)initIdentifier:(NSString *)identifier link:(NSString *)link targetPath:(NSString *)targetPath;


/**
 添加下载进度观察者

 @param observer 观察者
 @param handler  下载进度回调
 */
- (void)addObserver:(NSObject *)observer progressHandler:(BYDownloadProgressHandler)handler;

/**
 添加下载完成观察者
 
 @param observer 观察者
 @param handler  下载完成回调
 */
- (void)addObserver:(NSObject *)observer finishHandler:(BYDownloadFinishedHandler)handler;

/**
 添加解压完成观察者
 
 @param observer 观察者
 @param handler  解压完成回调
 */
- (void)addObserver:(NSObject *)observer unzipHandler:(BYDownloadUnzipHandler)handler;

/**
 开始下载
 */
- (void)start;

/**
 暂停下载
 */
- (void)pause;

/**
 继续下载
 */
- (void)resume;

/**
 取消下载
 */
- (void)cancel;

/**
 取消下载并删除临时文件
 */
- (void)cancelAndDeleteTempFile;

/**
 手动clear,该方法只有当属性removeObserversWhenCancel为NO时生效
 */
- (void)manualClear;
@end
