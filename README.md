# Record
Recordtool, wav to amr and data to base64String. 录音工具类，wav转amr，NSData转Base64String

// 获取工具了
+ (instancetype)sharedRecordTool;

// 开始录音并设置保存的录音文件名
- (void)startRecordingWithFileName:(NSString *)fileName;

// 停止并保存录音
- (void)stopRecording;

// 取消并删除录音
- (void)cancelRecording;

// 播放录音
- (void)playRecordingFileWithFileName:(NSString *)fileName;
