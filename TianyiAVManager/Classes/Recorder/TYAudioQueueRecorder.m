//
//  TYAudioQueueRecorder.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/14.
//

#import "TYAudioQueueRecorder.h"
#import <AVFoundation/AVFoundation.h>
#define TYBufferCount  3
#define TYBufferDurationSeconds  0.2

@interface TYAudioQueueRecorder(){
    AudioQueueRef audioQRef;       //音频队列对象指针
    AudioStreamBasicDescription recordFormat;   //音频流配置
    AudioQueueBufferRef audioBuffers[TYBufferCount];  //音频流缓冲区对象
}

@property(nonatomic,assign)AudioFileID recordFileID;   //音频文件标识  用于关联音频文件
@property(nonatomic,assign)SInt64 recordPacket;  //录音文件的当前包
@property(nonatomic, assign) UInt32 sampleRate;
@property(nonatomic, assign) UInt32 bytesPerPacket;
@property(nonatomic, assign) UInt32 bitsPerChannel;
@property(nonatomic, assign) UInt32 channelsPerFrame;

@end

@implementation TYAudioQueueRecorder

- (instancetype)initWithSampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket {
    if(self == [super init]) {
        _sampleRate = sampleRate;
        _bytesPerPacket = bytesPerPacket;
        _bitsPerChannel = bitsPerChannel;
        _channelsPerFrame = channelsPerFrame;
        [self initFormat];
    }
    return self;
}

-  (void)initFormat {
    recordFormat.mSampleRate =  _sampleRate;  //采样率
    recordFormat.mChannelsPerFrame = _channelsPerFrame; //声道数量
    //编码格式
    recordFormat.mFormatID = kAudioFormatLinearPCM;
    recordFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    //每采样点占用位数
    recordFormat.mBitsPerChannel = _bitsPerChannel;
    //每帧的字节数
    recordFormat.mBytesPerFrame = (recordFormat.mBitsPerChannel / 8) * recordFormat.mChannelsPerFrame;
    //每包的字节数
    recordFormat.mBytesPerPacket = recordFormat.mBytesPerFrame;
    //每帧的字节数
    recordFormat.mFramesPerPacket = _bytesPerPacket;
}

- (void)initAudio {
    //设置音频输入信息和回调
    OSStatus status = AudioQueueNewInput(&recordFormat, inputBufferHandler, (__bridge void *)(self), NULL, NULL, 0, &audioQRef);
    if( status != kAudioSessionNoError ) {
        NSLog(@"初始化出错");
        return ;
    }
    //计算估算的缓存区大小
    int frames = [self computeRecordBufferSize:&recordFormat seconds:TYBufferDurationSeconds];
    int bufferByteSize = frames * recordFormat.mBytesPerFrame;
    //创建缓冲器
    for (int i = 0; i < TYBufferCount; i++) {
        AudioQueueAllocateBuffer(audioQRef, bufferByteSize, &audioBuffers[i]);
        AudioQueueEnqueueBuffer(audioQRef, audioBuffers[i], 0, NULL);
    }
}

- (int)computeRecordBufferSize:(const AudioStreamBasicDescription*)format seconds:(float)seconds {
    int packets, frames, bytes = 0;
    frames = (int)ceil(seconds * format->mSampleRate);
    if (format->mBytesPerFrame > 0) {
        bytes = frames * format->mBytesPerFrame;
    } else {
        UInt32 maxPacketSize = 0;
        if (format->mBytesPerPacket > 0) {
            maxPacketSize = format->mBytesPerPacket;    // constant packet size
        }
        if (format->mFramesPerPacket > 0) {
            packets = frames / format->mFramesPerPacket;
        } else {
            packets = frames;    // worst-case scenario: 1 frame in a packet
        }
        if (packets == 0) {       // sanity check
            packets = 1;
        }
        bytes = packets * maxPacketSize;
    }
    return bytes;
}

//回调
void inputBufferHandler(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc) {
    TYAudioQueueRecorder *audioManager = [[TYAudioQueueRecorder alloc] init];
    if (inNumPackets > 0) {
        //写入文件
        AudioFileWritePackets(audioManager.recordFileID, FALSE, inBuffer->mAudioDataByteSize,inPacketDesc, audioManager.recordPacket, &inNumPackets, inBuffer->mAudioData);
           audioManager.recordPacket += inNumPackets;
    }
    if (audioManager.isRecording) {
       //将缓冲器重新放入缓冲队列，以便重复使用该缓冲器
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

- (void)startRecord {
    if (self.filePath.length <= 0) {
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    [self initAudio];
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)self.filePath, NULL);
    //创建音频文件夹
    AudioFileCreateWithURL(url, kAudioFileCAFType, &recordFormat, kAudioFileFlags_EraseFile,&_recordFileID);
    CFRelease(url);
    self.recordPacket = 0;
    
    OSStatus status = AudioQueueStart(audioQRef, NULL);
    if( status != kAudioSessionNoError ) {
        NSLog(@"开始出错");
        return;
    }
    self.isRecording = true;
}

- (void)stopRecord {
    if (self.isRecording) {
        self.isRecording = NO;
        //停止录音队列和移，这里无需考虑成功与否
        AudioQueueStop(audioQRef, true);
        AudioFileClose(_recordFileID);
        AudioQueueDispose(audioQRef, TRUE);
    }
}

- (void)dealloc {
    AudioQueueDispose(audioQRef, TRUE);
    AudioFileClose(_recordFileID);
}

@end
