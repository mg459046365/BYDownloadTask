//
//  BYDownloadTask.m
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import "BYDownloadTask.h"
#import "SSZipArchive.h"
#import <sys/mount.h>

/// 开始下载通知
 NSString *const BYDownloadStartNotification = @"BYDownloadStartNotification";
/// 暂停下载通知
 NSString *const BYDownloadPauseNotification = @"BYDownloadPauseNotification";
/// 继续下载通知
 NSString *const BYDownloadResumeNotification = @"BYDownloadResumeNotification";
/// 完成下载通知
 NSString *const BYDownloadFinishNotification = @"BYDownloadFinishNotification";
/// 开始解压通知
 NSString *const BYDownloadUnzipStartNotification = @"BYDownloadUnzipStartNotification";
/// 解压完毕通知
 NSString *const BYDownloadUnzipFinishNotification = @"BYDownloadUnzipFinishNotification";

/// 下载任务ID
 NSString *const BYDownloadKeyIdentifier = @"BYDownloadKeyIdentifier";
/// 下载任务被手动取消
 NSString *const BYDownloadKeyManualCancel = @"BYDownloadKeyManualCancel";
/// 下载任务扩展信息
 NSString *const BYDownloadKeyExtendInfo = @"BYDownloadKeyExtendInfo";
/// 下载任务目标路径
 NSString *const BYDownloadKeyTargetPath = @"BYDownloadKeyTargetPath";
/// 下载任务问价大小
 NSString *const BYDownloadKeyFileSize = @"BYDownloadKeyFileSize";
/// 下载任务是否成功
 NSString *const BYDownloadkeySuccess = @"BYDownloadkeySuccess";
/// 下载任务链接集合
 NSString *const BYDownloadKeyLinks = @"BYDownloadKeyLinks";
/// 下载任务错误信息
 NSString *const BYDownloadKeyError = @"BYDownloadKeyError";
/// 下载任务当前下载链接
 NSString *const BYDownloadKeyURL = @"BYDownloadKeyURL";


@interface BYDownloadTask()<NSURLSessionDataDelegate>
/*!
 * @brief 下载任务
 */
@property (nonatomic, strong) NSURLSessionDataTask *task;

/*!
 * @brief 文件的总长度
 */
@property (nonatomic, assign) NSInteger totalLength;

/*!
 * @brief 下载进度
 */
@property (nonatomic, assign) NSInteger downloadedLength;

/*!
 * @brief session
 */
@property (nonatomic, strong) NSURLSession *session;

/**
 下载进程当前状态
 */
@property (nonatomic, assign) BYDownloadTaskState state;
/**
 文件解压状态
 */
@property (nonatomic, assign) BYDownloadTaskUnzipState unzipState;
/**
 下载数据缓存句柄
 */
@property (nonatomic, strong) NSFileHandle *fileHandle;

/*!
 * @brief 下载完毕后需要执行的block集合
 */
@property (nonatomic, strong) NSMapTable *finishMapTable;

/*!
 * @brief 下载进度执行block集合
 */
@property (nonatomic, strong) NSMapTable *progressMapTable;

/**
 解压进度回调block集合
 */
@property (nonatomic, strong) NSMapTable *unzipMapTable;

/**
 当前下载链接地址
 */
@property (nonatomic, copy) NSString *currentLink;

/**
 当前链接的索引
 */
@property (nonatomic, assign) NSInteger currentLinkIndex;

/**
 操作线程
 */
@property (nonatomic, strong) dispatch_queue_t taskQueue;

/**
 创建下载任务线程
 */
@property (nonatomic, strong) dispatch_queue_t createTaskQueue;

/**
 重试的次数
 */
@property (nonatomic, assign) NSInteger retryCount;

/**
 手动取消下载标记
 */
@property (nonatomic, assign) BOOL manualCancel;

/**
 清理过的
 */
@property (nonatomic, assign) BOOL cleaned;

/**
 磁盘空间不足。YES-不足，NO-足够的空间
 */
@property (nonatomic, assign) BOOL noEnoughSpace;

@end

@implementation BYDownloadTask

