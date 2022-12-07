//
//  TYRecordView.m
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/6.
//

#import "TYRecordView.h"

typedef enum : NSUInteger {
    TYRecordViewType_Stystem = 0,     // 系统录音工具
    TYRecordViewType_AudioUnit,       // AudioUnit
    TYRecordViewType_AudioQueue,      // AudioQueue
} TYRecordViewType;

@interface TYRecordView()<TYSelectBaseViewDelegate>

@property(nonatomic, assign) TYRecordViewType type;
@property(nonatomic, assign) BOOL hasRecordData;
@property(nonatomic, strong) UIButton *recordBtn;  // 录音按钮
@property(nonatomic, strong) UIButton *playBtn;  // 播放按钮

@property(nonatomic, weak) TYSelectBaseView *selectView1;
@property(nonatomic, weak) TYSelectBaseView *selectView2;
@property(nonatomic, weak) TYSelectBaseView *selectView3;

@end

@implementation TYRecordView

- (void)setupContent {
    self.titleLb.text = @"模块1 - 录音";
    
    TYSelectBaseView *selectView1 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView1.title = @"系统录音器";
    selectView1.delegate = self;
    selectView1.isSelected = YES;
    selectView1.tag = 10000 + TYRecordViewType_Stystem;
    [selectView1 setIcon:@"ty_icon_select_s" bundle:@""];
    self.selectView1 = selectView1;
    [self addSubview:selectView1];
    
    TYSelectBaseView *selectView2 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView2.title = @"AudioUnit";
    selectView2.delegate = self;
    selectView2.isSelected = YES;
    selectView2.tag = 10000 + TYRecordViewType_AudioUnit;
    [selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView2 = selectView2;
    [self addSubview:selectView2];
    
    TYSelectBaseView *selectView3 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView3.title = @"AudioQueue";
    selectView3.delegate = self;
    selectView3.isSelected = YES;
    selectView3.tag = 10000 + TYRecordViewType_AudioQueue;
    [selectView3 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView3 = selectView3;
    [self addSubview:selectView3];
    
    self.playBtn.hidden = !self.hasRecordData;
    [self addSubview:self.recordBtn];
    [self addSubview:self.playBtn];
    
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
    [self.selectView3 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.selectView2.mas_bottom).offset(0);
        make.left.mas_equalTo(0);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(SCREEN_WIDTH);
    }];
    [self.playBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.selectView3).offset(-15);
        make.top.mas_equalTo(self.selectView3.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (self.hasRecordData) {
            make.right.mas_equalTo(self.playBtn.mas_left).offset(-10);
        } else {
            make.right.mas_equalTo(self.selectView3).offset(-15);
        }
        make.top.mas_equalTo(self.selectView3.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    self.contentHeight = self.titleTop + 40 * 4 + 30 + 35;
}

- (void)tySelectBaseViewOnClick:(TYSelectBaseView *)view {
    TYRecordViewType mType = view.tag - 10000;
    if (mType == self.type) {
        return;
    }
    
    self.type = mType;
    [self.selectView1 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView3 setIcon:@"ty_icon_select_n" bundle:@""];
    [view setIcon:@"ty_icon_select_s" bundle:@""];
    
    _playBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
    [_playBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
    self.playBtn.enabled = self.hasRecordData;
    if (!self.hasRecordData) {
        _playBtn.backgroundColor = [[UIColor colorFromHexString:@"f6f5ec"] colorWithAlphaComponent:0.5];
        [_playBtn setTitleColor:[UIColor colorFromHexString:@"999999"] forState:UIControlStateNormal];
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

- (BOOL)hasRecordData {
    // 根据录音的数据而来，如果有，则可以播放录音的内容
    return NO;
}

@end
