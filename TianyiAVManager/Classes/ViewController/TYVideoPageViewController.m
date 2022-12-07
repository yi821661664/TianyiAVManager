//
//  TYVideoPageViewController.m
//  TianyiAVManager
//
//  Created by JOJO on 2022/12/5.
//

#import "TYVideoPageViewController.h"

@interface TYVideoPageViewController ()

@end

@implementation TYVideoPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.title = @"视频编解码";
    self.backBtn.hidden = NO;
    self.helpBtn.hidden = NO;
}



@end
