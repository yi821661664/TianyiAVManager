//
//  TYAudioQueueRecorder.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioQueueRecorder : NSObject

- (instancetype)initWithSampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket;

@property(nonatomic,copy) NSString *filePath;
@property(nonatomic,assign) BOOL isRecording;
//开始播放
- (void)startRecord;
//停止播放
- (void)stopRecord;


@end

NS_ASSUME_NONNULL_END
