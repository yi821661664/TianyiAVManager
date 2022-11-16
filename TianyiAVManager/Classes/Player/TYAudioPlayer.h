//
//  TYAudioPlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    TYAudioPlayType_system = 0,     // 使用系统高级api
    TYAudioPlayType_audioUnit,      // 使用audioUnit
    TYAudioPlayType_audioQueue      // 使用audioQueue
} TYAudioPlayType;

typedef void(^TYAudioPlayerFinishBlock)(void);
typedef void(^TYAudioPlayerProgressBlock)(CGFloat currentTime, CGFloat duration);

/// 音频播放器
NS_ASSUME_NONNULL_BEGIN

@interface TYAudioPlayer : NSObject

+ (void)playAudioWith:(NSString *)path type:(TYAudioPlayType)type finish:(TYAudioPlayerFinishBlock)finish;

+ (void)playAudioWith:(NSString *)path type:(TYAudioPlayType)type progress:(TYAudioPlayerProgressBlock)progress finish:(TYAudioPlayerFinishBlock)finish;

@end

NS_ASSUME_NONNULL_END
