//
//  HHCycView.m
//  HHCycViewTest
//
//  Created by 黄华 on 2018/4/12.
//  Copyright © 2018年 huanghua. All rights reserved.
//

#import "HHCycView.h"

typedef struct {
    NSInteger index;
    NSInteger section;
}HHIndexSection;


NS_INLINE BOOL HHEqualIndexSection(HHIndexSection indexSection_1,HHIndexSection indexSection_2){
    return indexSection_1.index == indexSection_2.index && indexSection_1.section == indexSection_2.section;
}

NS_INLINE HHIndexSection HHMakeIndexSection(NSInteger index, NSInteger section) {
    HHIndexSection indexSection;
    indexSection.index = index;
    indexSection.section = section;
    return indexSection;
}

#define kPagerViewMaxSectionCount 200
#define kPagerViewMinSectionCount 18



#pragma mark    -----   HHCycView

@interface HHCycView () <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,HHCycBaseLayoutDelegate> {
    struct {
        unsigned int pagerViewDidScroll   :1;
        unsigned int didScrollFromIndexToNewIndex   :1;
        unsigned int initializeTransformAttributes   :1;
        unsigned int applyTransformToAttributes   :1;
    }_delegateFlags;
    struct {
        unsigned int cellForItemAtIndex   :1;
        unsigned int layoutForPagerView   :1;
    }_dataSourceFlags;
}
// UI
@property (nonatomic, weak)   UICollectionView *collectionView;
@property (nonatomic, strong) HHCycViewLayout *layout;
@property (nonatomic, strong) NSTimer *timer;
// Data
@property (nonatomic, assign) NSInteger numberOfItems;
@property (nonatomic, assign) HHIndexSection indexSection; // current index
@property (nonatomic, assign) NSInteger dequeueSection;
@property (nonatomic, assign) HHIndexSection beginDragIndexSection;
@property (nonatomic, assign) NSInteger firstScrollIndex;

@property (nonatomic, assign) BOOL needClearLayout;
@property (nonatomic, assign) BOOL didReloadData;
@property (nonatomic, assign) BOOL didLayout;

@end



@implementation HHCycView

#pragma mark --- lifeCycle

- (instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) {
        [self _initConfigureProperty];
        [self _initCollectionView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self == [super initWithCoder:aDecoder]) {
        [self _initConfigureProperty];
        [self _initCollectionView];
    }
    return self;
}

- (void)_initConfigureProperty{
    _didReloadData = NO;
    _didLayout = NO;
    _autoScrollInterval = 0;
    _isInfiniteLoop = YES;
    _beginDragIndexSection.index = 0;
    _beginDragIndexSection.section = 0;
    _indexSection.index = -1;
    _indexSection.section = -1;
    _firstScrollIndex = -1;
}

- (void)_initCollectionView{
    HHCycBaseLayout *layout = [[HHCycBaseLayout alloc]init];
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
    layout.delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = NO;
    collectionView.decelerationRate = 1-0.0076;
    if ([collectionView respondsToSelector:@selector(setPrefetchingEnabled:)])
    {
        collectionView.prefetchingEnabled = NO;
    }
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}


#pragma mark  ---  Timer

- (void)addTimer {
    if (_timer) {return;}
    _timer = [NSTimer timerWithTimeInterval:_autoScrollInterval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    if (!_timer) {return;}
    [_timer invalidate];
    _timer = nil;
}

- (void)timerFired:(NSTimer *)timer {
    if (!self.superview || !self.window || _numberOfItems == 0 || self.tracking) {return;}
    [self scrollToNearlyIndexAtDirection:HHPagerScrollDirectionRight animate:YES];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (!newSuperview) {
        [self removeTimer];
    }else {
        [self removeTimer];
        if (_autoScrollInterval > 0) {
            [self addTimer];
        }
    }
}



#pragma mark  ---   property set get

- (HHCycViewLayout *)layout{
    if (!_layout) {
        if (_dataSourceFlags.layoutForPagerView) {
            _layout = [_dataSource layoutForPagerView:self];
            _layout.isInfiniteLoop = _isInfiniteLoop;
        }
        if (_layout.itemSize.width <= 0 || _layout.itemSize.height <= 0) {
            _layout = nil;
        }
    }
    return _layout;
}

- (NSInteger)curIndex {
    return _indexSection.index;
}

- (CGPoint)contentOffset {
    return _collectionView.contentOffset;
}

- (BOOL)tracking {
    return _collectionView.tracking;
}

- (BOOL)dragging {
    return _collectionView.dragging;
}

- (BOOL)decelerating {
    return _collectionView.decelerating;
}

- (UIView *)backgroundView {
    return _collectionView.backgroundView;
}

- (UICollectionViewCell *)curIndexCell {
    return [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_indexSection.index inSection:_indexSection.section]];
}

