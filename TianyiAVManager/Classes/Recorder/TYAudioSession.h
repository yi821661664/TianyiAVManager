//
//  TYAudioSession.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioSession : NSObject

+ (void)setPlayAndRecord;
+ (void)setPlayback;
+ (void)setSampleRate:(double)sampleRate duration:(double)duration;

@end

NS_ASSUME_NONNULL_END
