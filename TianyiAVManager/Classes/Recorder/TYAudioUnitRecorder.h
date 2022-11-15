//
//  TYAudioUnitRecorder.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TYAudioUnitRecorder;

@protocol TYAudioUnitRecorderDelegate <NSObject>

///获取到音频数据
- (void)audioRecorder:(TYAudioUnitRecorder *)audioRecorder didRecoredAudioData:(void *)data length:(unsigned int)length;

@end

@interface TYAudioUnitRecorder : NSObject

@property (nonatomic, weak) id<TYAudioUnitRecorderDelegate> delegate;

// pitchShift：负数代表女声，0代表原音，正数代表男声，数值越大声音越尖锐
- (instancetype)initWithPitchShift:(Float32)pitchShift
                        sampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket;

- (void)startRecord;
- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
