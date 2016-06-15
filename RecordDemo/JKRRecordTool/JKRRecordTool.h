//
//  JKRRecordTool.h
//  RecordDemo
//
//  Created by tronsis_ios on 16/6/12.
//  Copyright © 2016年 tronsis_ios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class JKRRecordTool;

@protocol JKRRecordToolDelegate <NSObject>

@optional
/** 音量刷新代理 */
- (void)recordTool:(JKRRecordTool *)recordTool recordvoiceDidChange:(NSInteger)voice;

/** 时间刷新代理 */
- (void)recordTool:(JKRRecordTool *)recordTool recordTimeDidChange:(CGFloat)time;

@end

@interface JKRRecordTool : NSObject

/** 录音工具的单例 */
+ (instancetype)sharedRecordTool;

/** 开始录音 */
- (void)startRecordingWithFileName:(NSString *)fileName;

/** 停止录音并保存录音文件 */
- (void)stopRecording;

/** 取消录音并清楚录音文件 */
- (void)cancelRecording;

/** 播放录音 */
- (void)playRecordingFileWithFileName:(NSString *)fileName;

/** 停止播放录音文件 */
- (void)stopPlaying;

/** 获取文件列表(文件名数组) */
- (NSMutableArray<NSString *> *)getRecordingFileList;

/** 获取文件列表(字典数组: name: FileName, time: FileDuration) */
- (NSMutableArray<NSDictionary<NSString *, id> *> *)getRecordingFileDictionaryList;

/** 
    
    {
        @"name": @"filename",
        @"time": @12.123
    }
 
 */

/** 删除录音文件 */
- (void)deleteRecordingFileWithFileName:(NSString *)fileName;

/** 销毁最近录制的录音文件 */
//- (void)destructionRecordingFile;

/** 检查是否存在改名称的录音文件 */
- (BOOL)checkIfExitWithFileName:(NSString *)fileName;

/** 根据录音文件名获取amr转码的数据 */
- (void)getAmrRecoderDataWithFileName:(NSString *)fileName success:(void (^)(NSData *amrData))success failure:(void (^)(NSError *error))failure;

/** 根据录音文件名获取文件大小 */
- (NSUInteger)getDataLengthWithFileName:(NSString *)fileName;

/** 根据NSData获取对应的Base64String */
- (NSString *)getBase64StringWithData:(NSData *)uploadData;

/** 根据录音文件名获取录音时长 */
- (CGFloat)getRecordingTimeWithFileName:(NSString *)fileName;

/** 修改文件名 */
- (BOOL)changeRecordingFileName:(NSString *)fileName withNewFileName:(NSString *)newFileName;

/** 当前录音的时间长度 */
@property (nonatomic, assign) CGFloat currentRecordingTime;

/** 录音文件总时长 */
@property(nonatomic, assign) CGFloat allRecordingTime;

@property (nonatomic, weak) id<JKRRecordToolDelegate> delegate;

@end