- (instancetype)initIdentifier:(NSString *)identifier links:(NSArray *)links targetPath:(NSString *)targetPath
{
    if (self = [super init]) {
        _identifier = identifier;
        _downloadLinks = links;
        _targetPath = targetPath;
        _currentLinkIndex = 0;
        _state = BYDownloadTaskStateReady;
        _taskQueue = dispatch_queue_create("BY_DOWNLOAD_TASK_QUEUE", NULL);
        _createTaskQueue = dispatch_queue_create("BY_DOWNLOAD_TASK_CREATE_QUEUE", NULL);
        _removeObserversWhenCancel = YES;
        _minRemainFreeSpace = 50*1024*1024;
        //生成默认identifier
        if (!identifier || ![identifier by_deleteAllSpaceAndNewline]) {
            if (links && links.count > 0) {
                _identifier = [[links componentsJoinedByString:@","] by_md5String];
            }else{
                _identifier = [[NSString stringWithFormat:@"%@",@([[NSDate date] timeIntervalSince1970])] by_md5String];
            }
        }
    }
    return self;
}

- (instancetype)initIdentifier:(NSString *)identifier link:(NSString *)link targetPath:(NSString *)targetPath
{
    if (self = [super init]) {
        _identifier = identifier;
        _targetPath = targetPath;
        _currentLinkIndex = 0;
        _state = BYDownloadTaskStateReady;
        _taskQueue = dispatch_queue_create("BY_DOWNLOAD_TASK_QUEUE", NULL);
        _createTaskQueue = dispatch_queue_create("BY_DOWNLOAD_TASK_CREATE_QUEUE", NULL);
        _removeObserversWhenCancel = YES;
        _minRemainFreeSpace = 50*1024*1024;
        if (!link) {
            _downloadLinks = @[];
        }else{
            _downloadLinks = @[link];
        }
        //生成默认identifier
        if (!identifier || ![identifier by_deleteAllSpaceAndNewline]) {
            if ([link by_deleteAllSpaceAndNewline]) {
                _identifier = [link by_md5String];
            }else{
                _identifier = [[NSString stringWithFormat:@"%@",@([[NSDate date] timeIntervalSince1970])] by_md5String];
            }
        }
    }
    return self;
}

#pragma mark - Func

/**
 校验参数的合法性
 */
- (NSError *)checkArgumentsValid
{
    //校验targetPath是否为空
    NSError *error = nil;
    if (![self.targetPath by_deleteAllSpaceAndNewline]){
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey:@"目标路径不合法"}];
        return error;
    }
    //校验下载链接集合是否为空
    if (!self.downloadLinks || self.downloadLinks.count == 0) {
        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey:@"下载链接为空"}];
        return error;
    }
    
    //校验是否存在有效下载链接
    BOOL vaild = NO;
    for (NSString *link in self.downloadLinks) {
        NSString *tmp = [link by_deleteAllSpaceAndNewline];
        if (tmp) {
            vaild = YES;
        }
    }
    
    if (!vaild) {
        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:@{NSLocalizedDescriptionKey:@"下载链接不合法"}];
        return error;
    }
    return nil;
}

- (NSError *)preTask
{
    NSError *error = [self checkArgumentsValid];
    if (error) return error;
    
    for (NSInteger i = 0;i < self.downloadLinks.count; i++)
    {
        self.currentLinkIndex = i;
        self.currentLink = self.downloadLinks[i];
        error = [self configTask:self.downloadLinks[i]];
        if (!error) {
            break;
        }
    }
    return error;
}

- (void)pushNotification:(NSString *)noteName error:(NSError *)error;
{
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setValue:@(self.manualCancel) forKey:BYDownloadKeyManualCancel];
    [info setValue:self.identifier forKey:BYDownloadKeyIdentifier];
    [info setValue:self.extendInfo forKey:BYDownloadKeyExtendInfo];
    [info setValue:self.targetPath forKey:BYDownloadKeyTargetPath];
    [info setValue:@(self.totalLength) forKey:BYDownloadKeyFileSize];
    [info setValue:@(error ? NO : YES) forKey:BYDownloadkeySuccess];
    [info setValue:self.downloadLinks forKey:BYDownloadKeyLinks];
    [info setValue:self.currentLink forKey:BYDownloadKeyURL];
    [info setValue:error forKey:BYDownloadKeyError];
    [[NSNotificationCenter defaultCenter] postNotificationName:noteName object:nil userInfo:info];
}

- (void)start
{
     [[BYDownloadManager manager] addTask:self];
     [self pushNotification:BYDownloadStartNotification error:nil];
     [self startRetry:NO];
}

