//
//  TYAudioUnitPlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol TYAudioUnitPlayerDataSourse <NSObject>

- (void)readDataToBuffer:(AudioBufferList *_Nonnull)ioData length:(UInt32)inNumberFrames;

@end

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioUnitPlayer : NSObject

@property (nonatomic, weak) id<TYAudioUnitPlayerDataSourse> dataSource;

- (instancetype)initWithAsbd:(AudioStreamBasicDescription)asbd;

- (void)startPlay;
- (void)stopPlay;

@end

NS_ASSUME_NONNULL_END
