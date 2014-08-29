//
//  STCellView.h
//  jigsaw
//
//  Created by Song on 14-5-29.
//  Copyright (c) 2014年 song. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTKDragConstantTime YES
#define kTKDragConstantSpeed NO
#define SWAP_TO_START_DURATION .24f
#define SWAP_TO_END_DURATION   .24f
#define VELOCITY_PARAMETER 1000.0f

@protocol STCellViewDelegate;

@interface STCellView : UIView<UIGestureRecognizerDelegate>{
@private
    NSInteger currentGoodFrameIndex_;
    NSInteger currentBadFrameIndex_;
    struct {
        unsigned int dragViewDidStartDragging:1;
        unsigned int dragViewDidEndDragging:1;
        unsigned int dragViewDidEnterStartFrame:1;
        unsigned int dragViewDidLeaveStartFrame:1;
        unsigned int dragViewDidEnterGoodFrame:1;
        unsigned int dragViewDidLeaveGoodFrame:1;
        unsigned int dragViewDidEnterBadFrame:1;
        unsigned int dragViewDidLeaveBadFrame:1;
        unsigned int dragViewWillSwapToEndFrame:1;
        unsigned int dragViewDidSwapToEndFrame:1;
        unsigned int dragViewWillSwapToStartFrame:1;
        unsigned int dragViewDidSwapToStartFrame:1;
        unsigned int dragViewCanAnimateToEndFrame:1;
    } delegateFlags_;
}
@property (nonatomic, weak) id<STCellViewDelegate> delegate;
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) NSArray *allowedGrids;
@property (nonatomic) CGRect startPosition;
@property (nonatomic) int initRotate;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) BOOL usedVelocity;
@property (nonatomic) BOOL isAtEndFrame;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isOverEndFrame;
@property (nonatomic) BOOL isOverBadFrame;
@property (nonatomic) BOOL isOverStartFrame;
@property (nonatomic) BOOL isAtStartFrame;
@property (nonatomic) BOOL canDragFromEndPosition;
@property (nonatomic) BOOL canSwapToStartPosition;
@property (nonatomic) BOOL canDragMultipleDragViewsAtOnce;
@property (nonatomic) BOOL canUseSameEndFrameManyTimes;
@property (nonatomic) BOOL shouldStickToEndFrame;
@property (nonatomic) BOOL isAddedToManager;

- (id) initWithImage:(UIImage *)image startPosition:(CGRect) startPosition allowedGrids:(NSArray *)allowedGirds andDelegate:(id<STCellViewDelegate>) delegate;

@end

@protocol STCellViewDelegate <NSObject>
@optional
- (void)dragViewDidStartDragging:(STCellView *)dragView;
- (void)dragViewDidEndDragging:(STCellView *)dragView;
- (void)dragViewDidEnterStartFrame:(STCellView *)dragView;
- (void)dragViewDidLeaveStartFrame:(STCellView *)dragView;
- (void)dragViewDidEnterGoodFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewDidLeaveGoodFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewDidEnterBadFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewDidLeaveBadFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewWillSwapToEndFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewDidSwapToEndFrame:(STCellView *)dragView atIndex:(NSInteger)index;
- (void)dragViewWillSwapToStartFrame:(STCellView *)dragView;
- (void)dragViewDidSwapToStartFrame:(STCellView *)dragView;
- (BOOL)dragView:(STCellView *)dragView canAnimateToEndFrameWithIndex:(NSInteger)index;
@end


@interface TKDragManager : NSObject

+ (TKDragManager *)manager;

- (void)addDragView:(STCellView *)dragView;

- (void)removeDragView:(STCellView *)dragView;

- (BOOL)dragView:(STCellView*)dragView wantSwapToEndFrame:(CGRect)endFrame;

- (BOOL)dragViewCanStartDragging:(STCellView*)dragView;

- (void)dragViewDidEndDragging:(STCellView *)dragView;

- (void)dragView:(STCellView *)dragView didLeaveEndFrame:(CGRect)endFrame;

@end

@interface TKOccupancyIndicator : NSObject

@property CGRect frame;
@property NSInteger count;
@property BOOL isFree;

+ (TKOccupancyIndicator *)indicatorWithFrame:(CGRect)frame;

- (id)initWithFrame:(CGRect)frame;

@end
