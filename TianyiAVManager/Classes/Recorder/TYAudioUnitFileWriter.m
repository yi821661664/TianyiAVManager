//
//  TYAudioUnitFileWriter.m
//  TianyiAVManager
//
//  Created by 易召强 on 2022/11/15.
//

#import "TYAudioUnitFileWriter.h"

@interface TYAudioUnitFileWriter()

@property (nonatomic, assign) AudioStreamBasicDescription asbd;

@end

@implementation TYAudioUnitFileWriter {
    AudioFileTypeID _fileType;
    AudioFileID _audioFile;
    UInt32 _currentPacket;
}

- (instancetype)initWithSampleRate:(UInt32)sampleRate
                    bitsPerChannel:(UInt32)bitsPerChannel
                  channelsPerFrame:(UInt32)channelsPerFrame
                    bytesPerPacket:(UInt32)bytesPerPacket {
    self = [super init];
    if (self) {
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
        _fileType = kAudioFileCAFType;
        [self setAudioFormat];
    }
    return self;
}

- (void)setAudioFormat {
    
}

- (void)creatAudioFile {
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)self.filePath.UTF8String, strlen(self.filePath.UTF8String), false);
    
    OSStatus status = AudioFileCreateWithURL(audioFileURL,
                                             _fileType,
                                             &_asbd,
                                             kAudioFileFlags_EraseFile,
                                             &_audioFile);
    printf("create audio file: %d \n", (int)status);
}
- (void)writeData:(void *)data length:(int)length {
    UInt32 inNumPackets = 0;
    if (_asbd.mBytesPerPacket != 0) {
        inNumPackets = length / _asbd.mBytesPerPacket;
    }
    
    OSStatus status = AudioFileWritePackets(_audioFile, false, length, nil, _currentPacket, &inNumPackets, data);
    if (status == noErr){
        _currentPacket += inNumPackets;
    }
    printf("write date to file: %u\n", _currentPacket);
}
- (void)openFileWithFilePath:(NSString *)filePath {
    CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL,(const UInt8*)filePath.UTF8String, strlen(filePath.UTF8String), false);
    _currentPacket = 0;
    OSStatus status = AudioFileCreateWithURL(audioFileURL, _fileType, &_asbd, kAudioFileFlags_EraseFile, &_audioFile);
    printf("create audio file: %d \n", (int)status);
}
- (void)closeFile {
    OSStatus status = AudioFileClose(_audioFile);
    printf("close audio file: %d \n", (int)status);
}

@end
