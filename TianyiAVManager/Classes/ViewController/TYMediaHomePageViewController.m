//
//  TYMediaHomePageViewController.m
//  TianyiFunc
//
//  Created by 千刃雪 on 2022/11/4.
//

#import "TYMediaHomePageViewController.h"
#import "TYAudioPageViewController.h"
#import "TYVideoPageViewController.h"

@interface TYMediaHomePageViewController ()

@end

@implementation TYMediaHomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.title = @"音视频相关";
    self.funcsList = @[@"音频编解码",@"视频编解码",@"直播推流"];
    self.backBtn.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)tyBaseListDidSelect:(NSInteger)index {
    UIViewController *vc = nil;
    switch (index) {
        case 0:
            vc = [[TYAudioPageViewController alloc] init];
            break;
        case 1:
            vc = [[TYVideoPageViewController alloc] init];
            break;
        case 2:
            
            break;
        case 3:
            
            break;
        default:
            break;
    }
    if (vc == nil) {
        vc = [[UIViewController alloc] init];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

@end
