//
//  TYEncordView.m
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/6.
//

#import "TYEncordView.h"

typedef enum : NSUInteger {
    TYEncordViewType_PCM_AAC = 0,     // PCM -> AAC
    TYEncordViewType_AAC_PCM,         // AAC -> PCM
    TYEncordViewType_PCM_MP3,         // PCM -> MP3
} TYEncordViewType;

@interface TYEncordView()<TYSelectBaseViewDelegate>

@property(nonatomic, assign) BOOL isTransfroming; // 是否正在转化，如果是，本模块下所有内容将失去交互作用
@property(nonatomic, assign) TYEncordViewType type;
@property(nonatomic, strong) UIButton *startBtn;  // 开始按钮

@property(nonatomic, weak) TYSelectBaseView *selectView1;
@property(nonatomic, weak) TYSelectBaseView *selectView2;
@property(nonatomic, weak) TYSelectBaseView *selectView3;

@end

@implementation TYEncordView

- (void)setupContent {
    self.titleLb.text = @"模块4 - 编解码以及转化";
    
    TYSelectBaseView *selectView1 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView1.title = @"PCM -> AAC";
    selectView1.delegate = self;
    selectView1.isSelected = YES;
    selectView1.tag = 10000 + TYEncordViewType_PCM_AAC;
    [selectView1 setIcon:@"ty_icon_select_s" bundle:@""];
    self.selectView1 = selectView1;
    [self addSubview:selectView1];
    
    TYSelectBaseView *selectView2 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView2.title = @"AAC -> PCM";
    selectView2.delegate = self;
    selectView2.isSelected = YES;
    selectView2.tag = 10000 + TYEncordViewType_AAC_PCM;
    [selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView2 = selectView2;
    [self addSubview:selectView2];
    
    TYSelectBaseView *selectView3 = [[TYSelectBaseView alloc] initWithFrame:CGRectZero];
    selectView3.title = @"PCM -> MP3";
    selectView3.delegate = self;
    selectView3.isSelected = YES;
    selectView3.tag = 10000 + TYEncordViewType_PCM_MP3;
    [selectView3 setIcon:@"ty_icon_select_n" bundle:@""];
    self.selectView3 = selectView3;
    [self addSubview:selectView3];
    
    [self addSubview:self.startBtn];
    
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
    [self.startBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.selectView3).offset(-15);
        make.top.mas_equalTo(self.selectView3.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 40));
    }];
    self.contentHeight = self.titleTop + 40 * 4 + 30 + 25;
}

- (void)tySelectBaseViewOnClick:(TYSelectBaseView *)view {
    TYEncordViewType mType = view.tag - 10000;
    if (mType == self.type) {
        return;
    }
    
    self.type = mType;
    [self.selectView1 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView2 setIcon:@"ty_icon_select_n" bundle:@""];
    [self.selectView3 setIcon:@"ty_icon_select_n" bundle:@""];
    [view setIcon:@"ty_icon_select_s" bundle:@""];
}

#pragma mark - actions
- (void)recordBtnOnClick:(UIButton *)sender {
    
}

- (void)playBtnOnClick:(UIButton *)sender {
    
}

#pragma mark - lazy init
- (UIButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [UIButton new];
        _startBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_startBtn setTitle:@"开始转化" forState:UIControlStateNormal];
        _startBtn.backgroundColor = [UIColor colorFromHexString:@"f6f5ec"];
        _startBtn.layer.cornerRadius = 5.0;
        _startBtn.clipsToBounds = YES;
        [_startBtn setTitleColor:[UIColor colorFromHexString:@"2a5caa"] forState:UIControlStateNormal];
        [_startBtn addTarget:self action:@selector(recordBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

@end
