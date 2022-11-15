//
//  TYAudioUnitFileWriter.h
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TYAudioUnitFileWriter : NSObject

@property(copy, nonatomic) NSString* filePath;

- (instancetype)initWithSampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket;
- (void)openFileWithFilePath:(NSString *)filePath;
- (void)writeData:(void *)data length:(int)length;
- (void)closeFile;

@end

NS_ASSUME_NONNULL_END
