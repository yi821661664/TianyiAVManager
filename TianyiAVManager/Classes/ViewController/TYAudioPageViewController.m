//
//  TYAudioPageViewController.m
//  TianyiFunc
//
//  Created by 千刃雪 on 2022/11/4.
//

#import "TYAudioPageViewController.h"
#import "TYAudioRecorder.h"
#import "TYAudioPlayer.h"
#import "TYAudioRecorder.h"
#import "AudioSoundTouchOperation.h"
#import "AudioDecodeOperation.h"
#import <TianyiUIEngine/TYHud.h>

typedef enum : NSUInteger {
    TYAudioPageEncordType_PCM_AAC = 3,     // PCM 数据流 -> AAC音频
    TYAudioPageEncordType_PCM_MP3,      // PCM 数据流 -> MP3音频
    TYAudioPageEncordType_PCM_WAV,      // PCM 数据流 -> WAV音频
} TYAudioPageEncordType;

typedef enum : NSUInteger {
    TYAudioPagesoundTouchType_Demo = 6,     // 示例音频
    TYAudioPagesoundTouchType_Record,       // 录音PCM文件
} TYAudioPagesoundTouchType;

@interface TYAudioPageViewController ()

@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playRecordBtn;    // 播放录音按钮
@property(nonatomic, strong) UIButton *encordBtn;  // 解码按钮
@property(nonatomic, strong) UIButton *playPCMBtn; // 播放PCM数据
@property(nonatomic, strong) UIButton *soundTouchBtn;  // 播放变音文件
@property(nonatomic, strong) UISlider *soundTouchSlider;  // 用于调整变声器的数值

@property(nonatomic, assign) BOOL hasRecordFile;
@property(nonatomic, assign) TYAudioRecordType recordType;
@property(nonatomic, assign) TYAudioPageEncordType encordtype;
@property(nonatomic, assign) TYAudioPagesoundTouchType soundTouchType;
@property(nonatomic, strong) NSArray <NSString *>*recordTypeArr;
@property(nonatomic, strong) NSArray <NSString *>*audioEncordArr;
@property(nonatomic, strong) NSArray <NSString *>*soundTouchArr;
@property(nonatomic, strong) NSMutableArray <UIButton *>*btnsArr;
@property(nonatomic, strong) NSOperationQueue *myAudioQue;
@property(nonatomic, weak)   UIView *lastV;

@property(nonatomic, copy)   NSString *recordPcmPath;  // 录音后形成的PCM文件路径
@property(nonatomic, copy)   NSString *tempPath;  // 音频文件编码成WAV后的路径
@property(nonatomic, copy)   NSString *soundTouchPath;  //编码成WAV后文件变声的路径

@end

@implementation TYAudioPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音频编码与解码";
    self.recordTypeArr = @[@"系统高级Api录音",@"AudioUnit录音",@"AudioQueue录音"];
    self.audioEncordArr = @[@"PCM->AAC音频",@"PCM->MP3音频",@"PCM->WAV音频"];
    self.soundTouchArr = @[@"示例音频变声",@"录音音频变声"];
    self.btnsArr = @[].mutableCopy;
    [self checkRecordFileInfo];
    self.backBtn.hidden = NO;
    self.helpBtn.hidden = NO;
    self.recordType = TYAudioRecordType_system;
    self.encordtype = TYAudioPageEncordType_PCM_AAC;
    self.soundTouchType = TYAudioPagesoundTouchType_Demo;
    self.lastV = [self setupUI:self.recordTypeArr atIndex:self.recordType topView:nil];
    if (_hasRecordFile) {
        self.lastV = [self setupUI:self.audioEncordArr atIndex:self.encordtype topView:self.lastV];
        [self setupUI:self.soundTouchArr atIndex:self.soundTouchType topView:self.lastV];
    }
}

