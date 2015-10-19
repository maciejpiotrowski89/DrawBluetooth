//
//  DrawView.h
//  DrawCoreBlueetooth
//
//  Created by Maciej Piotrowski on 04/10/14.
//  Copyright (c) 2014 Maciej Piotrowski All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawView : UIView

- (void)drawPoint:(CGPoint)point;
- (void)endDrawingPoints;
- (void)clearDrawnPoints;

@end
