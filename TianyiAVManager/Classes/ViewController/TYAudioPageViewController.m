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

//音频波形图
//变声处理

// 音频播放工具
typedef enum : NSUInteger {
    TYAudioPageDemoType_demoAcc = 3,  // 示例AAC音频
    TYAudioPageDemoType_demoMp3,      // 示例MP3音频
    TYAudioPageDemoType_demoCaf       // 示例Caf音频
} TYAudioPageDemoType;

typedef enum : NSUInteger {
    TYAudioPageDecordType_demoAccToPCM = 6,     // 示例ACC音频 -> PCM 数据流
    TYAudioPageDecordType_recordAccToPCM,      // 录音编码后的ACC音频 -> PCM 数据流
} TYAudioPageDecordType;

@interface TYAudioPageViewController ()

@property(nonatomic, strong) UILabel *samplePointLb;  // PCM波形图
@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playRecordBtn;    // 播放录音按钮
@property(nonatomic, strong) UIButton *playDemoBtn;    // 播放Demo按钮
@property(nonatomic, strong) UIButton *decordBtn;  // 解码按钮
@property(nonatomic, strong) UIButton *playPCMBtn; // 播放PCM数据

@property(nonatomic, assign) BOOL demoPlaying;
@property(nonatomic, assign) TYAudioRecordType recordType;
@property(nonatomic, assign) TYAudioPageDemoType demoType;
@property(nonatomic, assign) TYAudioPageDecordType decordtype;
@property(nonatomic, strong) NSArray <NSString *>*recordTypeArr;
@property(nonatomic, strong) NSArray <NSString *>*audioDemoArr;
@property(nonatomic, strong) NSArray <NSString *>*audioDecordArr;
@property(nonatomic, strong) NSMutableArray <UIButton *>*btnsArr;
@property(nonatomic, copy)   NSString *recordPcmPath;

@property(nonatomic, copy)   NSString *tempPath;
@property(nonatomic, strong) NSOperationQueue *myAudioQue;

@end

@implementation TYAudioPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音频编码与解码";
    self.recordTypeArr = @[@"系统高级Api录音",@"AudioUnit录音",@"AudioQueue录音"];
    self.audioDemoArr = @[@"示例AAC音频",@"示例MP3音频",@"示例CAF音频"];
    self.audioDecordArr = @[@"示例AAC音频->PCM",@"录音AAC音频->PCM"];
    self.btnsArr = @[].mutableCopy;
    
    self.backBtn.hidden = NO;
    self.helpBtn.hidden = NO;
    
    self.recordType = TYAudioRecordType_system;
    self.demoType = TYAudioPageDemoType_demoAcc;
    self.decordtype = TYAudioPageDecordType_demoAccToPCM;
    
    UIView *lastV = [self setupUI:self.recordTypeArr atIndex:self.recordType topView:nil];
    lastV = [self setupUI:self.audioDemoArr atIndex:self.demoType topView:lastV];
    lastV = [self setupUI:self.audioDecordArr atIndex:self.decordtype topView:lastV];
    
    [self.view addSubview:self.recordBtn];
    [self.view addSubview:self.playRecordBtn];
    [self.view addSubview:self.playDemoBtn];
    [self.view addSubview:self.decordBtn];
    [self.view addSubview:self.playPCMBtn];
    
    [self.view addSubview:self.samplePointLb];
    self.samplePointLb.hidden = YES;
    
    [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(lastV.mas_bottom).offset(20);
        make.left.mas_equalTo(lastV);
        make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
        make.height.mas_equalTo(40);
    }];
    [self.playRecordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.recordBtn);
        make.left.mas_equalTo(self.recordBtn.mas_right).offset(8);
        make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
        make.height.mas_equalTo(40);
    }];
    [self.playDemoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.recordBtn.mas_bottom).offset(20);
        make.left.mas_equalTo(self.recordBtn);
        make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
        make.height.mas_equalTo(40);
    }];
    [self.decordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.playDemoBtn.mas_bottom).offset(20);
        make.left.mas_equalTo(self.recordBtn);
        make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
        make.height.mas_equalTo(40);
    }];
    [self.playPCMBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.decordBtn);
        make.left.mas_equalTo(self.decordBtn.mas_right).offset(8);
        make.width.mas_equalTo((SCREEN_WIDTH-56)/3.0);
        make.height.mas_equalTo(40);
    }];
    [self.samplePointLb mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.playPCMBtn.mas_bottom).offset(20);
        make.left.mas_equalTo(lastV);
    }];
    
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _recordPcmPath = [directory stringByAppendingPathComponent:@"TYRecord/record.pcm"];
    _tempPath = [directory stringByAppendingPathComponent:@"TYRecord/ttttRecord.mp3"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.recordPcmPath]) {
        _playRecordBtn.enabled = YES;
        _playRecordBtn.alpha = 1;
    } else {
        _playRecordBtn.enabled = NO;
        _playRecordBtn.alpha = 0.5;
    }
}

- (void)dealloc {
    //    [[TYAudioPlayer shared] stop];
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
    NSLog(@"====");
    
    NSString*fff = [TYBaseTool getFilePath:@"audio/告五人 - 爱人错过" type:@"mp3" bundleName:@"TianyiAVManager"];
    AudioSoundTouchOperation *soundTouch = [[AudioSoundTouchOperation alloc] initWithTarget:self
                                                                                     action:@selector(soundTouchFinish:)
                                                                                 sourcePath:fff
                                                                            audioOutputPath:_tempPath
                                                                            audioSampleRate:48000
                                                                           audioTempoChange:0
                                                                                 audioPitch:10
                                                                                  audioRate:0
                                                                              audioChannels:2];
    [[self myAudioQue] cancelAllOperations];
    [[self myAudioQue] addOperation:soundTouch];
}

