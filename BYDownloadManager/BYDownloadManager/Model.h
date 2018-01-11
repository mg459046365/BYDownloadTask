//
//  Model.h
//  BYDownloadManager
//
//  Created by Beryter on 2018/1/10.
//  Copyright © 2018年 Beryter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BYDownloadTask.h"
@interface Model : NSObject
@property (nonatomic, strong) BYDownloadTask *task;
- (void)start;
- (void)pause;
- (void)resume;
- (void)cancel;
@end
