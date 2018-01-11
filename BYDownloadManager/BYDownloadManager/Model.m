//
//  Model.m
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/10.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import "Model.h"

@interface Model()
@property (nonatomic, strong) NSString *dirPath;
@end

@implementation Model

- (void)start
{
    NSLog(@"开始下载");
    [self.task start];
}

- (void)pause
{
    NSLog(@"暂停");
    [self.task pause];
}

- (void)resume
{
    NSLog(@"继续");
    [self.task resume];
}

- (void)cancel
{
    NSLog(@"取消");
    [self.task cancel];
}

- (NSString *)dirPath
{
    if (!_dirPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths[0] stringByAppendingPathComponent:@"BYDOWNLOAD"];
        BOOL isDirectory;
        BOOL exist = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
        if (!exist || !isDirectory) {
            [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _dirPath = path;
    }
    return _dirPath;
}

- (BYDownloadTask *)task
{
    if (!_task) {
        NSArray *array = @[
                           @"https://mryj-hc.aipai.com/114/993529114/27d6bd619cff2d55eb3cbf30c4127c74.apk",
                           //        @"https://sessionpackage.dailyyoga.com.cn/session/package/com.dailyyoga.bbreathing_42.apk",
                           //        @"http://shouji.360tpcdn.com/161103/e462684be41f04dc69fdf067e345575c/com.dailyyoga.bbreathing_42.apk",
                           ];
        NSString *targetPath = [self.dirPath stringByAppendingPathComponent:@"test.zip"];
        self.task = [[BYDownloadTask alloc] initIdentifier:nil links:array targetPath:targetPath];
        __weak typeof(self) weakSelf = self;
        [self.task addObserver:self finishHandler:^(NSString *identifier, NSDictionary *extendInfo, NSError *error) {
            [weakSelf downloadFinish:error];
        }];
        [self.task addObserver:self progressHandler:^(NSString *identifier, CGFloat progress, NSDictionary *extendInfo) {
            [weakSelf updateProgress:progress];
        }];
    }
    return _task;
}

- (void)downloadFinish:(NSError *)error
{
    NSLog(@"下载完毕");
}

- (void)updateProgress:(CGFloat)progress
{
    NSLog(@"下载进度=%@",@(progress));
}
- (void)dealloc
{
    NSLog(@"model被释放");
}
@end
