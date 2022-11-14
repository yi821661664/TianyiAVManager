//
//  TYAudioRecorder.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    TYAudioRecordType_system = 0,     // 使用系统高级api
    TYAudioRecordType_audioUnit,      // 使用audioUnit
    TYAudioRecordType_audioQueue      // 使用audioQueue
} TYAudioRecordType;

/// 音频录制器
NS_ASSUME_NONNULL_BEGIN

@interface TYAudioRecorder : NSObject

/// 录音方式
@property(nonatomic, assign) TYAudioRecordType recordType;
/// 是否正在录音
@property(nonatomic, assign) BOOL isRecording;
/// 开始录音
-(void)start;
/// 停止录音
-(void)stop;

@end

NS_ASSUME_NONNULL_END
