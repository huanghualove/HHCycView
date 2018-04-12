//
//  HHCycView.h
//  HHCycViewTest
//
//  Created by 黄华 on 2018/4/12.
//  Copyright © 2018年 huanghua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HHCycBaseLayout.h"

//滑动方向
typedef NS_ENUM(NSUInteger, HHPagerScrollDirection) {
    HHPagerScrollDirectionLeft,
    HHPagerScrollDirectionRight,
};

//数据协议代理

@class HHCycView;

@protocol HHCycViewDataSource <NSObject>

- (NSInteger)numberOfItemsInPagerView:(HHCycView *)cycView;

- (UICollectionViewCell *)pagerView:(HHCycView *)cycView cellForItemAtIndex:(NSIndexPath *)indexPath;

- (HHCycViewLayout *)layoutForPagerView:(HHCycView *)pageView;

@end




@protocol HHCycViewDelegate <NSObject>

@optional

- (void)pagerView:(HHCycView *)cycView didScrollFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)pagerView:(HHCycView *)cycView didSelectedItemCell:(UICollectionViewCell *)cell atIndex:(NSIndexPath *)indexPath;
- (void)pagerView:(HHCycView *)cycView initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;
- (void)pagerView:(HHCycView *)cycView applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

// scrollViewDelegate
- (void)pagerViewDidScroll:(HHCycView *)cycView;
- (void)pagerViewWillBeginDragging:(HHCycView *)cycView;
- (void)pagerViewDidEndDragging:(HHCycView *)cycView willDecelerate:(BOOL)decelerate;
- (void)pagerViewWillBeginDecelerating:(HHCycView *)cycView;
- (void)pagerViewDidEndDecelerating:(HHCycView *)cycView;
- (void)pagerViewWillBeginScrollingAnimation:(HHCycView *)cycView;
- (void)pagerViewDidEndScrollingAnimation:(HHCycView *)cycView;

@end





@interface HHCycView : UIView

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, weak) id<HHCycViewDataSource> dataSource;
@property (nonatomic, weak) id<HHCycViewDelegate> delegate;
@property (nonatomic, weak,   readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) HHCycViewLayout *layout;
@property (nonatomic, assign) BOOL isInfiniteLoop;
@property (nonatomic, assign) CGFloat autoScrollInterval;
@property (nonatomic, assign, readonly) NSInteger curIndex;

@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) BOOL tracking;
@property (nonatomic, assign, readonly) BOOL dragging;
@property (nonatomic, assign, readonly) BOOL decelerating;

- (void)reloadData;
- (void)updateData;
- (void)setNeedUpdateLayout;
- (void)setNeedClearLayout;

- (UICollectionViewCell *)curIndexCell;
- (NSArray<UICollectionViewCell *> *)visibleCells;
- (NSArray *)visibleIndexs;
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;
- (void)scrollToNearlyIndexAtDirection:(HHPagerScrollDirection)direction animate:(BOOL)animate;
- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
- (UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;


@end
