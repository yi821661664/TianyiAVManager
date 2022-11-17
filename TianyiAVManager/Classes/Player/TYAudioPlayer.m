//
//  TYAudioPlayer.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import "TYAudioPlayer.h"
#import "TYAudioSystemPlayer.h"
#import "TYAudioQueuePlayer.h"
#import "TYAudioUnitPlayer.h"

@interface TYAudioPlayer()

@property(nonatomic, assign) TYAudioPlayType type;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) TYAudioPlayerFinishBlock finish;
@property(nonatomic, copy) TYAudioPlayerProgressBlock progress;
@property(nonatomic, strong) TYAudioQueuePlayer *queuePlayer;
@property(nonatomic, strong) TYAudioUnitPlayer *unitPlayer;

@end

@implementation TYAudioPlayer

+ (void)playAudioWith:(NSString *)path type:(TYAudioPlayType)type finish:(TYAudioPlayerFinishBlock)finish {
    TYAudioPlayer *player = [TYAudioPlayer shared];
    player.path = path;
    player.type = type;
    player.finish = finish;
    [player setup];
}

+ (void)playAudioWith:(NSString *)path type:(TYAudioPlayType)type progress:(TYAudioPlayerProgressBlock)progress finish:(TYAudioPlayerFinishBlock)finish {
    TYAudioPlayer *player = [TYAudioPlayer shared];
    player.path = path;
    player.type = type;
    player.finish = finish;
    player.progress = progress;
    [player setup];
}

+ (void)stopAllAuido {
    [TYAudioManager stopAllAudio];
}

+ (TYAudioPlayer *)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TYAudioPlayer alloc] init];
    });
    return sharedInstance;
}


- (void)setup {
    if (self.path.length <= 0) {
        return;
    }
    // pcm数据的播放才考虑audioUnit,audioqueue播放，不考虑播放进度的回调
    if ([[self.path pathExtension] isEqualToString:@"pcm"]) {
        if (self.type == TYAudioPlayType_audioUnit) {
            self.unitPlayer = [[TYAudioUnitPlayer alloc] initWithAudioFilePath:self.path];
            [self.unitPlayer play];
        } else {
            self.queuePlayer = [[TYAudioQueuePlayer alloc] initWithAudioFilePath:self.path];
            [self.queuePlayer startPlay];
        }
    // 如果是http数据，或者mp3等音频数据，直接使用系统高级api播放
    } else {
        __weak typeof(self)weakSelf = self;
        [TYAudioManager playBatchWithPath:self.path repeat:1 interval:0 progress:^(CGFloat currentTime, CGFloat duration) {
            if (weakSelf.progress) {
                weakSelf.progress(currentTime,duration);
            }
        } finish:^(TYAudioStatus finishStatus) {
            if (weakSelf.finish) {
                weakSelf.finish();
            }
        }];
    }
}

@end
