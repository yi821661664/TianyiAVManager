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
#import "TYEncordView.h"
#import "TYRecordView.h"
#import "TYEZAudioView.h"
#import "TYSoundTouchView.h"

typedef enum : NSUInteger {
    TYAudioPageEncordType_PCM_AAC = 3,     // PCM 数据流 -> AAC音频
    TYAudioPageEncordType_PCM_MP3,      // PCM 数据流 -> MP3音频
    TYAudioPageEncordType_PCM_WAV,      // PCM 数据流 -> WAV音频
} TYAudioPageEncordType;

@interface TYAudioPageViewController ()

@property(nonatomic, strong) UIScrollView *scroll;
@property(nonatomic, strong) TYEZAudioView *ezAudioContentView;  // 音谱
@property(nonatomic, strong) TYSoundTouchView *touchContentView;    // 变声器
@property(nonatomic, strong) TYRecordView *recordContentView;   // 多种录音
@property(nonatomic, strong) TYEncordView *encordContentView;   // 编解码

@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playRecordBtn;    // 播放录音按钮
@property(nonatomic, strong) UIButton *encordBtn;  // 解码按钮
@property(nonatomic, strong) UIButton *playPCMBtn; // 播放PCM数据

@property(nonatomic, assign) BOOL hasRecordFile;
@property(nonatomic, assign) TYAudioRecordType recordType;
@property(nonatomic, assign) TYAudioPageEncordType encordtype;
@property(nonatomic, strong) NSArray <NSString *>*recordTypeArr;
@property(nonatomic, strong) NSArray <NSString *>*audioEncordArr;
@property(nonatomic, strong) NSMutableArray <UIButton *>*btnsArr;
@property(nonatomic, weak)   UIView *lastV;

@end

@implementation TYAudioPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"音频编码与解码";
    [self setupUI];
    
//    self.recordTypeArr = @[@"系统高级Api录音",@"AudioUnit录音",@"AudioQueue录音"];
//    self.audioEncordArr = @[@"PCM->AAC音频",@"PCM->MP3音频",@"PCM->WAV音频"];
//    self.soundTouchArr = @[@"示例音频变声",@"录音音频变声"];
//    self.btnsArr = @[].mutableCopy;
//    [self checkRecordFileInfo];
    self.backBtn.hidden = NO;
    self.helpBtn.hidden = NO;
//    self.recordType = TYAudioRecordType_system;
//    self.encordtype = TYAudioPageEncordType_PCM_AAC;
//    self.soundTouchType = TYAudioPagesoundTouchType_Demo;
//    self.lastV = [self setupUI:self.recordTypeArr atIndex:self.recordType topView:nil];
//    if (_hasRecordFile) {
//        self.lastV = [self setupUI:self.audioEncordArr atIndex:self.encordtype topView:self.lastV];
//        [self setupUI:self.soundTouchArr atIndex:self.soundTouchType topView:self.lastV];
//    }
}

- (void)setupUI {
    CGFloat height = .0;
    
    self.recordContentView = [[TYRecordView alloc] initWithFrame:CGRectZero];
    self.recordContentView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.recordContentView.contentHeight);
    height += self.recordContentView.contentHeight;
    
    self.touchContentView = [[TYSoundTouchView alloc] initWithFrame:CGRectZero];
    self.touchContentView.frame = CGRectMake(0, height, SCREEN_WIDTH, self.touchContentView.contentHeight);
    height += self.touchContentView.contentHeight;
    
    self.ezAudioContentView = [[TYEZAudioView alloc] initWithFrame:CGRectZero];
    self.ezAudioContentView.frame = CGRectMake(0, height, SCREEN_WIDTH, self.ezAudioContentView.contentHeight);
    height += self.ezAudioContentView.contentHeight;
    
    self.encordContentView = [[TYEncordView alloc] initWithFrame:CGRectZero];
    self.encordContentView.frame = CGRectMake(0, height, SCREEN_WIDTH, self.encordContentView.contentHeight);
    height += self.encordContentView.contentHeight;
    
    self.scroll.contentSize = CGSizeMake(0, height);
    self.scroll.frame = [UIScreen mainScreen].bounds;
    [self.scroll addSubview:self.recordContentView];
    [self.scroll addSubview:self.touchContentView];
    [self.scroll addSubview:self.ezAudioContentView];
    [self.scroll addSubview:self.encordContentView];
    [self.view addSubview:self.scroll];
}

/// 检查本地是否已有录音好的PCM文件
- (void)checkRecordFileInfo {
    
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
            _hasRecordFile = YES;
        }
        [TYAudioRecorder.shared stopRecord];
        [self.recordBtn setTitle:@"开始录音" forState:UIControlStateNormal];
    }
}

- (void)encordBtnOnClick:(UIButton *)sender {
    
}

- (void)playRecordBtnOnClick:(UIButton *)sender {
    
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

- (UIScrollView *)scroll {
    if(!_scroll) {
        _scroll = [[UIScrollView alloc] init];
        _scroll.showsVerticalScrollIndicator = NO;
        _scroll.showsHorizontalScrollIndicator = NO;
    }
    return _scroll;
}

@end
