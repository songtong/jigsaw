//
//  STCellView.m
//  jigsaw
//
//  Created by Song on 14-5-29.
//  Copyright (c) 2014年 song. All rights reserved.
//

#import "STCellView.h"
#import <stdlib.h>

CGRect TKCGRectFromValue(NSValue *value){
    return [value CGRectValue];
}

CGPoint TKCGRectCenter(CGRect rect){
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGFloat TKDistanceBetweenFrames(CGRect rect1, CGRect rect2){
    CGPoint p1 = TKCGRectCenter(rect1);
    CGPoint p2 = TKCGRectCenter(rect2);
    return sqrtf(powf(p1.x - p2.x, 2) + powf(p1.y - p2.y, 2));
}

@interface STCellView ()

- (BOOL)didEnterGoodFrameWithPoint:(CGPoint)point;

- (NSInteger)goodFrameIndexWithPoint:(CGPoint)point;


- (void)panBegan:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)panMoved:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)panEnded:(UIPanGestureRecognizer *)gestureRecognizer;


- (NSTimeInterval)swapToStartAnimationDuration;

- (NSTimeInterval)swapToEndAnimationDurationWithFrame:(CGRect)endFrame;


@end

@implementation STCellView

@synthesize delegate = delegate_;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithImage:(UIImage *)image startPosition:(CGRect)startPosition allowedGrids:(NSArray *)allowedGirds andDelegate:(id<STCellViewDelegate>) delegate
{
    self = [super initWithFrame:startPosition];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.startPosition = startPosition;
    self.allowedGrids = allowedGirds;
    
    [self.imageView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self.imageView setImage:image];
    [self addSubview:self.imageView];
    [self.imageView.layer setMasksToBounds:YES];
    [self.imageView.layer setCornerRadius:5];
    [self.imageView.layer setBorderWidth:0.5];
    [self.imageView.layer setBorderColor:[[UIColor grayColor] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(3, 3)];
    [self.layer setShadowRadius:3];
    [self.layer setShadowOpacity:0.8];
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    
//    self.initRotate = arc4random()%10;
//    CGAffineTransform transform = self.transform;
//    transform = CGAffineTransformRotate(transform, self.initRotate);
//    self.transform = transform;
    
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
    [panGesture setMaximumNumberOfTouches:2];
    [panGesture setDelegate:self];
    panGesture.delaysTouchesEnded = NO;
    
    [self addGestureRecognizer:panGesture];
    
    self.userInteractionEnabled = YES;
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.exclusiveTouch = NO;
    self.multipleTouchEnabled = NO;
    
    self.usedVelocity = kTKDragConstantTime;
    self.isDragging =       NO;
    self.isAnimating =      NO;
    self.isOverEndFrame =   NO;
    self.isAtEndFrame =     NO;
    self.shouldStickToEndFrame = NO;
    self.isAtStartFrame =   YES;
    self.canDragFromEndPosition = YES;
    self.canUseSameEndFrameManyTimes = NO;
    self.canDragMultipleDragViewsAtOnce = YES;
    self.canSwapToStartPosition = YES;
    self.isOverStartFrame = NO;
    self.isAddedToManager = NO;
    
    currentBadFrameIndex_ = currentGoodFrameIndex_ = -1;
    
    self.startLocation = CGPointZero;
    
    [self setDelegate:delegate];

    return self;
}

- (void)setDelegate:(id<STCellViewDelegate>)delegate{
    if (delegate != delegate_) {
        delegate_ = delegate;
        
        delegateFlags_.dragViewDidStartDragging     = [delegate_ respondsToSelector:@selector(dragViewDidStartDragging:)];
        delegateFlags_.dragViewDidEndDragging       = [delegate_ respondsToSelector:@selector(dragViewDidEndDragging:)];
        
        delegateFlags_.dragViewDidEnterStartFrame   = [delegate_ respondsToSelector:@selector(dragViewDidEnterStartFrame:)];
        delegateFlags_.dragViewDidLeaveStartFrame   = [delegate_ respondsToSelector:@selector(dragViewDidLeaveStartFrame:)];
        
        delegateFlags_.dragViewDidEnterGoodFrame    = [delegate_ respondsToSelector:@selector(dragViewDidEnterGoodFrame:atIndex:)];
        delegateFlags_.dragViewDidLeaveGoodFrame    = [delegate_ respondsToSelector:@selector(dragViewDidLeaveGoodFrame:atIndex:)];
        
        delegateFlags_.dragViewDidEnterBadFrame     = [delegate_ respondsToSelector:@selector(dragViewDidEnterBadFrame:atIndex:)];
        delegateFlags_.dragViewDidLeaveBadFrame     = [delegate_ respondsToSelector:@selector(dragViewDidLeaveBadFrame:atIndex:)];
        
        delegateFlags_.dragViewWillSwapToEndFrame = [delegate_ respondsToSelector:@selector(dragViewWillSwapToEndFrame:atIndex:)];
        delegateFlags_.dragViewDidSwapToEndFrame    = [delegate_ respondsToSelector:@selector(dragViewDidSwapToEndFrame:atIndex:)];
        
        delegateFlags_.dragViewWillSwapToStartFrame = [delegate_ respondsToSelector:@selector(dragViewWillSwapToStartFrame:)];
        delegateFlags_.dragViewDidSwapToStartFrame  = [delegate_ respondsToSelector:@selector(dragViewDidSwapToStartFrame:)];
        
        delegateFlags_.dragViewCanAnimateToEndFrame = [delegate_ respondsToSelector:@selector(dragView:canAnimateToEndFrameWithIndex:)];
    }
}


- (void)panDetected:(UIPanGestureRecognizer*)gestureRecognizer{
    switch ([gestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            [self panBegan:gestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self panMoved:gestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
            [self panEnded:gestureRecognizer];
            break;
        default:
            break;
    }
}

- (NSValue *)getAllowedRectFromIndex: (NSInteger) index{
    int row = (int)index / 4 ;
    int col = (int)index - row  * 4;
    return self.allowedGrids[row][col];
}

- (void)panBegan:(UIPanGestureRecognizer*)gestureRecognizer{
	if (!self.isDragging && !self.isAnimating) {
        self.isDragging = YES;
        self.startLocation = [gestureRecognizer locationInView:self];
        [[self superview] bringSubviewToFront:self];
        if (delegateFlags_.dragViewDidStartDragging) {
            [delegate_ dragViewDidStartDragging:self];
        }
    }
}

- (void)panMoved:(UIPanGestureRecognizer*)gestureRecognizer{
    if(!self.isDragging)
        return;
    
    CGPoint pt = [gestureRecognizer locationInView:self];
    CGPoint translation = [gestureRecognizer translationInView:[self superview]];
    [self setCenter:CGPointMake([self center].x + translation.x, [self center].y + translation.y)];
    [gestureRecognizer setTranslation:CGPointZero inView:[self superview]];
    
    // 判断拖拽点是否有grid
    NSInteger goodFrameIndex = [self goodFrameIndexWithPoint:pt];
    
    // 进入拖拽点所在的grid
    if (goodFrameIndex >= 0 && !self.isOverEndFrame) {
        if (delegateFlags_.dragViewDidEnterGoodFrame) {
            [delegate_ dragViewDidEnterGoodFrame:self atIndex:goodFrameIndex];
        }
        currentGoodFrameIndex_ = goodFrameIndex;
        self.isOverEndFrame = YES;
    }
    
    // 离开grid
    if (self.isOverEndFrame && goodFrameIndex < 0) {
        if (delegateFlags_.dragViewDidLeaveGoodFrame) {
            [delegate_ dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
        }
        
        if(!self.canUseSameEndFrameManyTimes){
            CGRect goodFrame = TKCGRectFromValue([self getAllowedRectFromIndex:currentGoodFrameIndex_]);
            [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
        }
        
        currentGoodFrameIndex_ = -1;
        self.isOverEndFrame = NO;
        self.isAtEndFrame = NO;
    }
    
    // 进入另一个grid
    if (self.isOverEndFrame && goodFrameIndex != currentGoodFrameIndex_) {
        
        if (delegateFlags_.dragViewDidLeaveGoodFrame) {
            [delegate_ dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
            
        }
        
        if (!self.canUseSameEndFrameManyTimes && self.isAtEndFrame) {
            CGRect rect = TKCGRectFromValue([self getAllowedRectFromIndex:currentGoodFrameIndex_]);
            [[TKDragManager manager] dragView:self didLeaveEndFrame:rect];
        }
        
        if (delegateFlags_.dragViewDidEnterGoodFrame) {
            [delegate_ dragViewDidEnterGoodFrame:self atIndex:goodFrameIndex];
        }
        
        currentGoodFrameIndex_ = goodFrameIndex;
        self.isAtEndFrame = NO;
    }
}

- (void)panEnded:(UIPanGestureRecognizer*)gestureRecognizer{
    if (!self.isDragging)
        return;
    
    self.isDragging = NO;

    if (delegateFlags_.dragViewDidEndDragging) {
        [delegate_ dragViewDidEndDragging:self];
    }
    
    if (delegateFlags_.dragViewCanAnimateToEndFrame){
        if (![delegate_ dragView:self canAnimateToEndFrameWithIndex:currentGoodFrameIndex_]){
            [self swapToStartPosition];
            return;
        }
    }

    if (self.isAtEndFrame && !self.shouldStickToEndFrame) {
        if(!self.canUseSameEndFrameManyTimes) {
            CGRect goodFrame = TKCGRectFromValue([self getAllowedRectFromIndex:currentGoodFrameIndex_]);
            [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
        }
        
        if(delegateFlags_.dragViewDidLeaveGoodFrame)
            [delegate_ dragViewDidLeaveGoodFrame:self atIndex:currentGoodFrameIndex_];
        
        [self swapToStartPosition];
    }
    else{
        if (self.isOverStartFrame && self.canSwapToStartPosition) {
            [self swapToStartPosition];
        }
        else{
            if (currentGoodFrameIndex_ >= 0) {
                [self swapToEndPositionAtIndex:currentGoodFrameIndex_];
            }
            else{
                if (self.isOverEndFrame && !self.canUseSameEndFrameManyTimes) {
                    CGRect goodFrame = TKCGRectFromValue([self getAllowedRectFromIndex:currentGoodFrameIndex_]);
                    [[TKDragManager manager] dragView:self didLeaveEndFrame:goodFrame];
                }
                
                [self swapToStartPosition];
            }
        }
    }
    
    self.startLocation = CGPointZero;
}

#pragma mark - Private

- (BOOL)didEnterGoodFrameWithPoint:(CGPoint)point {
    
    if ([self goodFrameIndexWithPoint:point] >= 0) {
        return YES;
    }
    else{
        return NO;
    }
}

//返回拖拽点所在的grid序号
- (NSInteger)goodFrameIndexWithPoint:(CGPoint)point{
    CGPoint touchInSuperview = [self convertPoint:point toView:[self superview]];
    NSInteger index = -1;
    
    for (int row = 0; row < [self.allowedGrids count]; row ++){
        for (int col = 0; col < [self.allowedGrids[row] count]; col++){
            CGRect allow = [self.allowedGrids[row][col] CGRectValue];
            if(CGRectContainsPoint(allow, touchInSuperview)){
                index = row * 4 + col;
            }
        }
    }
    
    return index;
}

- (NSTimeInterval)swapToStartAnimationDuration{
    if (self.usedVelocity == kTKDragConstantTime) {
        return SWAP_TO_START_DURATION;
    }
    else{
        return TKDistanceBetweenFrames(self.frame, self.startPosition)/VELOCITY_PARAMETER;
    }
    
}

- (NSTimeInterval)swapToEndAnimationDurationWithFrame:(CGRect)endFrame{
    if (self.usedVelocity == kTKDragConstantTime) {
        return SWAP_TO_END_DURATION;
    }
    else{
        return TKDistanceBetweenFrames(self.frame, endFrame)/VELOCITY_PARAMETER;
    }
}

#pragma mark - Public

- (void)swapToStartPosition{
    self.isAnimating = YES;
    if (delegateFlags_.dragViewWillSwapToStartFrame)
        [delegate_ dragViewWillSwapToStartFrame:self];
    
    [UIView animateWithDuration:[self swapToStartAnimationDuration] delay:0. options:UIViewAnimationOptionCurveEaseIn animations:^{self.frame = self.startPosition;} completion:^(BOOL finished) {
        if (finished) {
            if (delegateFlags_.dragViewDidSwapToStartFrame){
                [delegate_ dragViewDidSwapToStartFrame:self];
            }
            self.isAnimating = NO;
            self.isAtStartFrame = YES;
            self.isAtEndFrame = NO;
        }
    }];
}

- (void)swapToEndPositionAtIndex:(NSInteger)index{
    
    if (![self.allowedGrids count]) return;
    
    CGRect endFrame = [[self getAllowedRectFromIndex:index] CGRectValue];
    
    if (!self.isAtEndFrame) {
        if (!self.canUseSameEndFrameManyTimes) {
            if(![[TKDragManager manager] dragView:self wantSwapToEndFrame:endFrame]){
                if(delegateFlags_.dragViewDidLeaveGoodFrame){
                    [delegate_ dragViewDidLeaveGoodFrame:self atIndex:index];
                }
                return;
            }
        }
    }
    
    self.isAnimating = YES;
    
    if (delegateFlags_.dragViewWillSwapToEndFrame){
        [delegate_ dragViewWillSwapToEndFrame:self atIndex:index];
    }
    
    [UIView animateWithDuration:[self swapToEndAnimationDurationWithFrame:endFrame]
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.frame = endFrame;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             if (delegateFlags_.dragViewDidSwapToEndFrame)
                                 [delegate_ dragViewDidSwapToEndFrame:self atIndex:index];
                             
                             self.isAnimating = NO;
                             self.isAtEndFrame = YES;
                             self.isAtStartFrame = NO;
                         }
                     }];
}

@end

#pragma mark - TKDragManager

@interface TKDragManager ()

@property (nonatomic, strong) NSMutableArray *managerArray;

@property (nonatomic, unsafe_unretained) STCellView *currentDragView;

@end


@implementation TKDragManager

@synthesize currentDragView = currentDragView_;

@synthesize managerArray = managerArray_;

static TKDragManager *manager; // it's a singleton, but how to relase it under ARC?

+ (TKDragManager *)manager{
    if (!manager) {
        manager = [[TKDragManager alloc] init];
    }
    
    return manager;
}

- (id)init{
    self = [super init];
    
    if(!self) return nil;
    
    self.managerArray = [NSMutableArray arrayWithCapacity:0];
    self.currentDragView = nil;
    
    
    return self;
}

- (void)addDragView:(STCellView *)dragView{
    
    NSMutableArray *framesToAdd = [NSMutableArray arrayWithCapacity:0];
    
    if ([self.managerArray count]) {
        
        for (NSValue *dragViewValue in dragView.allowedGrids) {
            CGRect dragViewRect = TKCGRectFromValue(dragViewValue);
            BOOL isInTheArray = NO;
            
            for (TKOccupancyIndicator *ind in self.managerArray) {
                CGRect managerRect = ind.frame;
                
                if (CGRectEqualToRect(managerRect, dragViewRect)) {
                    ind.count++;
                    isInTheArray = YES;
                    break;
                }
            }
            
            if (!isInTheArray) {
                [framesToAdd addObject:dragViewValue];
            }
            
        }
        
    }
    else{
        [framesToAdd addObjectsFromArray:dragView.allowedGrids];
    }
    
    
    for (int i = 0;i < [framesToAdd count]; i++) {
        
        CGRect frame = TKCGRectFromValue([framesToAdd objectAtIndex:i]);
        
        TKOccupancyIndicator *ind = [TKOccupancyIndicator indicatorWithFrame:frame];
        
        [self.managerArray addObject:ind];
    }
}

- (void)removeDragView:(STCellView *)dragView{
    NSMutableArray *arrayToRemove = [NSMutableArray arrayWithCapacity:0];
    
    for (TKOccupancyIndicator *ind in self.managerArray) {
        
        CGRect rect = ind.frame;
        
        for (NSValue *value in dragView.allowedGrids) {
            
            CGRect endFrame = TKCGRectFromValue(value);
            
            if (CGRectEqualToRect(rect, endFrame)) {
                ind.count--;
                
                if (ind.count == 0) {
                    [arrayToRemove addObject:ind];
                }
            }
            
        }
        
    }
    
    [self.managerArray removeObjectsInArray:arrayToRemove];
    
}

- (BOOL)dragView:(STCellView*)dragView wantSwapToEndFrame:(CGRect)endFrame{
    
    
    for (TKOccupancyIndicator *ind in self.managerArray) {
        CGRect frame = ind.frame;
        BOOL isTaken = !ind.isFree;
        if (CGRectEqualToRect(endFrame, frame)) {
            if (isTaken) {
                [dragView swapToStartPosition];
                return NO;
            }
            else{
                ind.isFree = NO;
                return YES;
            }
        }
    }
    
    return YES;
}

- (void)dragView:(STCellView *)dragView didLeaveEndFrame:(CGRect)endFrame{
    for (TKOccupancyIndicator *ind in self.managerArray) {
        CGRect frame = ind.frame;
        
        if (CGRectEqualToRect(frame, endFrame) && dragView.isAtEndFrame) {
            ind.isFree = YES;
        }
    }
}

- (BOOL)dragViewCanStartDragging:(STCellView*)dragView{
    if (!self.currentDragView) {
        self.currentDragView = dragView;
        return YES;
    }
    else{
        return NO;
    }
}

- (void)dragViewDidEndDragging:(STCellView *)dragView{
    if (self.currentDragView == dragView)
        self.currentDragView = nil;
}

@end

#pragma mark - TKOccupancyIndicator

@implementation TKOccupancyIndicator

@synthesize frame = frame_;
@synthesize count = count_;
@synthesize isFree = isFree_;

- (id)initWithFrame:(CGRect)frame{
    self = [super init];
    if(!self) return nil;
    
    self.frame = frame;
    self.isFree = YES;
    self.count = 1;
    
    return self;
    
}

+ (TKOccupancyIndicator *)indicatorWithFrame:(CGRect)frame{
    return [[TKOccupancyIndicator alloc] initWithFrame:frame];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"TKOccupancyIndicator: frame: %@, count: %ld, isFree: %@",
            NSStringFromCGRect(self.frame), self.count, self.isFree ? @"YES" : @"NO"];
}

@end

