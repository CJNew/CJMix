//
//  screenPopView.h
//  TiHouse
//
//  Created by Confused小伟 on 2018/1/26.
//  Copyright © 2018年 Confused小伟. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Budgetpro;
@interface PriceSortPopView : UIView

@property (nonatomic ,copy) void(^finishSelectde)(BOOL selectBuy, BOOL selectMoney);
@property (nonatomic, retain) Budgetpro *budgetpro;

-(void)Show;

@end