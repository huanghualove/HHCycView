//
//  HHCycBaseLayout.h
//  HHCycViewTest
//
//  Created by 黄华 on 2018/4/12.
//  Copyright © 2018年 huanghua. All rights reserved.
//

#import <UIKit/UIKit.h>

//cell ——> 样式
typedef NS_ENUM(NSUInteger ,HHCycLayoutType){
    HHCycleLayoutNormal,
    HHCycleLayoutLinear,
    HHCycleLayoutCoverflow,
};



@class HHCycBaseLayout;
//代理对象
@protocol HHCycBaseLayoutDelegate <NSObject>

- (void)pagerViewTransformLayout:(HHCycBaseLayout *)pagerViewTransformLayout initializeTransformAttributes:(UICollectionViewLayoutAttributes *)attributes;

- (void)pagerViewTransformLayout:(HHCycBaseLayout *)pagerViewTransformLayout applyTransformToAttributes:(UICollectionViewLayoutAttributes *)attributes;

@end





//布局对象
@interface HHCycViewLayout : NSObject

@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) UIEdgeInsets sectionInset;

@property (nonatomic, assign) HHCycLayoutType layoutType;

@property (nonatomic, assign) CGFloat minimumScale; // sacle default 0.8
@property (nonatomic, assign) CGFloat minimumAlpha; // alpha default 1.0
@property (nonatomic, assign) CGFloat maximumAngle; // angle is % default 0.2

@property (nonatomic, assign) BOOL isInfiniteLoop;  // infinte scroll
@property (nonatomic, assign) CGFloat rateOfChange; // scale and angle change rate
@property (nonatomic, assign) BOOL adjustSpacingWhenScroling;
@property (nonatomic, assign) BOOL itemVerticalCenter;
@property (nonatomic, assign) BOOL itemHorizontalCenter;


@property (nonatomic, assign, readonly) UIEdgeInsets onlyOneSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets firstSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets lastSectionInset;
@property (nonatomic, assign, readonly) UIEdgeInsets middleSectionInset;

@end






@interface HHCycBaseLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) HHCycViewLayout *layout;
@property (nonatomic, weak)   id<HHCycBaseLayoutDelegate> delegate;

@end



