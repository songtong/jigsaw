//
//  STJigsawViewController.m
//  jigsaw
//
//  Created by Song on 14-5-27.
//  Copyright (c) 2014年 song. All rights reserved.
//

#import "STJigsawViewController.h"
#import "STCellView.h"
#import <stdlib.h>

#define random(min,max) ((arc4random() % (max-min+1)) + min)

@interface STJigsawViewController (){
    int totalRow;
    int totalCol;
    UIImage * originImage;
}

@end

@implementation STJigsawViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        totalRow = 5;
        totalCol = 4;
        self.grids = [[NSMutableArray alloc] initWithCapacity:totalRow];
        self.slides = [[NSMutableArray alloc] initWithCapacity:totalRow];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"panda.jpg" ofType:nil];
        originImage = [UIImage imageWithContentsOfFile:path];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIImageView * backgroundImageView = (UIImageView *)self.view.subviews[0];
    [backgroundImageView setImage:originImage];
    CGRect startPostion = backgroundImageView.frame;

    self.allowedFrames = [NSMutableArray arrayWithCapacity:totalRow];
    
    for (int row = 0; row < totalRow; row ++) {
        [self.grids addObject:[[NSMutableArray alloc] initWithCapacity:totalCol]];
        [self.allowedFrames addObject:[NSMutableArray arrayWithCapacity:totalCol]];
        for (int col = 0; col < totalCol; col ++) {
            CGRect gridRect = CGRectMake(startPostion.origin.x +  col * 80, startPostion.origin.y + row * 80, 80, 80);
            
            UIView * grid = [[UIView alloc] initWithFrame:gridRect];
            grid.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor;
            grid.layer.borderWidth = 2.0f;
            
            [self.view addSubview:grid];
            [self.grids[row] addObject:grid];
            [self.allowedFrames[row] addObject:[NSValue valueWithCGRect:gridRect]];
        }
    }
    
    for (int row = 0; row < totalRow; row ++){
        [self.slides addObject:[[NSMutableArray alloc] initWithCapacity:totalCol]];
        for (int col = 0; col < totalCol; col ++) {
            
            UIImage * slideImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(originImage.CGImage, CGRectMake(col * 160, row * 160, 160, 160))];
            STCellView * cell = [[STCellView alloc] initWithImage:slideImage startPosition:[self randomPosition] allowedGrids:self.allowedFrames andDelegate:self];
            
            [self.view addSubview:cell];
            [self.slides[row] addObject:cell];
        }
    }
    
}

- (CGRect)randomPosition
{
    int x = arc4random() % 250;
    int y = 0;
    int topOrBottom = arc4random() % 2;
    if (topOrBottom == 0){
        y = random(0, 50);
    }else{
        y = random(460, 510);
    }
    return CGRectMake(x, y, 60, 60);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dragViewDidStartDragging:(STCellView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
}

- (void)dragViewDidEndDragging:(STCellView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}


- (void)dragViewDidEnterStartFrame:(STCellView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 0.5;
    }];
}

- (void)dragViewDidLeaveStartFrame:(STCellView *)dragView{
    
    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 1.0;
    }];
}

- (UIView *)getAllowedRectFromIndex: (NSInteger) index{
    int row = (int)index / 4 ;
    int col = (int)index - row  * 4;
    return self.grids[row][col];
}

- (void)dragViewDidEnterGoodFrame:(STCellView *)dragView atIndex:(NSInteger)index{
    
    UIView *view = [self getAllowedRectFromIndex:index];
    
    if (view) view.layer.borderWidth = 4.0f;
    
    
}

- (void)dragViewDidLeaveGoodFrame:(STCellView *)dragView atIndex:(NSInteger)index{
    UIView *view = [self getAllowedRectFromIndex:index];
    
    if (view) view.layer.borderWidth = 1.0f;
}

- (void)dragViewWillSwapToEndFrame:(STCellView *)dragView atIndex:(NSInteger)index{
    
    
    
}

- (void)dragViewDidSwapToEndFrame:(STCellView *)dragView atIndex:(NSInteger)index{
    
    
    [UIView animateWithDuration:0.2
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
//                         dragView.transform = CGAffineTransformMakeRotation(M_PI);
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}


- (void)dragViewWillSwapToStartFrame:(STCellView *)dragView{
    [UIView animateWithDuration:0.2 animations:^{
        dragView.alpha = 1.0f;
    }];
}

- (void)dragViewDidSwapToStartFrame:(STCellView *)dragView{
    
}


@end
