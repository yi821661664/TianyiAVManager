//
//  TYAudioRecorder.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import "TYAudioRecorder.h"
#import "TYAudioSession.h"
#import "TYAudioUnitRecorder.h"
#import "TYAudioQueueRecorder.h"

@interface TYAudioRecorder()<TYAudioUnitRecorderDelegate,AVAudioRecorderDelegate>

@property(nonatomic, strong) NSString *pcmFilePath;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) AVAudioRecorder *audioRecorder;  // 系统高级Api
@property(nonatomic, strong) TYAudioUnitRecorder *audiounitRecorder;  // audioUnit
@property(nonatomic, strong) TYAudioQueueRecorder *audioQueueRecorder; // audioqueue

@end

@implementation TYAudioRecorder

+ (instancetype) shared{
    static dispatch_once_t onceToken;
    static TYAudioRecorder *kPcmRecorder = nil;
    dispatch_once(&onceToken, ^{
        kPcmRecorder = [[TYAudioRecorder alloc] init];
    });
    return kPcmRecorder;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sampleRate = 48000;
        _bits = 16;
        _channel = 2;
        NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _pcmFilePath = [NSString stringWithFormat:@"%@/TYRecord", directory];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_pcmFilePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_pcmFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

- (void)startRecord {
    if (_isRecording) {
        return;
    }
    [TYAudioSession setPlayAndRecord];
    _isRecording = YES;
    if (_audiounitRecorder) {
        [_audiounitRecorder stop];
    }
    _filePath =  [NSString stringWithFormat:@"%@/record.pcm", _pcmFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
    if (_recordType == TYAudioRecordType_system) {
        if (!_audioRecorder) {
            _filePath =  [NSString stringWithFormat:@"%@/test.caf", _pcmFilePath];
            NSURL *url = [NSURL URLWithString:_filePath];
            NSError *error = nil;
            _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:[self getAudioRecordDic] error:&error];
            if (error) {
                NSLog(@"开启录音失败");
                return;
            }
            _audioRecorder.delegate = self;
            _audioRecorder.meteringEnabled = YES;
        }
        if ([_audioRecorder isRecording]) {
            [_audioRecorder record];
        }
    } else if (_recordType == TYAudioRecordType_audioUnit) {
        if (!_audiounitRecorder) {
            _audiounitRecorder = [[TYAudioUnitRecorder alloc] init];
            _audiounitRecorder.delegate = self;
        }
        [_audiounitRecorder start];
    } else {
        if (!_audioQueueRecorder) {
            _audioQueueRecorder = [[TYAudioQueueRecorder alloc] initWithSampleRate:_sampleRate bitsPerChannel:_bits channelsPerFrame:_channel bytesPerPacket:1];
            _audioQueueRecorder.filePath = _filePath;
        }
        [_audioQueueRecorder startRecord];
    }
}

- (void)stopRecord {
    _isRecording = NO;
    if (_recordType == TYAudioRecordType_system) {
        if ([_audioRecorder isRecording]) {
            [_audioRecorder stop];
        }
    } else if (_recordType == TYAudioRecordType_audioUnit) {
        [_audiounitRecorder stop];
    } else {
        if (_audioQueueRecorder.isRecording) {
            [_audioQueueRecorder stopRecord];
        }
    }
}

- (NSDictionary *)getAudioRecordDic {
    return @{
        AVFormatIDKey : @(kAudioFormatLinearPCM),
        AVSampleRateKey : @(_sampleRate),
        AVNumberOfChannelsKey : @(_channel),
        AVLinearPCMBitDepthKey : @(_bits),
        AVLinearPCMIsFloatKey : @(YES)
    };
}

#pragma mark - audioUnitRecorder delegate
- (void)audioRecorder:(TYAudioUnitRecorder *)audioRecorder didRecoredbufferList:(AudioBufferList *)bufferList {
    AudioBuffer audioBuffer = bufferList->mBuffers[0];// 左耳机buffer
    NSData *audioData = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
    NSFileHandle * fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
    if(fileHandle == nil) {
        return;
    }
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:audioData];
    [fileHandle closeFile];
}

#pragma  mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

@end
