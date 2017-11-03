//
//  do_TextField_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_TextField_IView <NSObject>

@required
//属性方法
- (void)change_clearAll:(NSString *)newValue;
- (void)change_enabled:(NSString *)newValue;
- (void)change_fontColor:(NSString *)newValue;
- (void)change_fontSize:(NSString *)newValue;
- (void)change_fontStyle:(NSString *)newValue;
- (void)change_hint:(NSString *)newValue;
- (void)change_inputType:(NSString *)newValue;
- (void)change_maxLength:(NSString *)newValue;
- (void)change_password:(NSString *)newValue;
- (void)change_text:(NSString *)newValue;
- (void)change_textFlag:(NSString *)newValue;
- (void)change_enterText:(NSString *)newValue;
- (void)change_textAlign:(NSString *)newValue;
- (void)change_clearImg:(NSString *)newValue;
- (void)change_padding:(NSString *)newValue;

//同步或异步方法
- (void)setFocus:(NSArray *)parms;


@end
