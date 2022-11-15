//
//  TYAudioRecorder.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

/// 音频录制器
NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TYAudioRecordType_system = 0,     // 使用系统高级api
    TYAudioRecordType_audioUnit,      // 使用audioUnit
    TYAudioRecordType_audioQueue      // 使用audioQueue
} TYAudioRecordType;

@interface TYAudioRecorder : NSObject

+ (instancetype)shared;

/// 录音方式
@property(nonatomic, assign) TYAudioRecordType recordType;
/// 是否正在录音
@property(nonatomic, assign) BOOL isRecording;
/// 录音声道，默认双声道
@property(nonatomic, assign) UInt32 channel;
/// 采样率，默认44.1kHz
@property(nonatomic, assign) UInt32 sampleRate;
/// 位深，默认16
@property(nonatomic, assign) UInt32 bits;

/// 开始录音
-(void)startRecord;
/// 停止录音
-(void)stopRecord;

@end

NS_ASSUME_NONNULL_END
