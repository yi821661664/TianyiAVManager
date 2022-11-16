//
//  TYAudioSystemPlayer.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/16.
//

#import "TYAudioSystemPlayer.h"
#import <UIKit/UIKit.h>
#import "TYAudioSession.h"

@interface TYAudioSystemPlayer()

@property(nonatomic, assign) BOOL isCallFinishing;
@property(nonatomic, strong) id timeObserver;

@end

@implementation TYAudioSystemPlayer

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeCustomTimeObserve];
    NSLog(@"播放器释放");
}

- (void)removeCustomTimeObserve{
    if (_timeObserver) {
        [self removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

+ (TYAudioSystemPlayer *)creatWithPath:(NSString *)playPath{
    NSURL *pathUrl = [TYAudioSystemPlayer handlePlayURLWithPath:playPath];
    if (pathUrl == nil) {
        return nil;
    }
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:pathUrl];
    TYAudioSystemPlayer *player = [[TYAudioSystemPlayer alloc] initWithPlayerItem:item];
    player.playPath = playPath;
    return player;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.volume = 1.0;
        self.isErrorCallFinish = true;
        self.interval = 1;
        self.repeatCount = 1;
        [self addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioPlayerDidEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
    }
    return self;
}

- (void)play{
    [TYAudioSession setPlayAndRecord];
    [super play];
    if (self.speed > 0 && self.rate != self.speed) {
        self.rate = self.speed;
        // 针对速率播放下的音频回音问题处理
        self.currentItem.audioTimePitchAlgorithm = self.speed != 1 ? AVAudioTimePitchAlgorithmTimeDomain : AVAudioTimePitchAlgorithmLowQualityZeroLatency;
    }
}

- (void)setSpeed:(CGFloat)speed {
    _speed = speed;
    
    if (self.speed > 0 && self.rate != self.speed && self.rate != 0) {
        self.rate = self.speed;
        
        self.currentItem.audioTimePitchAlgorithm = self.speed != 1 ? AVAudioTimePitchAlgorithmTimeDomain : AVAudioTimePitchAlgorithmLowQualityZeroLatency;
        
    }
}

- (void)setProgress:(void (^)(CGFloat, CGFloat))progress {
    _progress = [progress copy];
    [self removeCustomTimeObserve];
    if (_progress && self.interval > 0) {
        __weak typeof(self)weakSelf = self;
       _timeObserver = [self addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(self.interval, NSEC_PER_SEC)
                                           queue:NULL
                                      usingBlock:^(CMTime time) {
                                          [weakSelf handleTime:time];
                                      }];
    }
}

- (void)handleTime:(CMTime)time {
    CGFloat currentTime = CMTimeGetSeconds(self.currentItem.currentTime);
    CGFloat duration = CMTimeGetSeconds(self.currentItem.duration);
    if (self.progress) {
        self.progress(currentTime, duration);
    }
}

/** 监听播放器事件 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]){
        if (self.isOnlyPrepare) {
            [TYAudioManager removePlayer:self];
        }
        if (self.currentItem.status == AVPlayerStatusFailed) {
            if (self.isErrorCallFinish) {
                [self callFinish:TYAudioStatusError];
            }
        }else if (self.currentItem.status == AVPlayerStatusReadyToPlay){
            // 能正常播放
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

//播放结束
- (void)audioPlayerDidEnd:(NSNotification *)notice{
    if (self.currentItem == notice.object) {
        [self callFinish:TYAudioStatusFinish];
        self.repeatCount = self.repeatCount - 1;
        if (self.repeatCount <= 0) {
            [TYAudioManager removePlayer:self];
        }else{
            [self seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            [self play];
        }
    }
}

- (void)callFinish:(TYAudioStatus)audioStatus{
    if (self.isCallFinishing) {
        return;
    }
    self.isCallFinishing = true;
    !self.finishBlock ?: self.finishBlock(audioStatus);
    self.isCallFinishing = false;
}

- (CGFloat)currentTime{
    return CMTimeGetSeconds(self.currentItem.currentTime);
}

- (CGFloat)duration{
    return CMTimeGetSeconds(self.currentItem.duration);
}

// 随机字符表
static const NSString *TMAudioRandomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
- (NSString *)tagkey{
    if (_tagkey == nil) {
        NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
        for (int i = 0; i < 10; i++) {
            [randomString appendFormat: @"%C", [TMAudioRandomAlphabet characterAtIndex:arc4random_uniform((u_int32_t)[TMAudioRandomAlphabet length])]];
        }
        _tagkey = randomString;
    }
    return _tagkey;
}

+ (NSURL *)handlePlayURLWithPath:(NSString *)playPath{
    NSString *errorStr = nil;
    NSURL *pathURL = nil;
    if (playPath != nil && [playPath isKindOfClass:NSString.class] && playPath.length > 0) {
        if ([playPath hasPrefix:@"https://"] || [playPath hasPrefix:@"http://"]) {
            pathURL = [NSURL URLWithString:playPath];
        }else{
            if (!([playPath containsString:@"/"] && [playPath hasPrefix:@"/"])) {
                NSString *fileName = playPath;
                if ([playPath containsString:@".mp3"]) {
                    playPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@""];
                }else{
                    playPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp3"];
                }
            }
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:playPath];
            if (fileExists) {
                pathURL = [NSURL fileURLWithPath:playPath];
            }else{
                errorStr = [NSString stringWithFormat:@"异常(文件不存在)-> playPath:%@",playPath];
            }
        }
    }else{
        errorStr = [NSString stringWithFormat:@"异常(文件路径为空)-> playPath值为空"];
    }
    if (errorStr) {
//        NSLog
    }
    return pathURL;
}

@end

@interface TYAudioManager()

@property(nonatomic, assign) BOOL isInBackground;  // 程序处于后台
@property(nonatomic, strong) NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> *chainDictionary;
@property(nonatomic, strong) NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> *batchDictionary;
@property(nonatomic, strong) NSMutableDictionary<NSString* ,AVAudioPlayer*> *shortDictionary;
@property(nonatomic, strong) NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> *destoryDictionary;

@end

@implementation TYAudioManager

+ (TYAudioManager *)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TYAudioManager alloc] init];
        [sharedInstance setdefaultConfig];
    });
    return sharedInstance;
}

- (void)setdefaultConfig{
    self.chainDictionary = [NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> dictionary];
    self.batchDictionary = [NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> dictionary];
    self.shortDictionary = [NSMutableDictionary<NSString* ,AVAudioPlayer*> dictionary];
    self.destoryDictionary = [NSMutableDictionary<NSString* ,TYAudioSystemPlayer*> dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    if (@available(iOS 14.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioSessionInterruption:) name:AVAudioSessionInterruptionNotification
                                                   object:nil];
    }
}


- (void)appWillResignActive:(NSNotification *)notice {
    self.isInBackground = true;
    [self pause];
}

- (void)appDidBecomeActive:(NSNotification *)notice {
    self.isInBackground = false;
    [self resume];
}

- (void)pause {
    NSArray *chainAllKeys = self.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [self.chainDictionary objectForKey:key];
        player.isPlayingToBackground = (player.rate > 0 || player.isPlayingToBackground);
        [player pause];
    }
    NSArray *batchAllKeys = self.batchDictionary.allKeys;
    for (NSString *key in batchAllKeys) {
        TYAudioSystemPlayer *player = [self.batchDictionary objectForKey:key];
        player.isPlayingToBackground = (player.rate > 0 || player.isPlayingToBackground);
        [player pause];
    }
}

- (void)resume {
    NSArray *chainAllKeys = self.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [self.chainDictionary objectForKey:key];
        if (player.isPlayingToBackground) {
            player.isPlayingToBackground = false;
            [player play];
        }
    }
    NSArray *batchAllKeys = self.batchDictionary.allKeys;
    for (NSString *key in batchAllKeys) {
        TYAudioSystemPlayer *player = [self.batchDictionary objectForKey:key];
        if (player.isPlayingToBackground) {
            player.isPlayingToBackground = false;
            [player play];
        }
    }
}
  
- (void)audioSessionInterruption:(NSNotification *)notice{
    if (self.isInBackground) {
        return;
    }
    if ([notice.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
        if ([notice.userInfo.allKeys containsObject:@"AVAudioSessionInterruptionTypeKey"]) {
            int status = [[notice.userInfo valueForKey:@"AVAudioSessionInterruptionTypeKey"] intValue];
            if (status) {
                [self pause];
            }else{
                [self resume];
            }
        }
    }
}


//串行: 停止上一个,处理完上一个的回调后开始播放
+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
{
    return [TYAudioManager playChainWithPath:path repeat:1 interval:0 progress:nil finish:nil];
}

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              finish:(TYAuidoFinishBlock)finishBlock
{
    return [TYAudioManager playChainWithPath:path repeat:1 interval:0 progress:nil finish:finishBlock];
}

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                              finish:(TYAuidoFinishBlock)finishBlock
{
    return [TYAudioManager playChainWithPath:path repeat:repeatCount interval:0 progress:nil finish:finishBlock];
}

+ (TYAudioSystemPlayer *)playChainWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                            interval:(NSTimeInterval)interval
                            progress:(void(^)(CGFloat currentTime, CGFloat duration))progress
                              finish:(TYAuidoFinishBlock)finishBlock
{
    [TYAudioManager stopChainCallFinish:true];
    TYAudioSystemPlayer *player = [TYAudioSystemPlayer creatWithPath:path];
    if (player) {
        [TYAudioManager.shared.chainDictionary setObject:player forKey:player.tagkey];
        player.finishBlock = finishBlock;
        player.repeatCount = repeatCount;
        player.interval = interval;
        player.progress = progress;
        [player play];
    }else{
        !finishBlock ?: finishBlock(TYAudioStatusError);
    }
    return player;
}

//并行互不干扰
+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
{
    return [TYAudioManager playBatchWithPath:path repeat:1 interval:0 progress:nil finish:nil];
}

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              finish:(TYAuidoFinishBlock)finishBlock
{
    return [TYAudioManager playBatchWithPath:path repeat:1 interval:0 progress:nil finish:finishBlock];
}

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                              finish:(TYAuidoFinishBlock)finishBlock
{
    return [TYAudioManager playBatchWithPath:path repeat:repeatCount interval:0 progress:nil finish:finishBlock];
}

+ (TYAudioSystemPlayer *)playBatchWithPath:(NSString *)path
                              repeat:(NSInteger)repeatCount
                            interval:(NSTimeInterval)interval
                            progress:(void(^)(CGFloat currentTime, CGFloat duration))progress
                              finish:(TYAuidoFinishBlock)finishBlock
{
    TYAudioSystemPlayer *player = [TYAudioSystemPlayer creatWithPath:path];
    if (player) {
        [TYAudioManager.shared.batchDictionary setObject:player forKey:player.tagkey];
        player.finishBlock = finishBlock;
        player.repeatCount = repeatCount;
        player.interval = interval;
        player.progress = progress;
        [player play];
    }else{
        !finishBlock ?: finishBlock(TYAudioStatusError);
    }
    return player;
}

/// 播放短音频
+ (AVAudioPlayer *)playShortAudio:(NSString *)audioName{
    return [TYAudioManager createShortAudio:audioName play:true];
}
+ (void)prepareShortAudio:(NSString *)audioName{
    [TYAudioManager createShortAudio:audioName play:false];
}
+ (void)stopShortAudio{
    NSArray *chainAllKeys = TYAudioManager.shared.shortDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        AVAudioPlayer *player = [TYAudioManager.shared.shortDictionary objectForKey:key];
        [player stop];
    }
}

//获取音频时长
+ (CGFloat)audioDurationFromPath:(NSString *)path{
    NSURL *pathURL = [TYAudioSystemPlayer handlePlayURLWithPath:path];
    if (pathURL) {
        NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:pathURL options:dic];
        CMTime audioDuration = audioAsset.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        return audioDurationSeconds;
    }
    return 0;
}


+ (AVAudioPlayer *)createShortAudio:(NSString *)audioName play:(BOOL)isPlay{
    // 暂时开发阶段使用，正式版本使用else中的代码
    AVAudioPlayer *audioPlay = [TYAudioManager.shared.shortDictionary objectForKey:audioName];
    if (audioPlay == nil) {
        NSURL *pathURL = [TYAudioSystemPlayer handlePlayURLWithPath:audioName];
        if (pathURL && [pathURL isFileURL]) {
            NSError *error = nil;
            audioPlay = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:&error];
            if (audioPlay && error == nil) {
                [TYAudioManager.shared.shortDictionary setObject:audioPlay forKey:audioName];
                [audioPlay prepareToPlay];
            }else{
                NSString *errorStr = [NSString stringWithFormat:@"异常(播放器创建失败)-> 音频名称(本地短音频):%@, error:%@",audioName ,error];
                NSLog(@"%@",errorStr);
            }
        }
    }
    if (isPlay) {
        [audioPlay play];
    }
    return audioPlay;

    
}

//重新播放音频,调用回调
+ (void)playChainAudio{
    [TYAudioManager playChainCallFinish:true];
}
+ (void)playBatchAudio{
    [TYAudioManager playBatchCallFinish:true];
}
+ (void)playAllAudio{
    [TYAudioManager playChainCallFinish:true];
    [TYAudioManager playBatchCallFinish:true];
}
+ (void)playAudio:(TYAudioSystemPlayer *)player{
    [player play];
}

//暂停音频,调用回调
+ (void)pauseChainAudio{
    [TYAudioManager pauseChainCallFinish:true];
}
+ (void)pauseBatchAudio{
    [TYAudioManager pauseBatchCallFinish:true];
}
+ (void)pauseAllAudio{
    [TYAudioManager pauseChainCallFinish:true];
    [TYAudioManager pauseBatchCallFinish:true];
}

+ (void)pauseAudio:(TYAudioSystemPlayer *)player{
    [player pause];
    [player callFinish:TYAudioStatusPause];
}

//跳转时间
+ (void)seekChainTime:(CGFloat)time{
    NSArray *chainAllKeys = TYAudioManager.shared.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.chainDictionary objectForKey:key];
        [TYAudioManager seekChainTime:time auido:player];
    }
}
+ (void)seekChainTime:(CGFloat)time auido:(TYAudioSystemPlayer *)player{
    time = MAX(0, time);
    time = player.duration > 0 ? MIN(time, player.duration) : time;
    [player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_MSEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

//停止音频,调用回调
+ (void)stopChainAudio{
    [TYAudioManager stopChainCallFinish:true];
}
+ (void)stopBatchAudio{
    [TYAudioManager stopBatchCallFinish:true];
}
+ (void)stopAllAudio{
    [TYAudioManager stopChainCallFinish:true];
    [TYAudioManager stopBatchCallFinish:true];
}
+ (void)stopAudio:(TYAudioSystemPlayer *)player{
    [player pause];
    [TYAudioManager removePlayer:player];
    [player callFinish:TYAudioStatusStop];
}

//播放播放音频
+ (void)playChainCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.chainDictionary objectForKey:key];
        [player play];
    }
}
+ (void)playBatchCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.batchDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.batchDictionary objectForKey:key];
        [player play];
    }
}

//暂停播放音频
+ (void)pauseChainCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.chainDictionary objectForKey:key];
        [player pause];
        if (isCallFinish) {
            [player callFinish:TYAudioStatusPause];
        }
    }
}
+ (void)pauseBatchCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.batchDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.batchDictionary objectForKey:key];
        [player pause];
        if (isCallFinish) {
            [player callFinish:TYAudioStatusPause];
        }
    }
}

//停止播放音频
+ (void)stopChainCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.chainDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.chainDictionary objectForKey:key];
        [player pause];
        [TYAudioManager removePlayer:player];
        if (isCallFinish) {
            [player callFinish:TYAudioStatusStop];
        }
    }
}
+ (void)stopBatchCallFinish:(BOOL)isCallFinish{
    NSArray *chainAllKeys = TYAudioManager.shared.batchDictionary.allKeys;
    for (NSString *key in chainAllKeys) {
        TYAudioSystemPlayer *player = [TYAudioManager.shared.batchDictionary objectForKey:key];
        [player pause];
        [TYAudioManager removePlayer:player];
        if (isCallFinish) {
            [player callFinish:TYAudioStatusStop];
        }
    }
}
+ (void)stopAllCallFinish:(BOOL)isCallFinish{
    [TYAudioManager stopChainCallFinish:isCallFinish];
    [TYAudioManager stopBatchCallFinish:isCallFinish];
}

+ (void)removePlayer:(TYAudioSystemPlayer *)audioPlayer {
    if (audioPlayer && audioPlayer.tagkey) {
        
        BOOL isPlaying = NO;
        
        NSMutableArray *allPlayers = [NSMutableArray array];
        [allPlayers addObjectsFromArray:TYAudioManager.shared.chainDictionary.allValues];
        [allPlayers addObjectsFromArray:TYAudioManager.shared.batchDictionary.allValues];
        
        for (TYAudioSystemPlayer *player in allPlayers) {
            if (player.rate != 0) {
                isPlaying = YES;
                break;
            }
        }
        
        if (isPlaying) {
            [TYAudioManager.shared.destoryDictionary setObject:audioPlayer forKey:audioPlayer.tagkey];
            [audioPlayer removeCustomTimeObserve];
            if (TYAudioManager.shared.destoryDictionary.count > 15) {
                [TYAudioManager.shared.destoryDictionary removeAllObjects];
            }
            NSLog(@"TOTO - 播放中，不移除, %@, %@, %@", @(TYAudioManager.shared.chainDictionary.count), @(TYAudioManager.shared.batchDictionary.count), @(TYAudioManager.shared.destoryDictionary.count));

        } else {
            [TYAudioManager.shared.destoryDictionary removeAllObjects];
            NSLog(@"TOTO - destoryDictionary all");
        }
        
        [TYAudioManager.shared.chainDictionary removeObjectForKey:audioPlayer.tagkey];
        [TYAudioManager.shared.batchDictionary removeObjectForKey:audioPlayer.tagkey];
        
        NSLog(@"TOTO - 移除, %@, %@, %@", @(TYAudioManager.shared.chainDictionary.count), @(TYAudioManager.shared.batchDictionary.count), @(TYAudioManager.shared.destoryDictionary.count));
    }
}

@end