- (void)startRetry:(BOOL)retry
{
    //防止重复创建task，将处理逻辑放入createTaskQueue线程中
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.createTaskQueue, ^{
        if (weakSelf.task) {
            [weakSelf.task resume];
            return;
        }
        NSError *error = nil;
        if (weakSelf.cleaned) {
            error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileLockingError userInfo:@{NSLocalizedDescriptionKey:@"下载任务已被清理，失效。请手动移除该下载任务，并生实例化新的BYDownloadTask对象"}];
        }
        if (error) {
            [weakSelf handleFinishBlock:error];
            return;
        }
        error = [weakSelf preTask];
        if (error) {
            [weakSelf handleFinishBlock:error];
            return;
        }
        [weakSelf.task resume];
    });
}

- (void)pause
{
     [self.task suspend];
     [self pushNotification:BYDownloadPauseNotification error:nil];
}

- (void)resume
{
    [self.task resume];
    [self pushNotification:BYDownloadResumeNotification error:nil];
}

- (void)cancel
{
    self.manualCancel = YES;
    [self.task cancel];
}

- (void)cancelAndDeleteTempFile
{
    self.manualCancel = YES;
    [self.task cancel];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fmg = [[NSFileManager alloc] init];
        for (NSString *link in weakSelf.downloadLinks) {
            NSString *tempFilePath = [weakSelf tempFilePathWithLink:link];
            [fmg removeItemAtPath:tempFilePath error:nil];
        }
    });
    
}

- (void)addObserver:(NSObject *)observer progressHandler:(BYDownloadProgressHandler)handler
{
    if (self.state == BYDownloadTaskStateCanceling || self.state == BYDownloadTaskStateCompleted)
    {
        //下载完毕或者取消下载不再接收观察者
        return;
    }
    if (!observer) {
        return;
    }
    if (!handler) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.taskQueue, ^{
        [weakSelf.progressMapTable setObject:handler forKey:observer];
    });
}

- (void)setTask:(NSURLSessionDataTask *)task
{
    if (_task) {
        [_task removeObserver:self forKeyPath:@"state"];
    }
    if (task) {
        [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    }
    _task = task;
}

- (void)addObserver:(NSObject *)observer finishHandler:(BYDownloadFinishedHandler)handler
{
    if (self.state == BYDownloadTaskStateCanceling || self.state == BYDownloadTaskStateCompleted)
    {
        //下载完毕或者取消下载不再接收观察者
        return;
    }
    if (!observer) {
        return;
    }
    if (!handler) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.taskQueue, ^{
        [weakSelf.finishMapTable setObject:handler forKey:observer];
    });
}

- (void)addObserver:(NSObject *)observer unzipHandler:(BYDownloadUnzipHandler)handler
{
    if (self.state == BYDownloadTaskStateCanceling || self.state == BYDownloadTaskStateCompleted)
    {
        //下载完毕或者取消下载不在接收观察者
        return;
    }
    if (!observer) {
        return;
    }
    if (!handler) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.taskQueue, ^{
        [weakSelf.unzipMapTable setObject:handler forKey:observer];
    });
}

- (void)downloadSuccess
{
    [self.fileHandle closeFile];
    NSFileManager *fmg = [[NSFileManager alloc] init];
    [fmg removeItemAtPath:self.targetPath error:NULL];
    NSError *error = nil;
    [fmg moveItemAtPath:[self tempFilePath] toPath:self.targetPath error:&error];
    __weak typeof(self) weakSelf = self;
    [self handleFinishBlock:error];
    if (error) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *link in weakSelf.downloadLinks) {
            //删除缓存文件
            NSString *tempPath = [weakSelf tempFilePathWithLink:link];
            [fmg removeItemAtPath:tempPath error:NULL];
        }
    });
    
    if (!self.unzipTargetPath) {
        [self clear];
        return;
    }
    
    dispatch_async(self.taskQueue, ^{
        [weakSelf.finishMapTable removeAllObjects];
    });
    //解压文件
    self.unzipState = BYDownloadTaskUnzipStateRunning;
    [self pushNotification:BYDownloadUnzipStartNotification error:nil];
    __block NSError *unzipError = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, self.taskQueue, ^{
        unzipError = [weakSelf unzipFile];
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [weakSelf pushNotification:BYDownloadUnzipFinishNotification error:unzipError];
        [weakSelf clear];
    });
}

