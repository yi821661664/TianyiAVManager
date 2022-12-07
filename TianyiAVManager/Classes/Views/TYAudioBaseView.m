//
//  TYAudioBaseView.m
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/6.
//

#import "TYAudioBaseView.h"

@interface TYAudioBaseView()

@property(nonatomic, strong) UIView *lineView;

@end

@implementation TYAudioBaseView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupContent];
    }
    return self;
}

- (void)setupUI {
    self.cells = @[].mutableCopy;
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    // 设置文件夹路径
    self.fileFolder = [NSString stringWithFormat:@"%@/TYRecord", directory];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.fileFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:self.fileFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    // 处理显示问题
    self.titleLb = [UILabel new];
    self.titleLb.font = [UIFont systemFontOfSize:16];
    self.titleLb.textColor = [UIColor colorFromHexString:@"333333"];
    [self addSubview:self.titleLb];
    self.titleTop = 15;
    
    self.lineView = [UIView new];
    self.lineView.backgroundColor = [[UIColor colorFromHexString:@"999999"] colorWithAlphaComponent:0.5];
    [self addSubview:self.lineView];

    [self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.width.mas_equalTo(SCREEN_WIDTH - 30);
        make.bottom.mas_equalTo(0);
        make.height.mas_equalTo(1);
    }];
}

- (void)setTitleTop:(CGFloat)titleTop {
    _titleTop = titleTop;
    [self.titleLb mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(15);
        make.top.mas_equalTo(_titleTop);
    }];
}

- (void)setupContent {
    
}

- (void)refreshUI {
    
}

- (void)setShowLine:(BOOL)showLine {
    _showLine = showLine;
    self.lineView.hidden = !_showLine;
}

@end
