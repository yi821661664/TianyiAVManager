//
//  TYAudioUnitPlayer.h
//  TianyiFunc
//
//  Created by 易召强 on 2022/11/7.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class TYAudioUnitPlayer;

typedef void (^TYInputBlock)(AudioBufferList * _Nonnull bufferList);
typedef void (^TYInputBlockFull)(TYAudioUnitPlayer * _Nonnull player,
                                 AudioUnitRenderActionFlags * _Nonnull ioActionFlags,
                                 const AudioTimeStamp * _Nonnull inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList * _Nonnull ioData);

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioUnitPlayer : NSObject

@property (nonatomic,copy) TYInputBlock inputBlock;
@property (nonatomic,copy) TYInputBlockFull inputFullBlock;
- (void)initWithSampleRate:(UInt32)sampleRate bitsPerChannel:(UInt32)bitsPerChannel;
- (void)start;
- (void)stop;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
