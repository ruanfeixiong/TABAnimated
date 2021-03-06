//
//  UICollectionView+Animated.m
//  AnimatedDemo
//
//  Created by tigerAndBull on 2018/10/12.
//  Copyright © 2018年 tigerAndBull. All rights reserved.
//

#import "UICollectionView+Animated.h"
#import "UIView+Animated.h"
#import "UIView+TABControlAnimation.m"
#import "TABViewAnimated.h"

#import "TABAnimatedObject.h"
#import "TABBaseCollectionViewCell.h"

#import "TABAnimated.h"

#import <objc/runtime.h>

@implementation UICollectionView (Animated)

struct {
    unsigned int animatedSectionCountDelegate:1;
} collectionViewAnimatedDelegateRespondTo;

+ (void)load {
    
    // Ensure that the exchange method executed only once.
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // Gets the viewDidLoad method to the class,whose type is a pointer to a objc_method structure.
        Method originMethod = class_getInstanceMethod([self class], @selector(setDelegate:));
        // Get the method you created.
        Method newMethod = class_getInstanceMethod([self class], @selector(tab_setDelegate:));
        
        method_exchangeImplementations(originMethod, newMethod);
    });
}

- (void)tab_setDelegate:(id<UICollectionViewDelegate>)delegate {
    
    SEL oldSectionSelector = @selector(collectionView:numberOfItemsInSection:);
    SEL newSectionSelector = @selector(tab_collectionView:numberOfItemsInSection:);
    
    SEL old = @selector(collectionView:willDisplayCell:forItemAtIndexPath:);
    SEL new = @selector(tab_collectionView:willDisplayCell:forItemAtIndexPath:);
    
    SEL oldCell = @selector(collectionView:cellForItemAtIndexPath:);
    SEL newCell = @selector(tab_collectionView:cellForItemAtIndexPath:);
    
    SEL oldHeightSel = @selector(collectionView:layout:sizeForItemAtIndexPath:);
    SEL newHeightSel = @selector(tab_collectionView:layout:sizeForItemAtIndexPath:);
    
    SEL oldClickSel = @selector(collectionView:didSelectItemAtIndexPath:);
    SEL newClickSel = @selector(tab_collectionView:didSelectItemAtIndexPath:);
    
    if ([self respondsToSelector:newSectionSelector]) {
        [self exchangeCollectionDelegateMethod:oldSectionSelector withNewSel:newSectionSelector withCollectionDelegate:delegate];
        [self exchangeCollectionDelegateMethod:old withNewSel:new withCollectionDelegate:delegate];
        [self exchangeCollectionDelegateMethod:oldCell withNewSel:newCell withCollectionDelegate:delegate];
        [self exchangeCollectionDelegateMethod:oldHeightSel withNewSel:newHeightSel withCollectionDelegate:delegate];
        [self exchangeCollectionDelegateMethod:oldClickSel withNewSel:newClickSel withCollectionDelegate:delegate];
    }

    [self tab_setDelegate:delegate];
}

#pragma mark - TABCollectionViewDelegate

- (NSInteger)tab_collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView.tabAnimated.isAnimating) {
        
        if (collectionView.animatedDelegate &&
            [collectionView.animatedDelegate respondsToSelector:@selector(collectionView:numberOfAnimatedItemsInSection:)]) {
            return [collectionView.animatedDelegate collectionView:collectionView numberOfAnimatedItemsInSection:section];
        }
        
        if (collectionView.tabAnimated.animatedCountArray.count > 0) {
            if (section > collectionView.tabAnimated.animatedCountArray.count - 1) {
                return collectionView.tabAnimated.animatedCount;
            }
            return [collectionView.tabAnimated.animatedCountArray[section] integerValue];
        }
        return collectionView.tabAnimated.animatedCount;
    }
    return [self tab_collectionView:collectionView numberOfItemsInSection:section];
}

