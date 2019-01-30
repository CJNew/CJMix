//
//  CloudRecordSearchView.h
//  TiHouse
//
//  Created by 陈晨昕 on 2018/1/30.
//  Copyright © 2018年 Confused小伟. All rights reserved.
//

#import "BaseView.h"
#import "House.h"
#import "CloudRecordSearchVC.h"

@interface CloudRecordSearchView : BaseView
/*
+ (instancetype)shareInstanceWithViewModel:(id<BaseViewModelProtocol>)viewModel withHouse:(House *)house;
*/
@property (nonatomic, strong) RACSubject * cancleBtnSubject;
@property (nonatomic, strong) House *house;
@property (nonatomic, strong) CloudRecordSearchVC *parentVC;

@end