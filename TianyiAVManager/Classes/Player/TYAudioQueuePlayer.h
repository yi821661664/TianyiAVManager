//
//  TYAudioQueuePlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioQueuePlayer : NSObject

- (instancetype)initWithAudioFilePath:(NSString *)audioFilePath;

- (void)startPlay;

- (void)llystartPlay;

- (void)pause;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
