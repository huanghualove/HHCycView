//
//  HHCycBaseLayout.m
//  HHCycViewTest
//
//  Created by 黄华 on 2018/4/12.
//  Copyright © 2018年 huanghua. All rights reserved.
//

#import "HHCycBaseLayout.h"

typedef NS_ENUM(NSUInteger , HHCycLayoutItemDirection){
    HHCycLayoutItemLeft,
    HHCycLayoutItemCenter,
    HHCycLayoutItemRight,
};


#pragma mark   ---   布局对象

@interface HHCycViewLayout ()

@property (nonatomic, weak) UIView *pageView;

@end


@implementation HHCycViewLayout

- (instancetype)init{
    if (self == [super init]) {
        _itemVerticalCenter = YES;
        _minimumScale = 0.8;
        _minimumAlpha = 1.0;
        _maximumAngle = 0.2;
        _rateOfChange = 0.4;
        _adjustSpacingWhenScroling = YES;
    }
    return self;
}

- (UIEdgeInsets)onlyOneSectionInset {
    CGFloat leftSpace = _pageView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.left;
    CGFloat rightSpace = _pageView && !_isInfiniteLoop && _itemHorizontalCenter ? (CGRectGetWidth(_pageView.frame) - _itemSize.width)/2 : _sectionInset.right;
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, leftSpace, verticalSpace, rightSpace);
    }
    return UIEdgeInsetsMake(_sectionInset.top, leftSpace, _sectionInset.bottom, rightSpace);
}
- (UIEdgeInsets)firstSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, _sectionInset.left, verticalSpace, _itemSpacing);
    }
    return UIEdgeInsetsMake(_sectionInset.top, _sectionInset.left, _sectionInset.bottom, _itemSpacing);
}
- (UIEdgeInsets)lastSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _sectionInset.right);
    }
    return UIEdgeInsetsMake(_sectionInset.top, 0, _sectionInset.bottom, _sectionInset.right);
}
- (UIEdgeInsets)middleSectionInset {
    if (_itemVerticalCenter) {
        CGFloat verticalSpace = (CGRectGetHeight(_pageView.frame) - _itemSize.height)/2;
        return UIEdgeInsetsMake(verticalSpace, 0, verticalSpace, _itemSpacing);
    }
    return _sectionInset;
}
@end












#pragma mark   ---  BaseLayout

@interface HHCycBaseLayout ()
{
    struct {
        unsigned int applyTransformToAttributes    :1;
        unsigned int initializeTransformAttributes :1;
    }_delegateFlags;
}
@property (nonatomic, assign) BOOL applyTransformToAttributesDelegate;

@end



@implementation HHCycBaseLayout

- (instancetype)init{
    if (self == [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self == [super initWithCoder:aDecoder]) {
       self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return self;
}


- (void)setDelegate:(id<HHCycBaseLayoutDelegate>)delegate{
    
    _delegate = delegate;
    
    if (delegate)
    {
        _delegateFlags.initializeTransformAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:initializeTransformAttributes:)];
        
        _delegateFlags.applyTransformToAttributes = [delegate respondsToSelector:@selector(pagerViewTransformLayout:applyTransformToAttributes:)];
    }
}


- (void)setLayout:(HHCycViewLayout *)layout{

    _layout = layout;
    _layout.pageView = self.collectionView;
    self.itemSize = _layout.itemSize;
    self.minimumLineSpacing = _layout.itemSpacing;
    self.minimumInteritemSpacing = _layout.itemSpacing;
}

- (CGSize)itemSize{
    if (!_layout) {
        return [super itemSize];
    }
    return _layout.itemSize;
}

- (CGFloat)minimumLineSpacing {
    if (!_layout) {
        return [super minimumLineSpacing];
    }
    return _layout.itemSpacing;
}

- (CGFloat)minimumInteritemSpacing {
    if (!_layout) {
        return [super minimumInteritemSpacing];
    }
    return _layout.itemSpacing;
}


#pragma mark   ---   layout
/*!
 *  多次调用 只要滑出范围就会 调用
 *  当CollectionView的显示范围发生改变的时候，是否重新发生布局
 *  一旦重新刷新 布局，就会重新调用
 *  1.layoutAttributesForElementsInRect：方法
 *  2.preparelayout方法
 */
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    
    return _layout.layoutType == HHCycleLayoutNormal ? [super shouldInvalidateLayoutForBoundsChange:newBounds] : YES;
}


/**
 *  这个方法的返回值是一个数组(数组里存放在rect范围内所有元素的布局属性)
 *  这个方法的返回值  决定了rect范围内所有元素的排布（frame）
 */
//数组中 -> 布局可见对象
- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    
   //如果不是正常大小 cell 则需要计算
    if (_delegateFlags.applyTransformToAttributes || _layout.layoutType != HHCycleLayoutNormal ) {
    
        NSArray *attributesArr = [[NSArray alloc] initWithArray:[super layoutAttributesForElementsInRect:rect] copyItems:YES];
        
        CGRect visibleRect = {self.collectionView.contentOffset,self.collectionView.bounds.size};
        
        for (UICollectionViewLayoutAttributes *attributes in attributesArr) {
            
            if (!CGRectIntersectsRect(visibleRect, attributes.frame)){
                continue;
            }
            
            if (_delegateFlags.applyTransformToAttributes) {
                
                [_delegate pagerViewTransformLayout:self applyTransformToAttributes:attributes];
                
            }else {
                
                [self applyTransformToAttributes:attributes layoutType:_layout.layoutType];
            }
        }
        return attributesArr;
    }
    
    return [super layoutAttributesForElementsInRect:rect];
}



- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    if (_delegateFlags.initializeTransformAttributes) {
        
        [_delegate pagerViewTransformLayout:self initializeTransformAttributes:attributes];
        
    }else if(_layout.layoutType != HHCycleLayoutNormal){
        
        [self initializeTransformAttributes:attributes layoutType:_layout.layoutType];
    }
    return attributes;
}



#pragma mark   -  根据cell排版类型计算
- (void)applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(HHCycLayoutType)layoutType {
    switch (layoutType) {
        case HHCycleLayoutLinear:
            [self applyLinearTransformToAttributes:attributes];
            break;
        case HHCycleLayoutCoverflow:
            [self applyCoverflowTransformToAttributes:attributes];
            break;
        default:
            break;
    }
}

- (void)initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes layoutType:(HHCycLayoutType)layoutType {
    switch (layoutType) {
        case HHCycleLayoutLinear:
            [self applyLinearTransformToAttributes:attributes scale:_layout.minimumScale alpha:_layout.minimumAlpha];
            break;
        case HHCycleLayoutCoverflow:
        {
            [self applyCoverflowTransformToAttributes:attributes angle:_layout.maximumAngle alpha:_layout.minimumAlpha];
            break;
        }
        default:
            break;
    }
}




#pragma mark - 计算cell
- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {return;}
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth/2;
    CGFloat delta = ABS(attributes.center.x - centetX);
    CGFloat scale = MAX(1 - delta/collectionViewWidth*_layout.rateOfChange, _layout.minimumScale);
    CGFloat alpha = MAX(1 - delta/collectionViewWidth, _layout.minimumAlpha);
    [self applyLinearTransformToAttributes:attributes scale:scale alpha:alpha];
}

- (void)applyLinearTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes scale:(CGFloat)scale alpha:(CGFloat)alpha{
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    if (_layout.adjustSpacingWhenScroling) {
        HHCycLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
        CGFloat translate = 0;
        switch (direction) {
            case HHCycLayoutItemLeft:
                translate = 1.15 * attributes.size.width*(1-scale)/2;
                break;
            case HHCycLayoutItemRight:
                translate = -1.15 * attributes.size.width*(1-scale)/2;
                break;
            default:
                // center
                scale = 1.0;
                alpha = 1.0;
                break;
        }
        transform = CGAffineTransformTranslate(transform,translate, 0);
    }
    attributes.transform = transform;
    attributes.alpha = alpha;
}


- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes {
    CGFloat collectionViewWidth = self.collectionView.frame.size.width;
    if (collectionViewWidth <= 0) {return;}
    CGFloat centetX = self.collectionView.contentOffset.x + collectionViewWidth/2;
    CGFloat delta = ABS(attributes.center.x - centetX);
    CGFloat angle = MIN(delta/collectionViewWidth*(1-_layout.rateOfChange), _layout.maximumAngle);
    CGFloat alpha = MAX(1 - delta/collectionViewWidth, _layout.minimumAlpha);
    [self applyCoverflowTransformToAttributes:attributes angle:angle alpha:alpha];
}

- (void)applyCoverflowTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes angle:(CGFloat)angle alpha:(CGFloat)alpha{
    HHCycLayoutItemDirection direction = [self directionWithCenterX:attributes.center.x];
    CATransform3D transform3D = CATransform3DIdentity;
    transform3D.m34 = -0.002;
    CGFloat translate = 0;
    switch (direction) {
        case HHCycLayoutItemLeft:
            translate = (1-cos(angle*1.2*M_PI))*attributes.size.width;
            break;
        case HHCycLayoutItemRight:
            translate = -(1-cos(angle*1.2*M_PI))*attributes.size.width;
            angle = -angle;
            break;
        default:
            // center
            angle = 0;
            alpha = 1;
            break;
    }
    transform3D = CATransform3DRotate(transform3D, M_PI*angle, 0, 1, 0);
    if (_layout.adjustSpacingWhenScroling) {
        transform3D = CATransform3DTranslate(transform3D, translate, 0, 0);
    }
    attributes.transform3D = transform3D;
    attributes.alpha = alpha;

}


- (HHCycLayoutItemDirection)directionWithCenterX:(CGFloat)centerX {
    HHCycLayoutItemDirection direction= HHCycLayoutItemRight;
    CGFloat contentCenterX = self.collectionView.contentOffset.x + CGRectGetWidth(self.collectionView.frame)/2;
    if (ABS(centerX - contentCenterX) < 0.5) {
        direction = HHCycLayoutItemCenter;
    }else if (centerX - contentCenterX < 0) {
        direction = HHCycLayoutItemLeft;
    }
    return direction;
}


@end






