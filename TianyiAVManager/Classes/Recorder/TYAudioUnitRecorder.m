//
//  TYAudioUnitRecorder.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import "TYAudioUnitRecorder.h"

@interface TYAudioUnitRecorder()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) AudioStreamBasicDescription asbd;
@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioUnit ioUnit;
@property (nonatomic) AudioComponentDescription ioUnitDesc;
@property (nonatomic, assign) Float32 pitchShift;
@property (nonatomic, assign) UInt32 channelsPerFrame;

@end

@implementation TYAudioUnitRecorder

- (instancetype)initWithAsbd:(AudioStreamBasicDescription)asbd{
    self = [super init];
    if (self) {
        _asbd = asbd;
        _queue = dispatch_queue_create("ty.audioRecorder", DISPATCH_QUEUE_SERIAL);
        [self setupAcd];
        dispatch_async(_queue, ^{
//            [self createInputUnit];
            [[NSUserDefaults standardUserDefaults] setObject:@(self.channelsPerFrame) forKey:@"mChannelsPerFrame"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self getAudioUnits];
            [self setupAudioUnits];
        });
    }
    return self;
}
- (instancetype)initWithPitchShift:(Float32)pitchShift
                        sampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket {
    AudioStreamBasicDescription asbd = {0};
    asbd.mSampleRate = sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    asbd.mBytesPerPacket = channelsPerFrame * 2;
    asbd.mFramesPerPacket = bytesPerPacket;
    asbd.mBytesPerFrame = channelsPerFrame * 2;
    asbd.mChannelsPerFrame = channelsPerFrame;
    asbd.mBitsPerChannel = channelsPerFrame;
    _asbd = asbd;
    self.pitchShift = pitchShift;
    return [self initWithAsbd:_asbd];
}
- (void)setupAcd {
    _ioUnitDesc.componentType = kAudioUnitType_Output;
    //vpio模式
    _ioUnitDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    _ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _ioUnitDesc.componentSubType = kAudioUnitSubType_NewTimePitch;
    _ioUnitDesc.componentType = kAudioUnitType_FormatConverter;
    _ioUnitDesc.componentFlags = 0;
    _ioUnitDesc.componentFlagsMask = 0;
}
- (void)getAudioUnits {
    OSStatus status = NewAUGraph(&_graph);
    printf("create graph %d \n", (int)status);
    
    AUNode ioNode;
    status = AUGraphAddNode(_graph, &_ioUnitDesc, &ioNode);
    printf("add ioNote %d \n", (int)status);

    //instantiate the audio units
    status = AUGraphOpen(_graph);
    printf("open graph %d \n", (int)status);
    
    //obtain references to the audio unit instances
    status = AUGraphNodeInfo(_graph, ioNode, NULL, &_ioUnit);
    printf("get ioUnit %d \n", (int)status);
    
    //处理变声
    if (self.pitchShift != 0) {
        AudioUnitSetParameter(self.ioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, self.pitchShift, 0);
    }
}
- (void)createInputUnit {
    AudioComponent comp = AudioComponentFindNext(NULL, &_ioUnitDesc);
    if (comp == NULL) {
        printf("can't get AudioComponent");
    }
    OSStatus status = AudioComponentInstanceNew(comp, &(_ioUnit));
    printf("creat audio unit %d \n", (int)status);
}
- (void)setupAudioUnits {
    OSStatus status;
    //音频输入默认是关闭的，需要开启 0:关闭，1:开启
    UInt32 enableInput = 1; // to enable input
    UInt32 propertySize;
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  1,
                                  &enableInput,
                                  sizeof(enableInput));
    printf("enable input %d \n", (int)status);
    
    //关闭音频输出
    UInt32 disableOutput = 0; // to disable output
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  0,
                                  &disableOutput,
                                  sizeof(disableOutput));
    printf("disable output %d \n", (int)status);
    
    //设置stram format
    propertySize = sizeof (AudioStreamBasicDescription);
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &_asbd,
                                  propertySize);
    printf("set input format %d \n", (int)status);
    //检查是否设置成功
    AudioStreamBasicDescription deviceFormat;
    status = AudioUnitGetProperty(_ioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  1,
                                  &deviceFormat,
                                  &propertySize);
    printf("get input format %d \n", (int)status);
    
    //设置最大采集帧数
    UInt32 maxFramesPerSlice = 4096;
    propertySize = sizeof(UInt32);
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &maxFramesPerSlice,
                                  propertySize);
    printf("set max frame per slice: %d, %d \n", (int)maxFramesPerSlice, (int)status);
    AudioUnitGetProperty(_ioUnit,
                         kAudioUnitProperty_MaximumFramesPerSlice,
                         kAudioUnitScope_Global,
                         0,
                         &maxFramesPerSlice,
                         &propertySize);
    printf("get max frame per slice: %d, %d \n", (int)maxFramesPerSlice, (int)status);
    
    //设置回调
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *_Nullable)(self);
    
    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    printf("set render callback %d \n", (int)status);
}
- (void)startRecord {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AUGraphInitialize(self.graph);
        printf("AUGraphInitialize %d \n", (int)status);
        status = AUGraphStart(self.graph);
        printf("AUGraphStart %d \n", (int)status);
    });
}
- (void)stopRecord {
    dispatch_async(_queue, ^{
        OSStatus status;
        status = AUGraphStop(self.graph);
        printf("AUGraphStop %d \n", (int)status);
    });
}
OSStatus inputCallback(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *__nullable ioData) {

    TYAudioUnitRecorder *recorder = (__bridge TYAudioUnitRecorder *)inRefCon;

    AudioBuffer buffer;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    UInt32 size = inNumberFrames * recorder.asbd.mBytesPerFrame;
    NSString *obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"mChannelsPerFrame"];
    UInt32 mChannelsPerFrame = 2;
    if (obj != nil) {
        mChannelsPerFrame = (UInt32)[obj integerValue];
    }
    
    buffer.mDataByteSize = size; // sample size
    buffer.mNumberChannels = mChannelsPerFrame; // one channel
    buffer.mData = malloc(size); // buffer size
    
    // we put our buffer into a bufferlist array for rendering
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    OSStatus status = noErr;
    
    status = AudioUnitRender(recorder.ioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, &bufferList);
    
    if (status != noErr) {
        printf("AudioUnitRender %d \n", (int)status);
        return status;
    }
    if ([recorder.delegate respondsToSelector:@selector(audioRecorder:didRecoredAudioData:length:)]) {
        [recorder.delegate audioRecorder:recorder didRecoredAudioData:buffer.mData length:buffer.mDataByteSize];
    }
    free(buffer.mData);
    
    return status;
}


@end
