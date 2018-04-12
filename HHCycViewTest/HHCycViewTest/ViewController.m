//
//  ViewController.m
//  HHCycViewTest
//
//  Created by 黄华 on 2018/4/12.
//  Copyright © 2018年 huanghua. All rights reserved.
//

#import "ViewController.h"
#import "HHCycBaseLayout.h"
#import "HHPageControl.h"
#import "HHCycView.h"

@interface ViewController ()<HHCycViewDelegate,HHCycViewDataSource>

@property (nonatomic, strong) HHCycView *cycView;
@property (nonatomic, strong) HHPageControl *pageControl;
@property (nonatomic, strong) NSArray *datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self _initPagerView];
    
    [self _initPageControl];
    
    [self loadData];
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _cycView.frame = CGRectMake(0, 64, CGRectGetWidth(self.view.frame), 300);
    _pageControl.frame = CGRectMake(0, CGRectGetHeight(_cycView.frame) - 26, CGRectGetWidth(_cycView.frame), 26);
}


- (void)_initPagerView {
    
    HHCycView *cycView = [[HHCycView alloc]init];
    //cycView.layer.borderWidth = 1;
    cycView.isInfiniteLoop = YES;
    cycView.autoScrollInterval = 0.0;
    cycView.dataSource = self;
    cycView.delegate = self;
    [cycView registerClass:[CycViewCell class] forCellWithReuseIdentifier:@"CycViewCell_Id"];
    [self.view addSubview:cycView];
    _cycView = cycView;
}


- (void)_initPageControl {

    HHPageControl *pageControl = [[HHPageControl alloc]init];
    //pageControl.numberOfPages = _datas.count;
    pageControl.currentPageIndicatorSize = CGSizeMake(8, 8);
    pageControl.currentPageIndicatorTintColor = [UIColor greenColor];
    [_cycView addSubview:pageControl];
    _pageControl = pageControl;
}


- (void)loadData{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSMutableArray *datas = [NSMutableArray array];
        for (int i = 0; i < 6; ++i) {
            if (i == 0) {
                [datas addObject:[UIColor redColor]];
                continue;
            }
            [datas addObject:[UIColor blueColor]];
        }
        self->_datas = [datas copy];
        self->_pageControl.numberOfPages = self->_datas.count;
        [self->_cycView reloadData];
    });
}


#pragma mark - TYCyclePagerViewDataSource

- (NSInteger)numberOfItemsInPagerView:(HHCycView *)pageView {
    return _datas.count;
}


- (void)pagerView:(HHCycView *)pageView didSelectedItemCell:(UICollectionViewCell *)cell atIndex:(NSIndexPath *)indexPath{
    
    NSLog(@"%ld -> ",indexPath.row);
    
}

- (UICollectionViewCell *)pagerView:(HHCycView *)pagerView cellForItemAtIndex:(NSIndexPath *)indexPath {
    
    CycViewCell *cell = (CycViewCell*)[pagerView dequeueReusableCellWithReuseIdentifier:@"CycViewCell_Id" forIndex:indexPath.row];
    
    cell.backgroundColor = _datas[indexPath.row];
    
    cell.label.text = [NSString stringWithFormat:@"-----%ld------",indexPath.row];
    
    return cell;
}

- (HHCycViewLayout *)layoutForPagerView:(HHCycView *)pageView {
    
    HHCycViewLayout *layout = [[HHCycViewLayout alloc]init];
    layout.itemSize = CGSizeMake(CGRectGetWidth(pageView.frame)*0.8, CGRectGetHeight(pageView.frame)*0.8);
    layout.itemSpacing = 15;
    //layout.minimumAlpha = 0.3;
    layout.itemHorizontalCenter = YES;
    return layout;
}

- (void)pagerView:(HHCycView *)pageView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    _pageControl.currentPage = toIndex;
    NSLog(@"%ld ->  %ld",fromIndex,toIndex);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end










@interface CycViewCell ()
@property (nonatomic, weak) UILabel *label;
@end

@implementation CycViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addLabel];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
        [self addLabel];
    }
    return self;
}


- (void)addLabel {
    UILabel *label = [[UILabel alloc]init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:18];
    [self addSubview:label];
    _label = label;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = self.bounds;
}

@end

