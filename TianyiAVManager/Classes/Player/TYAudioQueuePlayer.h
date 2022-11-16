//
//  TYAudioQueuePlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioQueuePlayer : NSObject

- (instancetype)initWithChannel:(UInt32)channel;
- (void)start;
- (void)stop;
- (void)putAudioData:(void *)data length:(UInt32)length;

@end

NS_ASSUME_NONNULL_END
