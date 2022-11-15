//
//  TYAudioRecorder.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import "TYAudioRecorder.h"
#import "TYAudioSession.h"
#import "TYAudioUnitRecorder.h"
#import "TYAudioUnitFileWriter.h"
#import "TYAudioQueueRecorder.h"

@interface TYAudioRecorder()<TYAudioUnitRecorderDelegate,AVAudioRecorderDelegate>

@property(nonatomic, strong) NSString *pcmFilePath;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) AVAudioRecorder *audioRecorder;  // 系统高级Api
@property(nonatomic, strong) TYAudioUnitRecorder *audiounitRecorder;  // audioUnit
@property(nonatomic, strong) TYAudioQueueRecorder *audioQueueRecorder; // audioqueue
@property(nonatomic, strong) TYAudioUnitFileWriter *audiounitFileWriter;

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
        if ([[NSFileManager defaultManager] fileExistsAtPath:_pcmFilePath]) {
            [[NSFileManager defaultManager] createFileAtPath:_pcmFilePath contents:nil attributes:nil];
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
        [_audiounitRecorder stopRecord];
    }
    _filePath =  [NSString stringWithFormat:@"%@/test.pcm", _pcmFilePath];
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
            _audiounitRecorder = [[TYAudioUnitRecorder alloc] initWithPitchShift:0 sampleRate:_sampleRate bitsPerChannel:_bits channelsPerFrame:_channel bytesPerPacket:1];
            _audiounitRecorder.delegate = self;
            _audiounitFileWriter = [[TYAudioUnitFileWriter alloc] initWithSampleRate:_sampleRate bitsPerChannel:_bits channelsPerFrame:_channel bytesPerPacket:1];
        }
        [TYAudioSession setSampleRate:_sampleRate duration:0.02];
        [_audiounitFileWriter openFileWithFilePath:_filePath];
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
        [_audiounitRecorder stopRecord];
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
- (void)audioRecorder:(TYAudioUnitRecorder *)audioRecorder didRecoredAudioData:(void *)data length:(unsigned int)length {
    [_audiounitFileWriter writeData:data length:length];
}

#pragma  mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

@end
