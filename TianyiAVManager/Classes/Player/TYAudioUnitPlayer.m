//
//  TYAudioUnitPlayer.m
//  TianyiFunc
//
//  Created by 易召强 on 2022/11/7.
//

#import "TYAudioUnitPlayer.h"

@interface TYAudioUnitPlayer() {
    AudioUnit audioUnit;
}

@end

@implementation TYAudioUnitPlayer

- (void)destroy {
    if (audioUnit) {
        OSStatus status;
        status = AudioComponentInstanceDispose(audioUnit);
        CheckError(status, "audioUnit释放失败");
    }
}

static OSStatus outputCallBackFun(void *                          inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *          inTimeStamp,
                                  UInt32                          inBusNumber,
                                  UInt32                          inNumberFrames,
                                  AudioBufferList * __nullable    ioData) {
    memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    
    TYAudioUnitPlayer *player = (__bridge TYAudioUnitPlayer *)(inRefCon);
    typeof(player) __weak weakPlayer = player;
    if (player.inputBlock) {
        player.inputBlock(ioData);
    }
    if (player.inputFullBlock) {
        player.inputFullBlock(weakPlayer, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    }
    return noErr;
}

- (void)initWithSampleRate:(UInt32)sampleRate bitsPerChannel:(UInt32)bitsPerChannel {
    //初始化audioUnit
    AudioComponentDescription outputDesc;
    outputDesc.componentType = kAudioUnitType_Output;
    outputDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    outputDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDesc.componentFlags = 0;
    outputDesc.componentFlagsMask = 0;
    
    AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputDesc);
    AudioComponentInstanceNew(outputComponent, &audioUnit);

    //设置输出格式
    AudioStreamBasicDescription streamDesc;
    memset(&streamDesc, 0, sizeof(streamDesc));
    streamDesc.mSampleRate       = sampleRate;
    streamDesc.mFormatID         = kAudioFormatLinearPCM;
    streamDesc.mFormatFlags      = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved);
    streamDesc.mFramesPerPacket  = 1;
    streamDesc.mChannelsPerFrame = bitsPerChannel;
    streamDesc.mBitsPerChannel   = 16;
    streamDesc.mBytesPerFrame    = 16 * bitsPerChannel / 8;
    streamDesc.mBytesPerPacket   = 16 * bitsPerChannel / 8 * 1;

    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input,
                                           0,
                                           &streamDesc,
                                           sizeof(streamDesc));
    CheckError(status, "SetProperty StreamFormat failure");

    //设置回调
    AURenderCallbackStruct outputCallBackStruct;
    outputCallBackStruct.inputProc = outputCallBackFun;
    outputCallBackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &outputCallBackStruct,
                                  sizeof(outputCallBackStruct));
    CheckError(status, "SetProperty EnableIO failure");
    
//    AudioUnitSetParameter(self->audioUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, 80, 0);
}

- (void)start {
    [self stop];
    AudioOutputUnitStart(audioUnit);
}

- (void)stop {
    if (audioUnit == nil) {
        return;
    }
    OSStatus status;
    status = AudioOutputUnitStop(audioUnit);
    CheckError(status, "audioUnit停止失败");
}

void CheckError(OSStatus error, const char *operation) {
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

@end
