//
//  TYAudioUnitPlayer.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class TYAudioUnitPlayer;
@protocol TYPlayerDelegate <NSObject>

- (void)onPlayToEnd:(TYAudioUnitPlayer *)player;

@end

@interface TYAudioUnitPlayer : NSObject

- (instancetype)initWithAudioFilePath:(NSString *)audioFilePath;
@property (nonatomic, weak) id<TYPlayerDelegate> delegate;
- (void)play;
- (double)getCurrentTime;

@end

NS_ASSUME_NONNULL_END