/// 检查本地是否已有录音好的PCM文件
- (void)checkRecordFileInfo {
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _recordPcmPath = [directory stringByAppendingPathComponent:@"TYRecord/record.pcm"];
    _tempPath = [directory stringByAppendingPathComponent:@"TYRecord/ttttRecord.wav"];
    _soundTouchPath = [directory stringByAppendingPathComponent:@"TYRecord/stRecord.wav"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    _hasRecordFile = [fileManager fileExistsAtPath:self.recordPcmPath];
}

- (void)dealloc {
    [TYAudioPlayer stopAllAuido];
}

- (UIView *)setupUI:(NSArray *)arr atIndex:(NSInteger)atIndex topView:(UIView *)topView {
    UIView *lastView = topView;
    NSInteger index = atIndex;
    for (NSString *obj in arr) {
        UILabel *label = [UILabel new];
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor colorFromHexString:@"333333"];
        label.text = obj;
        [self.view addSubview:label];
        
        NSString *iconName = index == atIndex ? @"ty_icon_select_s" : @"ty_icon_select_n";
        UIButton *btn = [UIButton new];
        btn.tag = 10000 + index;
        [btn setImage:[TYBaseTool getImagaResource:iconName bundleName:@"TianyiUIEngine"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnOnClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            if (lastView == nil) {
                make.top.mas_equalTo(self.mas_topLayoutGuide).offset(20);
            } else {
                make.top.mas_equalTo(lastView.mas_bottom).offset(15);
            }
            make.left.mas_equalTo(20);
        }];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(label);
            make.right.mas_equalTo(-10);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
        [self.btnsArr addObject:btn];
        
        index++;
        lastView = label;
    }
    
    if (arr == _recordTypeArr) {
        [self.view addSubview:self.recordBtn];
        [self.view addSubview:self.playRecordBtn];
        [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(lastView.mas_bottom).offset(20);
            make.left.mas_equalTo(lastView);
            make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
            make.height.mas_equalTo(40);
        }];
        [self.playRecordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.recordBtn);
            make.left.mas_equalTo(self.recordBtn.mas_right).offset(8);
            make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
            make.height.mas_equalTo(40);
        }];
        lastView = self.recordBtn;
    } else if (arr == _audioEncordArr) {
        [self.view addSubview:self.encordBtn];
        [self.view addSubview:self.playPCMBtn];
        [self.encordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(lastView.mas_bottom).offset(20);
            make.left.mas_equalTo(self.recordBtn);
            make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
            make.height.mas_equalTo(40);
        }];
        [self.playPCMBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.encordBtn);
            make.left.mas_equalTo(self.encordBtn.mas_right).offset(8);
            make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
            make.height.mas_equalTo(40);
        }];
        lastView = self.encordBtn;
    } else {
        [self.view addSubview:self.soundTouchSlider];
        [self.view addSubview:self.soundTouchBtn];
        self.soundTouchSlider.value = 0.5;
        [self.soundTouchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(lastView.mas_bottom).offset(20);
            make.right.mas_equalTo(-20);
            make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
            make.height.mas_equalTo(40);
        }];
        [self.soundTouchSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.soundTouchBtn);
            make.left.mas_equalTo(self.recordBtn);
            make.right.mas_equalTo(self.soundTouchBtn.mas_left).offset(-10);
            make.height.mas_equalTo(40);
        }];
        lastView = self.soundTouchBtn;
    }
    
    UIView *line = [UIView new];
    line.backgroundColor = [[UIColor colorFromHexString:@"999999"] colorWithAlphaComponent:0.3];
    [self.view addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(20);
        make.right.mas_equalTo(-20);
        make.top.mas_equalTo(lastView.mas_bottom).offset(15);
        make.height.mas_equalTo(1);
    }];
    lastView = line;
    
    return lastView;
}

#pragma mark - action
// 音频基础以及相关文档介绍
- (void)helpBtnOnClick:(UIButton *)sender {
    
}

