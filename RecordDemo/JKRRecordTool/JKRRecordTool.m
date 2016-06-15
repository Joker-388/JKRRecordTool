//
//  JKRRecordTool.m
//  RecordDemo
//
//  Created by tronsis_ios on 16/6/12.
//  Copyright © 2016年 tronsis_ios. All rights reserved.
//

#import "JKRRecordTool.h"
#import "VoiceConverter.h"

@interface JKRRecordTool ()<AVAudioRecorderDelegate>

/** 录音文件地址 */
@property (nonatomic, strong) NSURL *recordFileUrl;

/** 定时器 */
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) AVAudioSession *session;

/** 录音对象 */
@property (nonatomic, strong) AVAudioRecorder *recorder;

/** 播放器对象 */
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, assign) int renameMark;

@property (nonatomic, assign) BOOL hasRemark;

@end

@implementation JKRRecordTool

static JKRRecordTool *instance;
#pragma mark - 单例
+ (instancetype)sharedRecordTool {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [super allocWithZone:zone];
        }
    });
    return instance;
}

#pragma mark - 开始录音
- (void)startRecordingWithFileName:(NSString *)fileName {
    
    // 录音时停止播放
    [self stopPlaying];
    
    // 真机环境下需要的代码
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
    
    self.session = session;
    
    self.recorder = [self recorderWithFileName:fileName];
    
    [self.recorder record];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    [timer fire];
    self.timer = timer;
    
}

#pragma mark - 每隔0.1s调用一次代理
- (void)updateTimer:(NSTimer *)timer {
    
    [self.recorder updateMeters];
    double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
    float result  = 10 * (float)lowPassResults;
//    NSLog(@"%f", result);
    NSInteger no = 0;
    if (result > 0 && result <= 1.3) {
        no = 1;
    } else if (result > 1.3 && result <= 2) {
        no = 2;
    } else if (result > 2 && result <= 3.0) {
        no = 3;
    } else if (result > 3.0 && result <= 5.0) {
        no = 4;
    } else if (result > 5.0 && result <= 10) {
        no = 5;
    } else if (result > 10 && result <= 40) {
        no = 6;
    } else if (result > 40) {
        no = 7;
    }
    
    if ([self.delegate respondsToSelector:@selector(recordTool:recordvoiceDidChange:)]) {
        [self.delegate recordTool:self recordvoiceDidChange: no];
    }
    
    if ([self.delegate respondsToSelector:@selector(recordTool:recordTimeDidChange:)]) {
        [self.delegate recordTool:self recordTimeDidChange: self.currentRecordingTime];
    }
}

#pragma mark - 停止并保存录音
- (void)stopRecording {
    if ([self.recorder isRecording]) {
        [self.recorder stop];
        [self.timer invalidate];
    }
}

#pragma mark - 取消录音并清楚录音文件
- (void)cancelRecording {
    [self stopRecording];
    [self destructionRecordingFile];
}

#pragma mark - 播放录音文件
- (void)playRecordingFileWithFileName:(NSString *)fileName {
    // 1.获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",fileName, [fileName isEqualToString:@"upload11034"] ? @"amr" : @"wav"]];
    
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    
    // 播放时停止录音
    [self.recorder stop];
    
    // 正在播放就返回
    if ([self.player isPlaying]) {
        [self stopPlaying];
    };
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.recordFileUrl error:NULL];
    
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.player play];

}

#pragma mark - 停止播放
- (void)stopPlaying {
    [self.player stop];
}

#pragma mark - 获取录音文件列表
- (NSMutableArray<NSString *> *)getRecordingFileList {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSArray *pathList = [manager subpathsAtPath:path];
    
    NSMutableArray *audioPathList = [NSMutableArray array];
    
    for (NSString *audioPath in pathList) {
        if ([audioPath.pathExtension isEqualToString:@"wav"]
//            || [audioPath.pathExtension isEqualToString:@"amr"]
            ) {
            NSString *str = [audioPath substringToIndex:audioPath.length - 4];
            [audioPathList addObject:str];
        }
    }
    
    return audioPathList;
}

#pragma mark - 获取文件列表(字典数组: Name: FileName, Time: FileDuration)
- (NSMutableArray<NSDictionary<NSString *,id> *> *)getRecordingFileDictionaryList {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSArray *pathList = [manager subpathsAtPath:path];
    
    NSMutableArray *audioPathList = [NSMutableArray array];
    
    for (NSString *audioPath in pathList) {
        if ([audioPath.pathExtension isEqualToString:@"wav"]
            //            || [audioPath.pathExtension isEqualToString:@"amr"]
            ) {
            NSString *name = [audioPath substringToIndex:audioPath.length - 4];
            
            CGFloat time = [self getRecordingTimeWithFileName:name];
            
            NSDictionary *file = @{@"name": name, @"time": [NSNumber numberWithFloat:time]};
            
            [audioPathList addObject:file];
        }
    }
    
    return audioPathList;
}