- (NSArray<UICollectionViewCell *> *)visibleCells {
    return _collectionView.visibleCells;
}

- (NSArray *)visibleIndexs {
    NSMutableArray *indexs = [NSMutableArray array];
    for (NSIndexPath *indexPath in _collectionView.indexPathsForVisibleItems) {
        [indexs addObject:@(indexPath.item)];
    }
    return [indexs copy];
}

#pragma mark - setter

- (void)setBackgroundView:(UIView *)backgroundView {
    [_collectionView setBackgroundView:backgroundView];
}

- (void)setAutoScrollInterval:(CGFloat)autoScrollInterval {
    _autoScrollInterval = autoScrollInterval;
    [self removeTimer];
    if (autoScrollInterval > 0 && self.superview) {
        [self addTimer];
    }
}

- (void)setDelegate:(id<HHCycViewDelegate>)delegate{
    _delegate = delegate;
    _delegateFlags.pagerViewDidScroll = [delegate respondsToSelector:@selector(pagerViewDidScroll:)];
    _delegateFlags.didScrollFromIndexToNewIndex = [delegate respondsToSelector:@selector(pagerView:didScrollFromIndex:toIndex:)];
    _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerView:initializeTransformAttributes:)];
    _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerView:applyTransformToAttributes:)];
    if (self.collectionView && self.collectionView.collectionViewLayout) {
        ((HHCycBaseLayout *)self.collectionView.collectionViewLayout).delegate = _delegateFlags.applyTransformToAttributes ? self : nil;
    }
}



- (void)setDataSource:(id<HHCycViewDataSource>)dataSource{
    _dataSource = dataSource;
    _dataSourceFlags.cellForItemAtIndex = [dataSource respondsToSelector:@selector(pagerView:cellForItemAtIndex:)];
    _dataSourceFlags.layoutForPagerView = [dataSource respondsToSelector:@selector(layoutForPagerView:)];
}

#pragma mark - public

- (void)reloadData {
    _didReloadData = YES;
    [self setNeedClearLayout];
    [self clearLayout];
    [self updateData];
}

// not clear layout
- (void)updateData {
    [self updateLayout];
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    [_collectionView reloadData];
    if (!_didLayout && !CGRectIsEmpty(self.frame) && _indexSection.index < 0) {
        _didLayout = YES;
    }
    [self resetPagerViewAtIndex:_indexSection.index < 0 && !CGRectIsEmpty(self.frame) ? 0 :_indexSection.index];
}

- (void)scrollToNearlyIndexAtDirection:(HHPagerScrollDirection)direction animate:(BOOL)animate {
    HHIndexSection indexSection = [self nearlyIndexPathAtDirection:direction];
    [self scrollToItemAtIndexSection:indexSection animate:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (!_didLayout && _didReloadData) {
        _firstScrollIndex = index;
    }else {
        _firstScrollIndex = -1;
    }
    if (!_isInfiniteLoop) {
        [self scrollToItemAtIndexSection:HHMakeIndexSection(index, 0) animate:animate];
        return;
    }
    
    [self scrollToItemAtIndexSection:HHMakeIndexSection(index, index >= self.curIndex ? _indexSection.section : _indexSection.section+1) animate:animate];
}

- (void)scrollToItemAtIndexSection:(HHIndexSection)indexSection animate:(BOOL)animate {
    if (_numberOfItems <= 0 || ![self isValidIndexSection:indexSection]) {
        //NSLog(@"scrollToItemAtIndex: item indexSection is invalid!");
        return;
    }
    
    if (animate && [_delegate respondsToSelector:@selector(pagerViewWillBeginScrollingAnimation:)]) {
        [_delegate pagerViewWillBeginScrollingAnimation:self];
    }
    CGFloat offset = [self caculateOffsetXAtIndexSection:indexSection];
    [_collectionView setContentOffset:CGPointMake(offset, _collectionView.contentOffset.y) animated:animate];
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:_dequeueSection]];
    return cell;
}

#pragma mark - configure layout

- (void)updateLayout {
    if (!self.layout) {
        return;
    }
    self.layout.isInfiniteLoop = _isInfiniteLoop;
    ((HHCycBaseLayout *)_collectionView.collectionViewLayout).layout = self.layout;
}

- (void)clearLayout {
    if (_needClearLayout) {
        _layout = nil;
        _needClearLayout = NO;
    }
}

