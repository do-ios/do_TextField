//
//  TYPEID_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_TextField_IView.h"
#import "do_TextField_UIModel.h"
#import "doIUIModuleView.h"

@interface do_TextField_UIView : UITextField<do_TextField_IView,doIUIModuleView,UITextFieldDelegate>
//可根据具体实现替换UIView
{
@private
    __weak do_TextField_UIModel *_model;
}
@property (nonatomic, assign) int maxLength;

@end