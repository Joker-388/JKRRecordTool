//
//  ViewController.m
//  RecordDemo
//
//  Created by tronsis_ios on 16/6/12.
//  Copyright © 2016年 tronsis_ios. All rights reserved.
//

#import "ViewController.h"
#import "JKRRecordTool.h"
#import "AFNetworking/AFHTTPSessionManager.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, JKRRecordToolDelegate>

@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@property (weak, nonatomic) IBOutlet UIButton *uploadBtn;

@property (weak, nonatomic) IBOutlet UIButton *showBtn;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UILabel *allTimeLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *voiceLabel;

@property (strong, nonatomic) NSMutableArray<NSDictionary<NSString *, id> *> *recordingFiles;

/** 录音工具 */
@property (nonatomic, strong) JKRRecordTool *recordTool;

@end

@implementation ViewController

static NSString *identifier = @"cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordTool = [JKRRecordTool sharedRecordTool];
    self.recordTool.delegate = self;
    
    self.startBtn.layer.cornerRadius = 10;
    
    [self.startBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
    [self.startBtn setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
    
    // 录音按钮
    [self.startBtn addTarget:self action:@selector(recordBtnDidTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.startBtn addTarget:self action:@selector(recordBtnDidTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.startBtn addTarget:self action:@selector(recordBtnDidTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    
    // 上传按钮
    [self.uploadBtn addTarget:self action:@selector(upload) forControlEvents:UIControlEventTouchUpInside];
    
    // 显示列表
    [self.showBtn addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
    
    [self resetView];

}

#pragma mark - 录音按钮事件
// 按下
- (void)recordBtnDidTouchDown:(UIButton *)recordBtn {
    [self.recordTool startRecordingWithFileName:[NSString stringWithFormat:@"%c%c%c%c%c", 'A' + arc4random() % 26, 'A' + arc4random() % 26, '0' + arc4random() % 10, '0' + arc4random() % 10, '0' + arc4random() % 10]];
}

// 点击
- (void)recordBtnDidTouchUpInside:(UIButton *)recordBtn {
    double currentTime = self.recordTool.currentRecordingTime;
    NSLog(@"%lf", currentTime);
    if (currentTime < 2) {
        [self alertWithMessage:@"说话时间太短"];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{

            [self.recordTool cancelRecording];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetView];
            });
        });
    } else {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            [self.recordTool stopRecording];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resetView];
            });
        });
        // 已成功录音
        NSLog(@"已成功录音");
    }
}

// 手指从按钮上移除
- (void)recordBtnDidTouchDragExit:(UIButton *)recordBtn {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [self.recordTool cancelRecording];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alertWithMessage:@"已取消录音"];
            [self resetView];
        });
    });
}

- (void)resetView {
    self.timeLabel.text = @"0.0";
    self.voiceLabel.progress = 0.0;
    self.allTimeLabel.text = [NSString stringWithFormat:@"%f", self.recordTool.allRecordingTime];
    [self.tableView reloadData];
}

#pragma mark - 获取录音文件列表 
- (void)show {
    _recordingFiles = self.recordingFiles;
    
    [self.tableView reloadData];
}

#pragma mark - 上传
- (void)upload {
    
    [self.recordTool getAmrRecoderDataWithFileName:self.recordingFiles[self.tableView.indexPathForSelectedRow.row][@"name"] success:^(NSData *amrData) {
        
        NSString *base64Str = [self.recordTool getBase64StringWithData:amrData];
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionary];
        parameter[@"token"] = @"MTgxfDNzdnA3d2JuY2V8MTQ2NTgxMTIxMDkyNA==";
        parameter[@"deviceId"] = @"123456789000027";
        parameter[@"binLength"] = [NSString stringWithFormat:@"%zd", amrData.length];
        parameter[@"bin"] = base64Str;
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        
        [manager POST:@"http://120.24.73.180/dogchain/secure/pet/upload_voice" parameters:parameter progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSLog(@"%@", responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            NSLog(@"%@", error.localizedDescription);
            
        }];
    } failure:^(NSError *error) {
        
    }];
    
}

#pragma mark - 弹窗提示
- (void)alertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recordingFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    cell.textLabel.text =  [NSString stringWithFormat:@"%@ : %f", self.recordingFiles[indexPath.row][@"name"], [self.recordingFiles[indexPath.row][@"time"] floatValue]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.recordTool playRecordingFileWithFileName:self.recordingFiles[indexPath.row][@"name"]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewRowAction *delegateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [self.recordTool deleteRecordingFileWithFileName:self.recordingFiles[indexPath.row][@"name"]];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        self.allTimeLabel.text = [NSString stringWithFormat:@"%f", self.recordTool.allRecordingTime];
    }];
    
    UITableViewRowAction *renameAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"重命名" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if ([self.recordTool changeRecordingFileName:self.recordingFiles[indexPath.row][@"name"] withNewFileName:@"Joker"]) {
            [self.tableView reloadData];
        }
    }];
    
    UITableViewRowAction *action3 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"播放" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if ([self.recordTool changeRecordingFileName:self.recordingFiles[indexPath.row][@"name"] withNewFileName:@"Joker"]) {
            [self.tableView reloadData];
        }
    }];
    
    
    UITableViewRowAction *action4 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"标记" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        if ([self.recordTool changeRecordingFileName:self.recordingFiles[indexPath.row][@"name"] withNewFileName:@"Joker"]) {
            [self.tableView reloadData];
        }
    }];
    
    return @[delegateAction, renameAction, action3, action4];
}

#pragma mark - recordToolDelegate
- (void)recordTool:(JKRRecordTool *)recordTool recordTimeDidChange:(CGFloat)time {
    self.timeLabel.text = [NSString stringWithFormat:@"%0.1lffs",time];
    NSLog(@"%f >>> %f", time, self.recordTool.currentRecordingTime);
}

- (void)recordTool:(JKRRecordTool *)recordTool recordvoiceDidChange:(NSInteger)voice {
    self.voiceLabel.progress = voice / 7.0;
}

#pragma mark - lazy
- (NSMutableArray *)recordingFiles {
    return [self.recordTool getRecordingFileDictionaryList];
}

@end
