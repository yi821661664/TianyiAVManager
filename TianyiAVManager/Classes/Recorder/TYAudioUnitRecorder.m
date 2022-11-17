//
//  TYAudioUnitRecorder.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

//AudioUnitSetParameter(self.ioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, self.pitchShift, 0);

#import "TYAudioUnitRecorder.h"

#pragma mark --audioEncodeParam
#define kAudioEncodeSampleRate                      48000
#define kAudioEncodeBitsPerChannel                  16
#define kAudioEncodeChannelCount                    2
#define kAudioEncodeBitrate                         128 * 1000

@interface TYAudioUnitRecorder() {
    AudioUnit audioUnit;
    BOOL audioComponentInitialized;
}
@property (nonatomic,assign) AudioStreamBasicDescription inputStreamDesc;

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;

@property (assign, nonatomic) double SampleRate;
@property (assign, nonatomic) double BitsPerChannel;
@property (assign, nonatomic) UInt32 ChannelCount;

@end

@implementation TYAudioUnitRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [super init];
        if (self) {
            [self defaultSetting];
        }
        return self;
    }
    return self;
}

- (void)defaultSetting{
    self.encoderQueue = dispatch_queue_create("AAC Encoder Queue", DISPATCH_QUEUE_SERIAL);
    self.callbackQueue = dispatch_queue_create("AAC Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
    self.SampleRate = kAudioEncodeSampleRate;
    self.BitsPerChannel = kAudioEncodeBitsPerChannel;
    self.ChannelCount = kAudioEncodeChannelCount;
    OSStatus status = [self prepareRecord:kAudioEncodeSampleRate];
    CheckError(status, "prepareRecord failed");
}
- (OSStatus)prepareRecord:(double)sampleRate {
    OSStatus status = noErr;
    
    if (!audioComponentInitialized) {
        audioComponentInitialized = YES;
        // 描述音频组件
        AudioComponentDescription audioComponentDescription;
        audioComponentDescription.componentType = kAudioUnitType_Output;
        audioComponentDescription.componentSubType = kAudioUnitSubType_VoiceProcessingIO; // 降噪
        audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        audioComponentDescription.componentFlags = 0;
        audioComponentDescription.componentFlagsMask = 0;
        
        // 查找音频单元
        AudioComponent remoteIOComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
        // 创建音频单元实例
        status = AudioComponentInstanceNew(remoteIOComponent, &(self->audioUnit));
        if (CheckError(status, "Couldn't get RemoteIO unit instance")) {
            return status;
        }
    }
    
    UInt32 oneFlag = 1;
    AudioUnitElement bus0 = 0;
    AudioUnitElement bus1 = 1;
    
    if ((NO)) {
        // Configure the RemoteIO unit for playback
        status = AudioUnitSetProperty (self->audioUnit,
                                       kAudioOutputUnitProperty_EnableIO,
                                       kAudioUnitScope_Output,
                                       bus0,
                                       &oneFlag,
                                       sizeof(oneFlag));
        if (CheckError(status, "Couldn't enable RemoteIO output")) {
            return status;
        }
    }
    
    // Configure the RemoteIO unit for input
    status = AudioUnitSetProperty(self->audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  bus1,
                                  &oneFlag,
                                  sizeof(oneFlag));
    if (CheckError(status, "Couldn't enable RemoteIO input")) {
        return status;
    }
    // 音频流基础描述
    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = self.SampleRate;//采样率
    asbd.mFormatID = kAudioFormatLinearPCM;//原始数据为PCM格式
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mChannelsPerFrame = self.ChannelCount;//每帧的声道数量
    asbd.mFramesPerPacket = 1;//每个数据包多少帧
    asbd.mBitsPerChannel = self.BitsPerChannel;//16位
    asbd.mBytesPerFrame = asbd.mChannelsPerFrame * asbd.mBitsPerChannel / 8;//每帧多少字节 bytes -> bit / 8
    asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame;//每个包多少字节
    
    // Set format for output (bus 0) on the RemoteIO's input scope
    status = AudioUnitSetProperty(self->audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  bus0,
                                  &asbd,
                                  sizeof(asbd));
    if (CheckError(status, "Couldn't set the ASBD for RemoteIO on input scope/bus 0")) {
        return status;
    }
    
    // Set format for mic input (bus 1) on RemoteIO's output scope
    status = AudioUnitSetProperty(self->audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  bus1,
                                  &asbd,
                                  sizeof(asbd));
    if (CheckError(status, "Couldn't set the ASBD for RemoteIO on output scope/bus 1")) {
        return status;
    }
    
    // Set the recording callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputCallBackFun;
    callbackStruct.inputProcRefCon = (__bridge void *) self;
    status = AudioUnitSetProperty(self->audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  bus1,
                                  &callbackStruct,
                                  sizeof (callbackStruct));
    if (CheckError(status, "Couldn't set RemoteIO's render callback on bus 0")) {
        return status;
    }
    
    if ((NO)) {
        // Set the playback callback
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = playbackCallback;
        callbackStruct.inputProcRefCon = (__bridge void *) self;
        status = AudioUnitSetProperty(self->audioUnit,
                                      kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Global,
                                      bus0,
                                      &callbackStruct,
                                      sizeof (callbackStruct));
        if (CheckError(status, "Couldn't set RemoteIO's render callback on bus 0")) {
            return status;
        }
    }
    
    // Initialize the RemoteIO unit
    status = AudioUnitInitialize(self->audioUnit);
    if (CheckError(status, "Couldn't initialize the RemoteIO unit")) {
        return status;
    }
    
    return status;
}
static OSStatus CheckError(OSStatus error, const char *operation) {
  if (error == noErr) {
    return error;
  }
  char errorString[20] = "";
  // See if it appears to be a 4-char-code
  *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
  if (isprint(errorString[1]) && isprint(errorString[2]) &&
      isprint(errorString[3]) && isprint(errorString[4])) {
    errorString[0] = errorString[5] = '\'';
    errorString[6] = '\0';
  } else {
    // No, format it as an integer
    sprintf(errorString, "%d", (int)error);
  }
  fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
  return error;
}
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
  OSStatus status = noErr;

  // Notes: ioData contains buffers (may be more than one!)
  // Fill them up as much as you can. Remember to set the size value in each buffer to match how
  // much data is in the buffer.
    TYAudioUnitRecorder *recorder = (__bridge TYAudioUnitRecorder *) inRefCon;

  UInt32 bus1 = 1;
  status = AudioUnitRender(recorder->audioUnit,
                           ioActionFlags,
                           inTimeStamp,
                           bus1,
                           inNumberFrames,
                           ioData);
  CheckError(status, "Couldn't render from RemoteIO unit");
  return status;
}