- (NSError *)unzipFile
{
    BOOL zipSuccess = [SSZipArchive unzipFileAtPath:self.targetPath toDestination:self.unzipTargetPath];
    if (self.unzipFinishedDeleteFile && self.unzipFinishedDeleteFile(zipSuccess))
    {
        NSFileManager *fmg = [[NSFileManager alloc] init];
        [fmg removeItemAtPath:self.targetPath error:NULL];
    }
    NSError *error = nil;
    if (!zipSuccess) {
        error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey:@"文件解压失败"}];
    }
    NSArray *array = [[self.finishMapTable objectEnumerator] allObjects];
     __weak typeof(self) weakSelf = self;
    for (BYDownloadUnzipHandler block in array) {
        dispatch_async(weakSelf.unzipFinishCallBackQueue ?: dispatch_get_main_queue(), ^{
            block(weakSelf.identifier, weakSelf.extendInfo, error);
        });
    }
    self.unzipState = BYDownloadTaskUnzipStateCompleted;
    return error;
}

- (void)downloadFailure:(NSError *)error
{
    if (self.manualCancel) {
        //取消下载
        NSError *tmpError = error;
        if (!tmpError) {
            tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"取消下载"}];
        }
        [self handleFinishBlock:tmpError];
        return;
    }
    if (self.noEnoughSpace) {
        //取消下载
        NSError *tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"空间不足"}];
        [self handleFinishBlock:tmpError];
        return;
    }
    if (self.downloadLinks.count == 1 && self.maxRetries > 0 && self.retryCount <self.maxRetries && self.state != BYDownloadTaskStateCanceling) {
        //重试
        self.retryCount ++;
        [self.task cancel];
        self.task = nil;
        [self startRetry:YES];
    }
    self.currentLinkIndex ++;
    if (self.currentLinkIndex >= self.downloadLinks.count) {
        //下载失败
        [self handleFinishBlock:error];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.createTaskQueue, ^{
        NSError *error = nil;
        for (NSInteger i = weakSelf.currentLinkIndex;i < weakSelf.downloadLinks.count; i++)
        {
            weakSelf.currentLinkIndex = i;
            weakSelf.currentLink = weakSelf.downloadLinks[i];
            error = [weakSelf configTask:weakSelf.downloadLinks[i]];
            if (!error) {
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [weakSelf handleFinishBlock:error];
            }else{
                [weakSelf.task resume];
            }
        });
    });
}

- (void)handleFinishBlock:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, self.taskQueue, ^{
        NSArray *array = [[weakSelf.finishMapTable objectEnumerator] allObjects];
        for (BYDownloadFinishedHandler block in array) {
            dispatch_async(weakSelf.downloadFinishCallBackQueue ?: dispatch_get_main_queue(), ^{
                block(weakSelf.identifier, weakSelf.extendInfo, error);
            });
        }
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [weakSelf pushNotification:BYDownloadFinishNotification error:error];
        if (!error) {
            if (!weakSelf.unzipTargetPath) {
                //不需要解压,下载完成
                [weakSelf clear];
            }
            return;
        }
        if (!weakSelf.manualCancel || (weakSelf.manualCancel && weakSelf.removeObserversWhenCancel)) {
            [weakSelf clear];
        }
        weakSelf.noEnoughSpace = NO;
        weakSelf.manualCancel = NO;
    });
}

- (void)handleProgressBlock:(CGFloat)progress
{
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.taskQueue, ^{
        NSArray *array = [[weakSelf.progressMapTable objectEnumerator] allObjects];
        for (BYDownloadProgressHandler block in array) {
            dispatch_async(weakSelf.progressCallBackQueue ?: dispatch_get_main_queue(), ^{
                block(weakSelf.identifier, progress, weakSelf.extendInfo);
            });
        }
    });
}

- (void)manualClear
{
    if (self.removeObserversWhenCancel) {
        return;
    }
    [self clear];
}

- (void)clearObservers
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.taskQueue, ^{
        [weakSelf.progressMapTable removeAllObjects];
        [weakSelf.finishMapTable removeAllObjects];
        [weakSelf.unzipMapTable removeAllObjects];
    });
}

- (void)clear
{
    self.cleaned = YES;
    [self clearObservers];
    //session retain self，need invalidate
    [self.session invalidateAndCancel];
    [self.task cancel];
    self.task = nil;
    self.session = nil;
    self.currentLink = nil;
    self.currentLinkIndex = 0;
    self.downloadedLength = 0;
    self.totalLength = 0;
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    [[BYDownloadManager manager] removeTaskWithIdentifer:self.identifier];
}

- (void)dealloc
{
    NSLog(@"%@被释放",NSStringFromClass([self class]));
}

