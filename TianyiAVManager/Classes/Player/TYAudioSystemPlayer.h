//
//  TYAudioSystemPlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/16.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    TYAudioStatusError = 0,
    TYAudioStatusPause = 1,
    TYAudioStatusStop = 2,
    TYAudioStatusFinish = 3,
} TYAudioStatus;

typedef void(^TYAuidoFinishBlock)(TYAudioStatus finishStatus);

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioSystemPlayer : AVPlayer

/// 创建一个播放器
+ (TYAudioSystemPlayer *)creatWithPath:(NSString *)playPath;

/// 播放路径,支持本地路径,网络地址
@property(nonatomic, strong) NSString *playPath;
/// 标记,随机串
@property(nonatomic, strong) NSString *tagkey;
/// 回调 参数:正常完成true 停止false
@property(nonatomic, copy)   TYAuidoFinishBlock finishBlock;
/// 停止时是否回调finishBlock 默认 true
@property(nonatomic, assign) BOOL isStopCallFinish;
/// 播放异常时是否回调finishBlock 默认 true
@property(nonatomic, assign) BOOL isErrorCallFinish;
/// 仅仅准备一次,避免资源首次使用播放延迟高,默认false
@property(nonatomic, assign) BOOL isOnlyPrepare;
/// 重复播放次数
@property(nonatomic, assign) NSInteger repeatCount;
/// 播放回调间隔时间
@property(nonatomic, assign) CGFloat interval;
/// 播放速度
@property(nonatomic, assign) CGFloat speed;
/// 播放回调
@property(nonatomic, copy)   void(^progress)(CGFloat currentTime ,CGFloat duration);

/// 正常播放-> 当前播放时间/总时间
@property(nonatomic, assign) CGFloat currentTime;
@property(nonatomic, assign) CGFloat duration;

@property(nonatomic, assign) id delegate;

@property(nonatomic, assign) BOOL isPlayingToBackground;

@end

@interface TYAudioManager : NSObject

//单例处理
+ (TYAudioManager *)shared;

//串行: 停止上一个,处理完上一个的回调后开始播放
+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path;

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              finish:(TYAuidoFinishBlock)finishBlock;

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                              finish:(TYAuidoFinishBlock)finishBlock;

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                            interval:(NSTimeInterval)interval
                            progress:(void(^)(CGFloat currentTime, CGFloat duration))progress
                              finish:(TYAuidoFinishBlock)finishBlock;

//并行互不干扰
+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path;

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              finish:(TYAuidoFinishBlock)finishBlock;

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                              finish:(TYAuidoFinishBlock)finishBlock;

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                            interval:(NSTimeInterval)interval
                            progress:(void(^)(CGFloat currentTime, CGFloat duration))progress
                              finish:(TYAuidoFinishBlock)finishBlock;

+ (void)removePlayer:(TYAudioSystemPlayer *)audioPlayer;

+ (void)stopAllAudio;

@end

NS_ASSUME_NONNULL_END
