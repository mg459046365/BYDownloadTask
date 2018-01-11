//
//  ViewController.m
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/8.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import "ViewController.h"
#import "BYDownloadTask.h"
#import "BYDownloadManager.h"
#import "Model.h"
@interface ViewController ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, copy) NSString *dirPath;
@property (nonatomic, strong) BYDownloadTask *task;
@property (nonatomic, strong) Model *model;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 40)];
    self.label.textColor = [UIColor blackColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont systemFontOfSize:14.0f];
    [self.view addSubview:self.label];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 40)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"开始下载" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(100, CGRectGetMaxY(button.frame) + 60, 100, 40)];
    button1.backgroundColor = [UIColor redColor];
    [button1 setTitle:@"暂停下载" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button1];
    
    UIButton *button2 = [[UIButton alloc] initWithFrame:CGRectMake(100, CGRectGetMaxY(button1.frame) + 60, 100, 40)];
    button2.backgroundColor = [UIColor redColor];
    [button2 setTitle:@"继续下载" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
    
    UIButton *button3 = [[UIButton alloc] initWithFrame:CGRectMake(100, CGRectGetMaxY(button2.frame) + 60, 100, 40)];
    button3.backgroundColor = [UIColor redColor];
    [button3 setTitle:@"取消下载" forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button3];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *path = [paths[0] stringByAppendingPathComponent:@"BYDOWNLOAD"];
//    self.dirPath = path;
//    BOOL isDirectory;
//    BOOL exist = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
//    if (!exist || !isDirectory) {
//        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
//    }
    self.model = [[Model alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    NSArray *array = @[
//        @"https://mryj-hc.aipai.com/114/993529114/27d6bd619cff2d55eb3cbf30c4127c74.apk",
////        @"https://sessionpackage.dailyyoga.com.cn/session/package/com.dailyyoga.bbreathing_42.apk",
////        @"http://shouji.360tpcdn.com/161103/e462684be41f04dc69fdf067e345575c/com.dailyyoga.bbreathing_42.apk",
//        ];
//    NSString *targetPath = [self.dirPath stringByAppendingPathComponent:@"test.zip"];
//    self.task = [[BYDownloadTask alloc] initIdentifier:nil links:array targetPath:targetPath];
//    __weak typeof(self) weakSelf = self;
//    [self.task addObserver:self finishHandler:^(NSString *identifier, NSDictionary *extendInfo, NSError *error) {
//        [weakSelf downloadFinish:error];
//    }];
//    [self.task addObserver:self progressHandler:^(NSString *identifier, CGFloat progress, NSDictionary *extendInfo) {
//        [weakSelf updateProgress:progress];
//    }];
}

- (void)downloadFinish:(NSError *)error
{
    NSString *title = nil;
    NSString *msg = nil;
    if (error) {
        title = @"下载失败";
        msg = [error localizedDescription];
    }else{
        title = @"下载完成";
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:^{
        
    }];
}

- (void)updateProgress:(CGFloat)progress
{
    self.label.text = [NSString stringWithFormat:@"进度：%@",@(progress)];
}

- (void)start
{
    [self.model start];
//    [self.task start];
}

- (void)pause
{
    [self.model pause];
//    [self.task pause];
}

- (void)resume
{
    [self.model resume];
//    [self.task resume];
}

- (void)cancel
{
    NSLog(@"点击取消");
    [[BYDownloadManager manager] removeTaskWithIdentifer:self.model.task.identifier];
    self.model = nil;
//    [self.model cancel];
//    [self.task cancel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