#pragma mark - Properties
- (NSError *)configTask:(NSString *)link
{
    if (self.task) {
        //清空原有task以及相关数据
        [self.task cancel];
        self.task = nil;
        self.totalLength = 0;
        self.currentLink = nil;
        self.downloadedLength = 0;
        [self.fileHandle closeFile];
        self.fileHandle = nil;
    }
    NSString *tempFilePath = [self tempFilePathWithLink:link];
    NSUInteger downloadedLength = [self tempFileLength:tempFilePath];
    NSFileManager *fmg = [[NSFileManager alloc] init];
    if (![fmg fileExistsAtPath:tempFilePath]) {
        // 创建缓存文件
        BOOL success = [fmg createFileAtPath:tempFilePath contents:nil attributes:nil];
        if (!success) {
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:@{NSLocalizedDescriptionKey:@"temp文件创建失败"}];
            return error;
        }
    }
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:link]];
    // 设置请求头
    // Range : bytes=xxx-xxx
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", downloadedLength];
    [request setValue:range forHTTPHeaderField:@"Range"];
    // 创建一个Data任务
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    self.totalLength = 0;
    self.downloadedLength = downloadedLength;
    self.task = task;
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:tempFilePath];
    return nil;
}

- (NSURLSession *)session{
    
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.beryter.www"];
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    }
    return _session;
}

#pragma mark - NSURLSessionDataDelegate

//接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        return;
    }
    //获取服务器这次请求返回数据的总长度
//    NSInteger contentLength = [tempResponse.allHeaderFields[@"Content-Length"] integerValue];
    long long expectedContentLength = response.expectedContentLength;
    self.totalLength = expectedContentLength + self.downloadedLength;
    self.noEnoughSpace = expectedContentLength >= ([self freeDiskSpaceByte] - self.minRemainFreeSpace);
    if (self.noEnoughSpace) {
        //当手机剩余空间不足时，下载失败
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    //接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

//接收服务器下载数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //写入数据
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    //下载进度
    self.downloadedLength += data.length;
    CGFloat currentProgress = self.downloadedLength * 1.00 / self.totalLength;
    [self handleProgressBlock:currentProgress];
}

//请求完毕
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        [self downloadFailure:error];
        return;
    }
    [self downloadSuccess];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"state"]) {
        switch ([change[NSKeyValueChangeNewKey] integerValue]) {
            case NSURLSessionTaskStateRunning:
                self.state = BYDownloadTaskStateRunning;
                break;
            case NSURLSessionTaskStateSuspended:
                self.state = BYDownloadTaskStateSuspended;
                break;
            case NSURLSessionTaskStateCanceling:
                self.state = BYDownloadTaskStateCanceling;
                break;
            case NSURLSessionTaskStateCompleted:
                self.state = BYDownloadTaskStateCompleted;
                break;
        }
    }
}

#pragma mark - Properties

- (NSMapTable *)finishMapTable
{
    if (!_finishMapTable) {
        _finishMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableCopyIn];
    }
    return _finishMapTable;
}

- (NSMapTable *)progressMapTable
{
    if (!_progressMapTable) {
        _progressMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableCopyIn];
    }
    return _progressMapTable;
}

- (NSMapTable *)unzipMapTable
{
    if (!_unzipMapTable) {
        _unzipMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableCopyIn];
    }
    return _unzipMapTable;
}


- (NSUInteger)tempFileLength:(NSString *)path
{
    NSFileManager *fmg = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSDictionary *fileInfo = [fmg attributesOfItemAtPath:path error:&error];
    if (error) {
        return 0;
    }
    if (!fileInfo) {
        return 0;
    }
    return [fileInfo fileSize];
}

/**
 下载文件缓存路径

 @return 下载文件缓存路径
 */
- (NSString *)tempFilePathWithLink:(NSString *)link
{
    if (![link by_deleteAllSpaceAndNewline]) {
        return nil;
    }
    NSString *md5 = [link by_md5String];
    NSString *tempPath = [[BYDownloadManager manager].cacheDir stringByAppendingPathComponent:md5];
    return tempPath;
}

- (NSString *)tempFilePath
{
    return [self tempFilePathWithLink:self.currentLink];
}

//手机剩余空间获取
- (long long) freeDiskSpaceByte{
    struct statfs buf;
    long long freespace = -1;
    if(statfs("/var", &buf) >= 0){
        freespace = (long long)(buf.f_bsize * buf.f_bfree);
    }
    return freespace;
}

@end