- (UICollectionViewCell *)tab_collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([TABViewAnimated sharedAnimated].isUseTemplate) {
        
        if (collectionView.tabAnimated.state == TABViewAnimationStart) {
            
            NSInteger index = indexPath.section;
            if (indexPath.section > (collectionView.tabAnimated.templateClassArray.count - 1)) {
                index = collectionView.tabAnimated.templateClassArray.count - 1;
                tabAnimatedLog(@"TABAnimated模版模式提醒 - section的数量和模版类的数量不一致，超出的section，将使用最后一个模版类加载");
            }
            
            SEL sel = @selector(cellWithIndexPath:atCollectionView:);
            tab_suppressPerformSelectorLeakWarning(
                return [NSClassFromString(collectionView.tabAnimated.templateClassArray[index])
                        performSelector:sel
                        withObject:indexPath
                        withObject:collectionView];
            );
        }
        return [self tab_collectionView:collectionView cellForItemAtIndexPath:indexPath];
    }
    return [self tab_collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (CGSize)tab_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([TABViewAnimated sharedAnimated].isUseTemplate) {
        
        if (collectionView.tabAnimated.state == TABViewAnimationStart) {
            
            NSAssert(collectionView.tabAnimated, @"TABAnimated模版模式强制提醒 - collectionView未注册模版类");
            
            NSInteger index = indexPath.section;
            if (indexPath.section > (collectionView.tabAnimated.templateClassArray.count - 1)) {
                index = collectionView.tabAnimated.templateClassArray.count - 1;
                tabAnimatedLog(@"TABAnimated模版模式提醒 - section的数量和模版类的数量不一致，超出的section，将使用最后一个模版类加载");
            }
            
            SEL sel = @selector(cellSize);
            tab_suppressPerformSelectorLeakWarning(
                NSValue *value = [NSClassFromString(collectionView.tabAnimated.templateClassArray[index]) performSelector:sel];
                if (value.CGSizeValue.height <= 1.0) {
                    NSAssert(NO, @"TABAnimated模版模式提醒 - 请在注册的模版类中设置固定高度，否则没有动画效果");
                }
                return [value CGSizeValue];
            );
        }
        return [self tab_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    }
    return [self tab_collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (void)tab_collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView.tabAnimated.state == TABViewAnimationStart) {
        return;
    }
    [self tab_collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)tab_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tabAnimated.state == TABViewAnimationStart ||
        collectionView.tabAnimated.state == TABViewAnimationRunning) {
        return;
    }
    [self tab_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - Private Methods

- (void)exchangeCollectionDelegateMethod:(SEL)oldSelector
                              withNewSel:(SEL)newSelector
                  withCollectionDelegate:(id<UICollectionViewDelegate>)delegate {
    
    Method oldMethod = class_getInstanceMethod([delegate class], oldSelector);
    Method newMethod = class_getInstanceMethod([self class], newSelector);
    
    if ([self isKindOfClass:[delegate class]]) {
        // 如果你采用了将数据代理给予表格本身，这种愚蠢的做法暂不做处理，将无法使用动画库。
        // method_exchangeImplementations(oldMethod, newMethod);
        NSAssert(NO, @"Why do you do `self.delegate = self` such a silly thing?");
    }else {
        
        if (oldMethod == nil) {
            return;
        }
        
        // 代理对象添加newMethod，指向oldImp
        BOOL isVictory = class_addMethod([delegate class], newSelector, class_getMethodImplementation([delegate class], oldSelector), method_getTypeEncoding(oldMethod));
        if (isVictory) {
            // 添加成功后，将oldMethod指向当前类的新的
            class_replaceMethod([delegate class], oldSelector, class_getMethodImplementation([self class], newSelector), method_getTypeEncoding(newMethod));
        }
    }
}

- (id<UICollectionViewAnimatedDelegate>)animatedDelegate {
    id<UICollectionViewAnimatedDelegate> delegate = objc_getAssociatedObject(self, @selector(animatedDelegate));
    return delegate;
}

- (void)setAnimatedDelegate:(id<UICollectionViewAnimatedDelegate>)animatedDelegate {
    
    if (self.animatedDelegate != animatedDelegate) {
        
        objc_setAssociatedObject(self, @selector(animatedDelegate), animatedDelegate, OBJC_ASSOCIATION_ASSIGN);
        
        collectionViewAnimatedDelegateRespondTo.animatedSectionCountDelegate = [animatedDelegate respondsToSelector:@selector(collectionView:numberOfAnimatedItemsInSection:)];
    }
}

@end
