//
//  TYAudioBaseView.h
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/6.
//

#import <UIKit/UIKit.h>
#import <Masonry/Masonry.h>
#import <Colours/Colours.h>
#import <TianyiUIEngine/TYDefine.h>
#import <TianyiUIEngine/TYBaseTool.h>
#import <TianyiUIEngine/TYSelectBaseView.h>

NS_ASSUME_NONNULL_BEGIN

@class TYAudioBaseView;

@protocol TYAudioBaseViewDelegate <NSObject>

/// 有阻断性操作时产生的回调
- (void)tyAudioBaseViewStartWorking:(TYAudioBaseView *)view;
/// 阻断结束时产生的回调
- (void)tyAudioBaseViewStopWorking:(TYAudioBaseView *)view;

@end

@interface TYAudioBaseView : UIView

/// 标题内容
@property(nonatomic, strong) UILabel *titleLb;

/// 录音后形成的PCM文件路径
@property(nonatomic, copy)   NSString *fileFolder;

/// 录音后形成的PCM文件路径
@property(nonatomic, copy)   NSString *recordPcmPath;

/// 选择框
@property(nonatomic, strong) NSMutableArray <TYSelectBaseView *>*cells;

/// 内容高度
@property(nonatomic, assign) CGFloat contentHeight;

/// 标题栏距离上方的距离（默认是10）
@property(nonatomic, assign) CGFloat titleTop;

/// 是否显示底部分割线
@property(nonatomic, assign) BOOL showLine;

/// 设置事件代理
@property(nonatomic, weak) id<TYAudioBaseViewDelegate> delegate;

/// 初始化UI
- (void)setupContent;

/// 更新UI
- (void)refreshUI;

@end

NS_ASSUME_NONNULL_END