- (void)setNeedClearLayout {
    _needClearLayout = YES;
}

- (void)setNeedUpdateLayout {
    if (!self.layout) {
        return;
    }
    [self clearLayout];
    [self updateLayout];
    [_collectionView.collectionViewLayout invalidateLayout];
    [self resetPagerViewAtIndex:_indexSection.index < 0 ? 0 :_indexSection.index];
}

#pragma mark - pagerIndex

- (BOOL)isValidIndexSection:(HHIndexSection)indexSection {
    return indexSection.index >= 0 && indexSection.index < _numberOfItems && indexSection.section >= 0 && indexSection.section < kPagerViewMaxSectionCount;
}

- (HHIndexSection)nearlyIndexPathAtDirection:(HHPagerScrollDirection)direction{
    return [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
}

- (HHIndexSection)nearlyIndexPathForIndexSection:(HHIndexSection)indexSection direction:(HHPagerScrollDirection)direction {
    if (indexSection.index < 0 || indexSection.index >= _numberOfItems) {
        return indexSection;
    }
    
    if (!_isInfiniteLoop) {
        if (direction == HHPagerScrollDirectionRight && indexSection.index == _numberOfItems - 1) {
            return _autoScrollInterval > 0 ? HHMakeIndexSection(0, 0) : indexSection;
        } else if (direction == HHPagerScrollDirectionRight) {
            return HHMakeIndexSection(indexSection.index+1, 0);
        }
        
        if (indexSection.index == 0) {
            return _autoScrollInterval > 0 ? HHMakeIndexSection(_numberOfItems - 1, 0) : indexSection;
        }
        return HHMakeIndexSection(indexSection.index-1, 0);
    }
    
    if (direction == HHPagerScrollDirectionRight) {
        if (indexSection.index < _numberOfItems-1) {
            return HHMakeIndexSection(indexSection.index+1, indexSection.section);
        }
        if (indexSection.section >= kPagerViewMaxSectionCount-1) {
            return HHMakeIndexSection(indexSection.index, kPagerViewMaxSectionCount-1);
        }
        return HHMakeIndexSection(0, indexSection.section+1);
    }
    
    if (indexSection.index > 0) {
        return HHMakeIndexSection(indexSection.index-1, indexSection.section);
    }
    if (indexSection.section <= 0) {
        return HHMakeIndexSection(indexSection.index, 0);
    }
    return HHMakeIndexSection(_numberOfItems-1, indexSection.section-1);
}

- (HHIndexSection)caculateIndexSectionWithOffsetX:(CGFloat)offsetX {
    if (_numberOfItems <= 0) {
        return HHMakeIndexSection(0, 0);
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat leftEdge = _isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat middleOffset = offsetX + width/2;
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    NSInteger curIndex = 0;
    NSInteger curSection = 0;
    if (middleOffset - leftEdge >= 0) {
        NSInteger itemIndex = (middleOffset - leftEdge+layout.minimumInteritemSpacing/2)/itemWidth;
        if (itemIndex < 0) {
            itemIndex = 0;
        }else if (itemIndex >= _numberOfItems*kPagerViewMaxSectionCount) {
            itemIndex = _numberOfItems*kPagerViewMaxSectionCount-1;
        }
        curIndex = itemIndex%_numberOfItems;
        curSection = itemIndex/_numberOfItems;
    }
    return HHMakeIndexSection(curIndex, curSection);
}

- (CGFloat)caculateOffsetXAtIndexSection:(HHIndexSection)indexSection{
    if (_numberOfItems == 0) {
        return 0;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    CGFloat leftEdge = _isInfiniteLoop ? _layout.sectionInset.left : _layout.onlyOneSectionInset.left;
    CGFloat width = CGRectGetWidth(_collectionView.frame);
    CGFloat itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing;
    CGFloat offsetX = leftEdge + itemWidth*(indexSection.index + indexSection.section*_numberOfItems) - layout.minimumInteritemSpacing/2 - (width - itemWidth)/2;
    return MAX(offsetX, 0);
}

- (void)resetPagerViewAtIndex:(NSInteger)index {
    if (_didLayout && _firstScrollIndex >= 0) {
        index = _firstScrollIndex;
        _firstScrollIndex = -1;
    }
    if (index < 0) {
        return;
    }
    if (index >= _numberOfItems) {
        index = 0;
    }
    [self scrollToItemAtIndexSection:HHMakeIndexSection(index, _isInfiniteLoop ? kPagerViewMaxSectionCount/3 : 0) animate:NO];
    if (!_isInfiniteLoop && _indexSection.index < 0) {
        [self scrollViewDidScroll:_collectionView];
    }
}

- (void)recyclePagerViewIfNeed {
    if (!_isInfiniteLoop) {
        return;
    }
    if (_indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount || _indexSection.section < kPagerViewMinSectionCount) {
        [self resetPagerViewAtIndex:_indexSection.index];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _isInfiniteLoop ? kPagerViewMaxSectionCount : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _numberOfItems = [_dataSource numberOfItemsInPagerView:self];
    return _numberOfItems;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _dequeueSection = indexPath.section;
    if (_dataSourceFlags.cellForItemAtIndex) {
        return [_dataSource pagerView:self cellForItemAtIndex:indexPath];
    }
    NSAssert(NO, @"pagerView cellForItemAtIndex: is nil!");
    return nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!_isInfiniteLoop) {
        return _layout.onlyOneSectionInset;
    }
    if (section == 0 ) {
        return _layout.firstSectionInset;
    }else if (section == kPagerViewMaxSectionCount -1) {
        return _layout.lastSectionInset;
    }
    return _layout.middleSectionInset;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if ([_delegate respondsToSelector:@selector(pagerView:didSelectedItemCell:atIndex:)]) {
        [_delegate pagerView:self didSelectedItemCell:cell atIndex:indexPath];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!_didLayout) {
        return;
    }
    HHIndexSection newIndexSection =  [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if (_numberOfItems <= 0 || ![self isValidIndexSection:newIndexSection]) {
        NSLog(@"inVlaidIndexSection:(%ld,%ld)!",(long)newIndexSection.index,(long)newIndexSection.section);
        return;
    }
    HHIndexSection indexSection = _indexSection;
    _indexSection = newIndexSection;
    
    if (_delegateFlags.pagerViewDidScroll) {
        [_delegate pagerViewDidScroll:self];
    }
    
    if (_delegateFlags.didScrollFromIndexToNewIndex && !HHEqualIndexSection(_indexSection, indexSection)) {
        //NSLog(@"curIndex %ld",(long)_indexSection.index);
        [_delegate pagerView:self didScrollFromIndex:MAX(indexSection.index, 0) toIndex:_indexSection.index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_autoScrollInterval > 0) {
        [self removeTimer];
    }
    _beginDragIndexSection = [self caculateIndexSectionWithOffsetX:scrollView.contentOffset.x];
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDragging:)]) {
        [_delegate pagerViewWillBeginDragging:self];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (fabs(velocity.x) < 0.35 || !HHEqualIndexSection(_beginDragIndexSection, _indexSection)) {
        targetContentOffset->x = [self caculateOffsetXAtIndexSection:_indexSection];
        return;
    }
    HHPagerScrollDirection direction = HHPagerScrollDirectionRight;
    if ((scrollView.contentOffset.x < 0 && targetContentOffset->x <= 0) || (targetContentOffset->x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width)) {
        direction = HHPagerScrollDirectionLeft;
    }
    HHIndexSection indexSection = [self nearlyIndexPathForIndexSection:_indexSection direction:direction];
    targetContentOffset->x = [self caculateOffsetXAtIndexSection:indexSection];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (_autoScrollInterval > 0) {
        [self addTimer];
    }
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDragging:willDecelerate:)]) {
        [_delegate pagerViewDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([_delegate respondsToSelector:@selector(pagerViewWillBeginDecelerating:)]) {
        [_delegate pagerViewWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndDecelerating:)]) {
        [_delegate pagerViewDidEndDecelerating:self];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self recyclePagerViewIfNeed];
    if ([_delegate respondsToSelector:@selector(pagerViewDidEndScrollingAnimation:)]) {
        [_delegate pagerViewDidEndScrollingAnimation:self];
    }
}

#pragma mark - HHCycBaseLayoutDelegate

- (void)pagerViewTransformLayout:(HHCycBaseLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.initializeTransformAttributes) {
        [_delegate pagerView:self initializeTransformAttributes:attributes];
    }
}

- (void)pagerViewTransformLayout:(HHCycBaseLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    if (_delegateFlags.applyTransformToAttributes) {
        [_delegate pagerView:self applyTransformToAttributes:attributes];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL needUpdateLayout = !CGRectEqualToRect(_collectionView.frame, self.bounds);
    _collectionView.frame = self.bounds;
    if ((_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData)) {
        _didLayout = YES;
        [self setNeedUpdateLayout];
    }
}

- (void)dealloc {
    ((HHCycBaseLayout *)_collectionView.collectionViewLayout).delegate = nil;
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
}


@end