- (void)btnOnClick:(UIButton *)sender {
    NSInteger tag = sender.tag - 10000;
    NSInteger startIndex = 0;
    NSInteger endIndex = 0;
    if (tag < self.recordTypeArr.count) {
        startIndex = TYAudioRecordType_system;
        endIndex = self.recordTypeArr.count;
        self.recordType = tag;
    } else if (tag < TYAudioPagesoundTouchType_Demo) {
        startIndex = TYAudioPageEncordType_PCM_AAC;
        endIndex = startIndex + self.audioEncordArr.count;
        self.encordtype = tag;
    } else {
        startIndex = TYAudioPagesoundTouchType_Demo;
        endIndex = startIndex + self.soundTouchArr.count;
        self.soundTouchType = tag;
    }
    for (NSInteger i = startIndex; i < endIndex; i++) {
        UIButton *btn = [self.btnsArr objectAtIndex:i];
        [btn setImage:[TYBaseTool getImagaResource:@"ty_icon_select_n" bundleName:@"TianyiUIEngine"] forState:UIControlStateNormal];
    }
    [sender setImage:[TYBaseTool getImagaResource:@"ty_icon_select_s" bundleName:@"TianyiUIEngine"] forState:UIControlStateNormal];
}

- (void)playAudioBtnOnClick:(UIButton *)sender {
//    NSString *path = [TYBaseTool getFilePath:@"audio/my_test" type:@"pcm" bundleName:@"TianyiAVManager"];
//    if (path.length <= 0) {
//        return;
//    }
//    [TYAudioPlayer playAudioWith:path type:TYAudioPlayType_audioUnit finish:^{
//
//    }];
}

- (void)recordBtnOnClick:(UIButton *)sender {
    if (!TYAudioRecorder.shared.isRecording) {
        _playRecordBtn.enabled = NO;
        _playRecordBtn.alpha = 0.5;
//        switch (self.recordType) {
//            case TYAudioPageRecordType_system:
//                self.recorder.recordType = ty_record_type_audioUnit;
//                break;
//            case TYAudioPageRecordType_audioUnit:
//                self.recorder.recordType = ty_record_type_audioUnit;
//                break;
//            case TYAudioPageRecordType_audioQueue:
//                self.recorder.recordType = ty_record_type_audioQueue;
//                break;
//            default:
//                break;
//        }
        TYAudioRecorder.shared.recordType = TYAudioRecordType_audioUnit;
        [TYAudioRecorder.shared startRecord];
        [self.recordBtn setTitle:@"停止录音" forState:UIControlStateNormal];
    } else {
        _playRecordBtn.enabled = YES;
        _playRecordBtn.alpha = 1;
        if (!_hasRecordFile) {
            self.lastV = [self setupUI:self.audioEncordArr atIndex:self.encordtype topView:self.lastV];
            [self setupUI:self.soundTouchArr atIndex:self.soundTouchType topView:self.lastV];
            _hasRecordFile = YES;
        }
        [TYAudioRecorder.shared stopRecord];
        [self.recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    }
}

- (void)encordBtnOnClick:(UIButton *)sender {
    
}

- (void)playRecordBtnOnClick:(UIButton *)sender {
    [TYAudioPlayer playAudioWith:_recordPcmPath type:TYAudioPlayType_audioUnit finish:^{

    }];
}

- (void)soundTouchBtnOnClick:(UIButton *)sender {
    [TYAudioPlayer stopAllAuido];
    if (self.soundTouchType == TYAudioPagesoundTouchType_Demo) {
        [self soundTouchDemo];
    } else {
        [self soundTouchRecord];
    }
}

- (void)sliderValueChanged:(UISlider *)sender {
    NSString *name = [NSString stringWithFormat:@"变声音频(%.0lf)",self.soundTouchSlider.value * 24 - 12];
    [_soundTouchBtn setTitle:name forState:UIControlStateNormal];
}

#pragma mark - soundTouch
- (void)soundTouchDemo {
    [TYHud showLoading];
    NSString*fff = [TYBaseTool getFilePath:@"audio/一生无悔高安" type:@"mp3" bundleName:@"TianyiAVManager"];
    // 先把mp3音频转码成wav格式
    AudioDecodeOperation *audioDecode = [[AudioDecodeOperation alloc] initWithSourcePath:fff
                                                                         audioOutputPath:_tempPath
                                                                        outputSampleRate:0
                                                                           outputChannel:1
                                                                          callBackTarget:self
                                                                            callFunction:@selector(didDecode:)];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:audioDecode];
}

- (void)soundTouchRecord {
    
}

