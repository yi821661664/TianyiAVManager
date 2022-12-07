//
//  TYEZAudioView.m
//  Colours
//
//  Created by JOJO on 2022/12/6.
//

#import "TYEZAudioView.h"

typedef enum : NSUInteger {
    TYEZAudioViewType_Demo = 0,     // 示例音频数据
    TYEZAudioViewType_Record,       // 录音音频数据
} TYEZAudioViewType;

@interface TYEZAudioView()<TYSelectBaseViewDelegate>

@property(nonatomic, assign) TYEZAudioViewType type;
@property(nonatomic, assign) BOOL hasRecordData;
@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playBtn;  // 播放按钮
@property(nonatomic, strong) UIView *ypView;  // 音谱视图

@property(nonatomic, weak) TYSelectBaseView *selectView1;
@property(nonatomic, weak) TYSelectBaseView *selectView2;

@end

@implementation TYEZAudioView

- (void)setupContent {
    self.titleLb.text = @"模块3 - 音频波形图";
    
    TYSelectBaseView *selectView1 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView1.title = @"示例音频";
    selectView1.delegate = self;
    selectView1.isSelected = YES;
    selectView1.tag = 10000 + TYEZAudioViewType_Demo;
    [selectView1 setIcon:@"ty_icon_select_s" bundle:@""];
    self.selectView1 = selectView1;
    [self addSubview:selectView1];
    
    TYSelectBaseView *selectView2 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView2.title = @"录音音频";
    selectView2.delegate = self;
    selectView2.isSelected = YES;
    selectView2.tag = 10000 + TYEZAudioViewType_Record;
    [selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView2 = selectView2;
    [self addSubview:selectView2];
    
    self.recordBtn.hidden = !self.hasRecordData;
    [self addSubview:self.recordBtn];
    [self addSubview:self.playBtn];
    [self addSubview:self.ypView];
    
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
    [self.playBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.selectView2).offset(-15);
        make.top.mas_equalTo(self.selectView2.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.playBtn.mas_left).offset(-10);
        make.top.mas_equalTo(self.selectView2.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    [self.ypView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.recordBtn.mas_bottom).offset(10);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(self.selectView2);
        make.height.mas_equalTo(120);
    }];
    self.contentHeight = self.titleTop + 40 * 4 + 30 + 120;
}

- (void)tySelectBaseViewOnClick:(TYSelectBaseView *)view {
    TYEZAudioViewType mType = view.tag - 10000;
    if (mType == self.type) {
        return;
    }
    
    self.type = mType;
    self.recordBtn.hidden = self.type != TYEZAudioViewType_Record;
    [self.selectView1 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    [view setIcon:@"ty_icon_select_s" bundle:@""];
    
    _playBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
    [_playBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
    if (self.type == TYEZAudioViewType_Demo) {
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

- (UIView *)ypView {
    if (!_ypView) {
        _ypView = [UIView new];
    }
    return _ypView;
}

- (BOOL)hasRecordData {
    // 根据录音的数据而来，如果有，则可以播放录音的内容
    return NO;
}

@end
