//
//  BudgetDetailsTableViewCell.h
//  TiHouse
//
//  Created by Confused小伟 on 2018/1/26.
//  Copyright © 2018年 Confused小伟. All rights reserved.
//

#import "CommonTableViewCell.h"
#import "Logbudgetope.h"
@interface BudgetLookTransformCell : CommonTableViewCell

@property (nonatomic, retain) Logbudgetope *logbudgetope;
@property (nonatomic, assign) BOOL lineShow;

@end