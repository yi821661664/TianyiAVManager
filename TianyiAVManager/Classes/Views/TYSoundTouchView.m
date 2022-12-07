//
//  TYSoundTouchView.m
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/6.
//

#import "TYSoundTouchView.h"
#import "AudioSoundTouchOperation.h"
#import "AudioDecodeOperation.h"
#import <TianyiUIEngine/TYHud.h>
#import "TYAudioPlayer.h"
#define TYSoundTouchRecordPath @""

typedef enum : NSUInteger {
    TYSoundTouchViewType_Demo = 0,     // 示例音频数据
    TYSoundTouchViewType_Record,       // 录音音频数据
} TYSoundTouchViewType;

@interface TYSoundTouchView()<TYSelectBaseViewDelegate>

@property(nonatomic, assign) TYSoundTouchViewType type;
@property(nonatomic, assign) BOOL hasRecordData;
@property(nonatomic, strong) UILabel  *yyLb;  // 变声阀值标签
@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playBtn;  // 播放按钮
@property(nonatomic, strong) UISlider *soundTouchSlider;  // 用于调整变声器的数值
@property(nonatomic, strong) NSOperationQueue *myAudioQue;

@property(nonatomic, weak) TYSelectBaseView *selectView1;
@property(nonatomic, weak) TYSelectBaseView *selectView2;

@property(nonatomic, copy)   NSString *tempPath;  // 音频文件编码成WAV后的路径
@property(nonatomic, copy)   NSString *soundTouchPath;  //编码成WAV后文件变声的路径

@end

@implementation TYSoundTouchView

- (void)setupContent {
    self.titleLb.text = @"模块2 - 变声器";
    
    TYSelectBaseView *selectView1 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView1.title = @"示例音频";
    selectView1.delegate = self;
    selectView1.isSelected = YES;
    selectView1.tag = 10000 + TYSoundTouchViewType_Demo;
    [selectView1 setIcon:@"ty_icon_select_s" bundle:@""];
    self.selectView1 = selectView1;
    [self addSubview:selectView1];
    
    TYSelectBaseView *selectView2 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView2.title = @"录音音频";
    selectView2.delegate = self;
    selectView2.isSelected = YES;
    selectView2.tag = 10000 + TYSoundTouchViewType_Record;
    [selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView2 = selectView2;
    [self addSubview:selectView2];
    
    [self addSubview:self.yyLb];
    [self addSubview:self.soundTouchSlider];
    [self addSubview:self.recordBtn];
    [self addSubview:self.playBtn];
    self.soundTouchSlider.value = 0.5;
    
    [self dealWithRecordInfo];
    [self refreshUI];
}

- (void)refreshUI {
    [self.selectView1 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLb.mas_bottom).offset(10);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    [self.selectView2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.selectView1.mas_bottom).offset(0);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    [self.yyLb mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(self.selectView2.mas_bottom);
        make.size.mas_equalTo(CGSizeMake(100, 30));
    }];
    [self.soundTouchSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.yyLb);
        make.left.mas_equalTo(self.yyLb.mas_right).offset(10);
        make.width.mas_equalTo(SCREEN_WIDTH - 140);
    }];
    [self.playBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.selectView2).offset(-15);
        make.top.mas_equalTo(self.yyLb.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.playBtn.mas_left).offset(-10);
        make.top.mas_equalTo(self.yyLb.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    self.contentHeight = self.titleTop + 40 * 2 + 30 * 3 + 35;
}

- (void)tySelectBaseViewOnClick:(TYSelectBaseView *)view {
    TYSoundTouchViewType mType = view.tag - 10000;
    if (mType == self.type) {
        return;
    }
    
    self.type = mType;
    self.recordBtn.hidden = self.type != TYSoundTouchViewType_Record;
    [self.selectView1 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    [view setIcon:@"ty_icon_select_s" bundle:@""];
    
    _playBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
    [_playBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
    if (self.type == TYSoundTouchViewType_Demo) {
        self.playBtn.enabled = YES;
    } else {
        self.playBtn.enabled = self.hasRecordData;
        if (!self.hasRecordData) {
            _playBtn.backgroundColor = [[UIColor colorFromHexString:@"f6f5ec"] colorWithAlphaComponent:0.5];
            [_playBtn setTitleColor:[UIColor colorFromHexString:@"999999"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark - actions
- (void)recordBtnOnClick:(UIButton *)sender {
    
}

- (void)playBtnOnClick:(UIButton *)sender {
    [TYAudioPlayer stopAllAuido];
    if (self.delegate && [self.delegate respondsToSelector:@selector(tyAudioBaseViewStartWorking:)]) {
        [self.delegate tyAudioBaseViewStartWorking:self];
    }
    if (self.type == TYSoundTouchViewType_Demo) {
        [self soundTouchDemo];
    } else {
        [self soundTouchRecord];
    }
}

- (void)sliderValueChanged:(UISlider *)sender {
    _yyLb.text = [NSString stringWithFormat:@"变声阀值(%.0lf)",self.soundTouchSlider.value * 24 - 12];
}

// 设置路径
- (void)dealWithRecordInfo {
    self.recordPcmPath = [self.fileFolder stringByAppendingPathComponent:@"record.pcm"];
    _tempPath = [self.fileFolder stringByAppendingPathComponent:@"ttttRecord.wav"];
    _soundTouchPath = [self.fileFolder stringByAppendingPathComponent:@"stRecord.wav"];
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(tyAudioBaseViewStopWorking:)]) {
        [self.delegate tyAudioBaseViewStopWorking:self];
    }
}

- (void)didDecode:(NSString *)tmpPath {
    // 解码失败
    if (!tmpPath) {
        [TYHud disMiss];
        [TYHud showToast:@"解码失败" duration:0 userInteraction:YES];
        if (self.delegate && [self.delegate respondsToSelector:@selector(tyAudioBaseViewStopWorking:)]) {
            [self.delegate tyAudioBaseViewStopWorking:self];
        }
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(tyAudioBaseViewStopWorking:)]) {
        [self.delegate tyAudioBaseViewStopWorking:self];
    }
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
        _recordBtn.hidden = YES;
        [_recordBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_recordBtn addTarget:self action:@selector(recordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordBtn;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton new];
        _playBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_playBtn setTitle:@"播放音频" forState:UIControlStateNormal];
        _playBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _playBtn.layer.cornerRadius = 5.0;
        _playBtn.clipsToBounds = YES;
        [_playBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UILabel *)yyLb {
    if (!_yyLb) {
        _yyLb = [UILabel new];
        _yyLb.textColor = [UIColor colorFromHexString:@"333333"];
        _yyLb.font = [UIFont systemFontOfSize:15];
        _yyLb.textAlignment = NSTextAlignmentLeft;
        _yyLb.text = @"变声阀值(0)";
    }
    return _yyLb;
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

// 根据录音的数据而来，如果有，则可以播放录音的内容
- (BOOL)hasRecordData {
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager fileExistsAtPath:self.recordPcmPath];
}

@end