#pragma mark - 根据录音文件名获取对应amr格式文件
- (void)getAmrRecoderDataWithFileName:(NSString *)fileName success:(void (^)(NSData *))success failure:(void (^)(NSError *))failure {
    if (![self checkIfExitWithFileName:fileName]) {
        NSError *error = [NSError errorWithDomain:@"File not exit" code:0 userInfo:nil];
        failure(error);
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",fileName]];
        
        NSString *toFilePath = [path stringByAppendingPathComponent:@"upload11034.amr"];
        
        NSURL *toFileURL = [NSURL URLWithString:toFilePath];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (toFileURL) {
            [fileManager removeItemAtURL:toFileURL error:NULL];
        }
        
        [VoiceConverter ConvertWavToAmr:filePath amrSavePath:toFilePath];
        
        NSData *data = [NSData dataWithContentsOfFile:toFilePath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            success(data);
        });
        
    });
}

#pragma mark - 获取录音文件的大小
- (NSUInteger)getDataLengthWithFileName:(NSString *)fileName {
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",fileName, [fileName isEqualToString:@"upload11034"] ? @"amr" : @"wav"]];
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    return data.length;
}

#pragma mark - 检查录音文件是否存在
- (BOOL)checkIfExitWithFileName:(NSString *)fileName {
    BOOL result = NO;
    
    NSMutableArray *allFileName = [self getRecordingFileList];
    
    for (NSString *name in allFileName) {
        if ([fileName isEqualToString:name]) {
            result = YES;
            break;
        }
    }
    
    return result;
}

#pragma mark - 删除录音文件
- (void)deleteRecordingFileWithFileName:(NSString *)fileName {
    // 1.获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",fileName, [fileName isEqualToString:@"upload11034"] ? @"amr" : @"wav"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:NULL];
}

#pragma mark - 根据NSData对象获取对应的Base64String
- (NSString *)getBase64StringWithData:(NSData *)uploadData {
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(NSUTF16BigEndianStringEncoding);
    
    NSString *str_iso_8859_1 = [[NSString alloc] initWithData:uploadData encoding:enc];
    
    NSData *data_iso_8859_1 = [str_iso_8859_1 dataUsingEncoding:enc];
    
//    Byte *byte = (Byte *)[data_iso_8859_1 bytes];
    
//    for (int i=0 ; i<[data_iso_8859_1 length]; i++) {
//        NSLog(@"byte = %d",byte[i]);
//    }
    
    NSString *str_base64 = [data_iso_8859_1 base64EncodedStringWithOptions:0];
    
    return str_base64;
}

#pragma mark - 删除当前操作的录音文件(内部处理方法)
- (void)destructionRecordingFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (self.recordFileUrl) {
        [fileManager removeItemAtURL:self.recordFileUrl error:NULL];
    }
}

- (CGFloat)currentRecordingTime {
    return self.recorder.currentTime;
}

#pragma mark - AVAudioRecorder对象创建方法(内部处理方法)
- (AVAudioRecorder *)recorderWithFileName:(NSString *)fileName {
    
    // 1.获取沙盒地址
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",fileName]];
    self.recordFileUrl = [NSURL fileURLWithPath:filePath];
    NSLog(@"%@", filePath);
    
    // 3.设置录音的一些参数
    NSMutableDictionary *setting = [NSMutableDictionary dictionary];
    // 音频格式
    setting[AVFormatIDKey] = @(kAudioFormatLinearPCM);
    // 录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    setting[AVSampleRateKey] = @(8000);
    // 音频通道数 1 或 2
    setting[AVNumberOfChannelsKey] = @(1);
    // 线性音频的位深度  8、16、24、32
    setting[AVLinearPCMBitDepthKey] = @(16);
    //录音的质量
    setting[AVEncoderAudioQualityKey] = [NSNumber numberWithInt:AVAudioQualityHigh];
    
    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:setting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    
    [recorder prepareToRecord];
    
    return recorder;
}

#pragma mark - 根据录音文件名获取录音时长
- (CGFloat)getRecordingTimeWithFileName:(NSString *)fileName {
    
    if (![self checkIfExitWithFileName:fileName]) {
        return 0.0;
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",fileName]];
    
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
    
    return player.duration;
}

#pragma mark - 录音总时间
- (CGFloat)allRecordingTime {
    
    CGFloat time = 0;
    
    NSArray *recordFiles = [self getRecordingFileList];
    
    for (NSString *name in recordFiles) {
        
        time += [self getRecordingTimeWithFileName:name];
    }
    
    return time;
}

#pragma mark - 修改文件名
- (BOOL)changeRecordingFileName:(NSString *)fileName withNewFileName:(NSString *)newFileName {
    if (![self checkIfExitWithFileName:fileName]) {
        return NO;
    }
    
    if ([self checkIfExitWithFileName:newFileName]) {
        
        _renameMark = 1;
        
        _hasRemark = NO;
        
        newFileName = [self getUnrenameWithName:newFileName];
        
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav",fileName]];
    
    NSString *newFilePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.wav", newFileName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    return [fileManager moveItemAtPath:filePath toPath:newFilePath error:nil];
}

- (NSString *)getUnrenameWithName:(NSString *)name {
    
    if (_hasRemark) {
        name = [name substringToIndex:name.length - 3];
    }
    
    name = [NSString stringWithFormat:@"%@(%d)", name, _renameMark];
    
    _renameMark += 1;
    _hasRemark = YES;
    
    if (![self checkIfExitWithFileName:name]) {
        return name;
    }else {
        return [self getUnrenameWithName:name];
    }
}

#pragma mark - AVAudioRecorderDelegate(内部处理方法)
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    if (flag) {
        [self.session setActive:NO error:nil];
    }
}

@end