- (void)soundTouchFinish:(NSString *)stPath {
    [TYAudioPlayer playAudioWith:stPath type:TYAudioPlayType_audioUnit finish:^{

    }];
}

- (void)btnOnClick:(UIButton *)sender {
    NSInteger tag = sender.tag - 10000;
    NSInteger startIndex = 0;
    NSInteger endIndex = 0;
    if (tag < self.recordTypeArr.count) {
        startIndex = TYAudioRecordType_system;
        endIndex = self.recordTypeArr.count;
        self.recordType = tag;
    } else if (tag >= TYAudioPageDemoType_demoAcc && tag < TYAudioPageDemoType_demoAcc + self.audioDemoArr.count) {
        startIndex = TYAudioPageDemoType_demoAcc;
        endIndex = startIndex + self.audioDemoArr.count;
        self.demoType = tag;
    } else {
        startIndex = TYAudioPageDecordType_demoAccToPCM;
        endIndex = startIndex + self.audioDecordArr.count;
        self.decordtype = tag;
    }
    for (NSInteger i = startIndex; i < endIndex; i++) {
        UIButton *btn = [self.btnsArr objectAtIndex:i];
        [btn setImage:[TYBaseTool getImagaResource:@"ty_icon_select_n" bundleName:@"TianyiUIEngine"] forState:UIControlStateNormal];
    }
    [sender setImage:[TYBaseTool getImagaResource:@"ty_icon_select_s" bundleName:@"TianyiUIEngine"] forState:UIControlStateNormal];
}

- (void)playPCMBtnOnClick:(UIButton *)sender {
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
        [TYAudioRecorder.shared stopRecord];
        [self.recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    }
}

- (void)decordBtnOnClick:(UIButton *)sender {
    
}

- (void)playRecordBtnOnClick:(UIButton *)sender {
    [TYAudioPlayer playAudioWith:_recordPcmPath type:TYAudioPlayType_audioUnit finish:^{

    }];
}

- (void)playDemoBtnOnClick:(UIButton *)sender {
    NSString *path = nil;
    switch (self.demoType) {
        case TYAudioPageDemoType_demoAcc:
            path = [TYBaseTool getFilePath:@"audio/告五人 - 爱人错过" type:@"mp3" bundleName:@"TianyiAVManager"];
            break;
        case TYAudioPageDemoType_demoMp3:
            path = [TYBaseTool getFilePath:@"audio/告五人 - 爱人错过" type:@"mp3" bundleName:@"TianyiAVManager"];
            break;
        case TYAudioPageDemoType_demoCaf:
            path = [TYBaseTool getFilePath:@"audio/告五人 - 爱人错过" type:@"mp3" bundleName:@"TianyiAVManager"];
            break;
        default:
            break;
    }

    if (path == nil) {
        return;
    }
    if (!self.demoPlaying) {
        self.demoPlaying = YES;
        [sender setTitle:@"停播示例音频" forState:UIControlStateNormal];
        __weak typeof(self)weakSelf = self;
        [TYAudioPlayer playAudioWith:path type:TYAudioPlayType_system finish:^{
            NSLog(@"播放完成");
            [sender setTitle:@"播放示例音频" forState:UIControlStateNormal];
            weakSelf.demoPlaying = NO;
        }];
    } else {
        [sender setTitle:@"播放示例音频" forState:UIControlStateNormal];
        self.demoPlaying = NO;
        [TYAudioPlayer stopAllAuido];
    }
}

#pragma mark - lazy init
- (UILabel *)samplePointLb {
    if (!_samplePointLb) {
        _samplePointLb = [UILabel new];
        _samplePointLb.font = [UIFont systemFontOfSize:16];
        _samplePointLb.textColor = [UIColor colorFromHexString:@"333333"];
        _samplePointLb.text = @"PCM波形图";
    }
    return _samplePointLb;
}

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

- (UIButton *)decordBtn {
    if (!_decordBtn) {
        _decordBtn = [UIButton new];
        _decordBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_decordBtn setTitle:@"解码" forState:UIControlStateNormal];
        _decordBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _decordBtn.layer.cornerRadius = 5.0;
        _decordBtn.clipsToBounds = YES;
        [_decordBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_decordBtn addTarget:self action:@selector(decordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _decordBtn;
}

- (UIButton *)playPCMBtn {
    if (!_playPCMBtn) {
        _playPCMBtn = [UIButton new];
        _playPCMBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_playPCMBtn setTitle:@"播放PCM音频" forState:UIControlStateNormal];
        _playPCMBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _playPCMBtn.layer.cornerRadius = 5.0;
        _playPCMBtn.clipsToBounds = YES;
        _playPCMBtn.enabled = NO;
        _playPCMBtn.alpha = 0.5;
        [_playPCMBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_playPCMBtn addTarget:self action:@selector(playPCMBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playPCMBtn;
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

- (UIButton *)playDemoBtn {
    if (!_playDemoBtn) {
        _playDemoBtn = [UIButton new];
        _playDemoBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_playDemoBtn setTitle:@"播放示例音频" forState:UIControlStateNormal];
        _playDemoBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _playDemoBtn.layer.cornerRadius = 5.0;
        _playDemoBtn.clipsToBounds = YES;
        [_playDemoBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_playDemoBtn addTarget:self action:@selector(playDemoBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playDemoBtn;
}

- (NSOperationQueue *)myAudioQue {
    if (!_myAudioQue) {
        _myAudioQue = [[NSOperationQueue alloc] init];
        _myAudioQue.maxConcurrentOperationCount = 1;
    }
    return _myAudioQue;
}

@end