- (void)didDecode:(NSString *)tmpPath {
    // 解码失败
    if (!tmpPath) {
        [TYHud disMiss];
        [TYHud showToast:@"解码失败" duration:0 userInteraction:YES];
        return;
    }
    // 进行变声处理
    int audioPitch = audioPitch = self.soundTouchSlider.value * 24 - 12;
    AudioSoundTouchOperation *soundTouch = [[AudioSoundTouchOperation alloc] initWithTarget:self
                                                                                     action:@selector(soundTouchFinish:)
                                                                                 sourcePath:tmpPath
                                                                            audioOutputPath:_soundTouchPath
                                                                            audioSampleRate:44100/2.0
                                                                           audioTempoChange:0
                                                                                 audioPitch:audioPitch
                                                                                  audioRate:0
                                                                              audioChannels:1];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:soundTouch];
}

- (void)soundTouchFinish:(NSString *)stPath {
    [TYHud disMiss];
    // 变声失败
    if (!stPath) {
        [TYHud showToast:@"变声失败" duration:0 userInteraction:YES];
        return;
    }
    if([[NSFileManager defaultManager] fileExistsAtPath:stPath]) {
        // 变声成功可以直接播放
        [TYAudioPlayer playAudioWith:stPath type:TYAudioPlayType_system finish:^{

        }];
    }
}

#pragma mark - lazy init
- (UIButton *)recordBtn {
    if (!_recordBtn) {
        _recordBtn = [UIButton new];
        _recordBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
        _recordBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _recordBtn.layer.cornerRadius = 5.0;
        _recordBtn.clipsToBounds = YES;
        [_recordBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_recordBtn addTarget:self action:@selector(recordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordBtn;
}

- (UIButton *)encordBtn {
    if (!_encordBtn) {
        _encordBtn = [UIButton new];
        _encordBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_encordBtn setTitle:@"编码" forState:UIControlStateNormal];
        _encordBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _encordBtn.layer.cornerRadius = 5.0;
        _encordBtn.clipsToBounds = YES;
        [_encordBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_encordBtn addTarget:self action:@selector(encordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _encordBtn;
}

- (UIButton *)playPCMBtn {
    if (!_playPCMBtn) {
        _playPCMBtn = [UIButton new];
        _playPCMBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_playPCMBtn setTitle:@"播放音频" forState:UIControlStateNormal];
        _playPCMBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _playPCMBtn.layer.cornerRadius = 5.0;
        _playPCMBtn.clipsToBounds = YES;
        _playPCMBtn.enabled = NO;
        _playPCMBtn.alpha = 0.5;
        [_playPCMBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_playPCMBtn addTarget:self action:@selector(playAudioBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playPCMBtn;
}

- (UIButton *)soundTouchBtn {
    if (!_soundTouchBtn) {
        _soundTouchBtn = [UIButton new];
        _soundTouchBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_soundTouchBtn setTitle:@"播放音频(0)" forState:UIControlStateNormal];
        _soundTouchBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _soundTouchBtn.layer.cornerRadius = 5.0;
        _soundTouchBtn.clipsToBounds = YES;
        [_soundTouchBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_soundTouchBtn addTarget:self action:@selector(soundTouchBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _soundTouchBtn;
}

- (UIButton *)playRecordBtn {
    if (!_playRecordBtn) {
        _playRecordBtn = [UIButton new];
        _playRecordBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_playRecordBtn setTitle:@"播放录音" forState:UIControlStateNormal];
        _playRecordBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _playRecordBtn.layer.cornerRadius = 5.0;
        _playRecordBtn.clipsToBounds = YES;
        [_playRecordBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_playRecordBtn addTarget:self action:@selector(playRecordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playRecordBtn;
}

- (NSOperationQueue *)myAudioQue {
    if (!_myAudioQue) {
        _myAudioQue = [[NSOperationQueue alloc] init];
        _myAudioQue.maxConcurrentOperationCount = 1;
    }
    return _myAudioQue;
}

- (UISlider *)soundTouchSlider {
    if (!_soundTouchSlider) {
        _soundTouchSlider = [[UISlider alloc] init];
        _soundTouchSlider.maximumValue = 1.0;
        _soundTouchSlider.minimumValue = 0.0;
        [_soundTouchSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _soundTouchSlider;
}

@end
