//
//  STJigsawViewController.h
//  jigsaw
//
//  Created by Song on 14-5-27.
//  Copyright (c) 2014年 song. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STCellView.h"

@interface STJigsawViewController : UIViewController<STCellViewDelegate>

@property (nonatomic, strong) NSMutableArray *grids;
@property (nonatomic, strong) NSMutableArray *slides;
@property (nonatomic, strong) NSMutableArray *allowedFrames;

@end
