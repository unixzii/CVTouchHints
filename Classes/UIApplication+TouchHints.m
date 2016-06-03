//
//  UIApplication+TouchHints.m
//  CocoaTouchPlayground
//
//  Created by 杨弘宇 on 16/6/3.
//  Copyright © 2016年 Cyandev. All rights reserved.
//

#import <objc/runtime.h>
#import "UIApplication+TouchHints.h"

static const char kOverlayWindowKey;
static const char kHintsImageKey;
static const char kTouchesDictKey;

@implementation UIApplication (TouchHints)

+ (void)_swizzleMethodWithSelector:(SEL)aSelector andSelector:(SEL)anotherSelector {
    Class cls = [self class];
    
    Method oriMethod = class_getInstanceMethod(cls, aSelector);
    Method newMethod = class_getInstanceMethod(cls, anotherSelector);
    
    BOOL didAddMethod = class_addMethod(cls, aSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (didAddMethod) {
        class_replaceMethod(cls, anotherSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    }
    else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

+ (void)load {
    [super load];
    
    [self _swizzleMethodWithSelector:@selector(sendEvent:) andSelector:@selector(tch_sendEvent:)];
}

- (NSString *)_stringFromPointer:(id)pointer {
    return [NSString stringWithFormat:@"%ld", (long) pointer];
}

- (UIWindow *)_overlayWindow {
    id overlayWindow = objc_getAssociatedObject(self, &kOverlayWindowKey);
    
    if ([overlayWindow isKindOfClass:[UIWindow class]]) {
        return overlayWindow;
    }
    
    return nil;
}

- (UIImage *)_hintsImage {
    id hintsImage = objc_getAssociatedObject(self, &kHintsImageKey);
    
    if ([hintsImage isKindOfClass:[UIImage class]]) {
        return hintsImage;
    }
    
    return nil;
}

- (NSMutableDictionary *)_touchesDict {
    id touchesDict = objc_getAssociatedObject(self, &kTouchesDictKey);
    
    if ([touchesDict isKindOfClass:[NSMutableDictionary class]]) {
        return touchesDict;
    }
    
    return nil;
}

- (CGRect)_frameForTouch:(UITouch *)touch {
    CGPoint loc = [touch locationInView:[self _overlayWindow]];
    return CGRectMake(loc.x - 32, loc.y - 32, 64, 64);
}

- (void)_createAndShowTouch:(UITouch *)touch {
    CALayer *layer = [CALayer layer];
    layer.frame = [self _frameForTouch:touch];
    layer.contents = (id) [self _hintsImage].CGImage;
    
    [[self _touchesDict] setObject:layer forKey:[self _stringFromPointer:touch]];
    [[self _overlayWindow].rootViewController.view.layer addSublayer:layer];
}

- (void)_moveTouch:(UITouch *)touch {
    CALayer *layer = [[self _touchesDict] objectForKey:[self _stringFromPointer:touch]];
    
    if (!layer) {
        return;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    layer.frame = layer.frame = [self _frameForTouch:touch];
    [CATransaction commit];
}

- (void)_hideAndReleaseTouch:(UITouch *)touch {
    NSString *pointerString = [self _stringFromPointer:touch];
    CALayer *layer = [[self _touchesDict] objectForKey:pointerString];
    
    if (!layer) {
        return;
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.4];
    layer.opacity = 0;
    layer.transform = CATransform3DMakeScale(0.92, 0.92, 1);
    [CATransaction commit];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(400 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [[self _touchesDict] removeObjectForKey:pointerString];
        [layer removeFromSuperlayer];
    });
}

- (void)_clearInvalidTouches:(NSSet<UITouch *> *)liveTouches {
    NSMutableDictionary *dict = [self _touchesDict];
    NSMutableArray *liveTouchStrings = [NSMutableArray array];
    [liveTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull obj, BOOL * _Nonnull stop) {
        [liveTouchStrings addObject:[self _stringFromPointer:obj]];
    }];
    
    NSArray<NSString *> *touchKeys = dict.allKeys;
    [touchKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![liveTouchStrings containsObject:obj]) {
            [self _hideAndReleaseTouch:(id) obj];
        }
    }];
    
    NSArray<CALayer *> *touchLayers = dict.allValues;
    [[[self _overlayWindow].rootViewController.view.layer.sublayers copy] enumerateObjectsUsingBlock:^(CALayer * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![touchLayers containsObject:obj]) {
            [obj removeFromSuperlayer];
        }
    }];
}

- (void)tch_enableTouchHintsWithImage:(UIImage *)image {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        objc_setAssociatedObject(self, &kHintsImageKey, image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        NSMutableDictionary *touches = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &kTouchesDictKey, touches, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        UIWindow *overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.userInteractionEnabled = NO;
        objc_setAssociatedObject(self, &kOverlayWindowKey, overlayWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.userInteractionEnabled = NO;
        
        overlayWindow.rootViewController = viewController;
        [overlayWindow makeKeyAndVisible];
    });
}

- (void)tch_sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches) {
        [event.allTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.phase == UITouchPhaseBegan) {
                [self _createAndShowTouch:obj];
            }
            else if (obj.phase == UITouchPhaseMoved || obj.phase == UITouchPhaseStationary) {
                [self _moveTouch:obj];
            }
            else if (obj.phase == UITouchPhaseEnded || obj.phase == UITouchPhaseCancelled) {
                [self _hideAndReleaseTouch:obj];
            }
            [self _clearInvalidTouches:event.allTouches];
        }];
    }
    
    [self tch_sendEvent:event];
}

@end