static OSStatus inputCallBackFun(void *inRefCon,
                    AudioUnitRenderActionFlags *ioActionFlags,
                    const AudioTimeStamp *inTimeStamp,
                    UInt32 inBusNumber,
                    UInt32 inNumberFrames,
                    AudioBufferList * __nullable ioData)
{
    TYAudioUnitRecorder *recorder = (__bridge TYAudioUnitRecorder *)(inRefCon);
    
    AudioBufferList bufferList;
    /*
    bufferList.mNumberBuffers = recorder.ChannelCount;
    for (UInt32 i = 0; i < recorder.ChannelCount; i++) {
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        bufferList.mBuffers[i] = buffer;
    }
    */
    bufferList.mNumberBuffers = 1;
    AudioBuffer buffer;
    buffer.mData = NULL;
    buffer.mDataByteSize = 0;
    buffer.mNumberChannels = recorder.ChannelCount;
    bufferList.mBuffers[0] = buffer;
    
    AudioUnitRender(recorder->audioUnit,
                    ioActionFlags,
                    inTimeStamp,
                    inBusNumber,
                    inNumberFrames,
                    &bufferList);
    if (recorder.delegate && [recorder.delegate respondsToSelector:@selector(audioRecorder:didRecoredbufferList:)]) {
        [recorder.delegate audioRecorder:recorder didRecoredbufferList:&bufferList];
    }
    
    return noErr;
}

- (void)start {
    [self deleteAudioFile];
    OSStatus status = AudioOutputUnitStart(audioUnit);
    CheckError(status, "AudioOutputUnitStart failed");
    _isRecording = YES;
}

- (void)stop {
    CheckError(AudioOutputUnitStop(audioUnit),
    "AudioOutputUnitStop failed");
    _isRecording = NO;
}

- (void)deleteAudioFile {
    NSString *pcmPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"record.mp3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pcmPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:pcmPath error:nil];
    }
}

- (void)dealloc {
    CheckError(AudioComponentInstanceDispose(audioUnit),
               "AudioComponentInstanceDispose failed");
    NSLog(@"UnitRecorder销毁");
}

@end
