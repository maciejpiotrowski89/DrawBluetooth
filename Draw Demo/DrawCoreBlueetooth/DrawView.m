//
//  DrawView.m
//  DrawCoreBlueetooth
//
//  Created by Maciej Piotrowski on 04/10/14.
//  Copyright (c) 2014 Maciej Piotrowski All rights reserved.
//

#import "DrawView.h"

@interface DrawView()

@property (nonatomic, weak) UIBezierPath *currentPath;
@property (nonatomic, strong) NSMutableArray *bezierPaths;

@end

@implementation DrawView

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    _bezierPaths = [NSMutableArray new];
    self.backgroundColor = [UIColor blackColor];
}

- (UIBezierPath *)setupNewPath {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 6.0f;
    return path;
}

- (void)drawPoint:(CGPoint)point {
    if (CGPointEqualToPoint(CGPointZero, point)) {
        [self endDrawingPoints];
        return;
    }
    
    if (nil == self.currentPath) {
        UIBezierPath *path = [self setupNewPath];
        [self.bezierPaths addObject:path];
        self.currentPath = path;
        [self.currentPath moveToPoint:point];
    } else {
        [self.currentPath addLineToPoint:point];
    }
    [self setNeedsDisplay];
}

- (void)endDrawingPoints {
    self.currentPath = nil;
}

- (void)clearDrawnPoints {
    [self endDrawingPoints];
    [self.bezierPaths removeAllObjects];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [[UIColor colorWithRed:51/255.0 green:232/255.0 blue:41/255.0 alpha:255/255.0]setStroke];
    for (UIBezierPath *path in self.bezierPaths) {
        [path stroke];
    }
}

@end
