//
//  TYPEID_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_TextField_UIView.h"

#import "doIPage.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doTextHelper.h"
#import "doDefines.h"
#import "doJsonHelper.h"
#import "doIScrollView.h"
#import "doIOHelper.h"
#import "doServiceContainer.h"
#import "doLogEngine.h"
#define FONT_OBLIQUITY 15.0
#define ANIMATION_DURATION .3

static NSString *didBeginEdit = @"DODidBeginEditNotification";
static NSString *keyboardShow = @"DOKeyboardShowNotification";
static NSString *keyboardHide = @"DOKeyboardHideNotification";
static BOOL shouldFireFocusInOutEvent = true;
static dispatch_once_t onceToken;
//不可修改否则borderview不能接收

@class do_TextField_UIView;

@interface DelegateClass : NSObject<UITextFieldDelegate>
@property(nonatomic, weak)doUIModule *model;
@end


@interface do_TextField_UIView()
@property (nonatomic,strong) DelegateClass *delegateClass;
@property (nonatomic, assign) CGFloat leftRightPadding;
@property (nonatomic, assign) CGFloat topBottomPadding;

@property (nonatomic, strong) NSMutableDictionary *attributeDict;
@property (nonatomic, strong) UIFont *currentFont;
@property (nonatomic, strong) UIColor *currentTextColor;
@property (nonatomic, strong) NSString *myFontStyle;
@property (nonatomic, strong) NSString *myFontFlag;
@property (nonatomic, assign) int intFontSize;



- (void)removeObserver;
- (void)registerForKeyboardNotifications;
@end


@implementation DelegateClass
#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self fireEvent:@"enter"];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    do_TextField_UIView *doTextField = (do_TextField_UIView *)textField;
    [doTextField registerForKeyboardNotifications];
    return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //source 原来的文本
    //newtxt 改变后的文本
    do_TextField_UIView *t = (do_TextField_UIView *)textField;
    NSString *newtxt = string;
    NSString *sourceText = textField.text;
    
    textField.clearsOnBeginEditing = NO;
    if (t.maxLength >=0) {//只有maxlength是正数，才需要限制输入
        if (t.maxLength < sourceText.length || t.maxLength < newtxt.length) {//如果原来的文本比maxlength更长，则只允许删除
            if (sourceText.length < newtxt.length) {
                return NO;
            }
        }
     }
    

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (!shouldFireFocusInOutEvent)return;
    [self fireEvent:@"focusIn"];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (!shouldFireFocusInOutEvent)return;
    [self fireEvent:@"focusOut"];
    do_TextField_UIView *doTextField = (do_TextField_UIView *)textField;
    [doTextField removeObserver];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:keyboardHide object:doTextField];
}

-(void) fireEvent:(NSString*) _event
{
    doInvokeResult* _result = [[doInvokeResult alloc] init:_model.UniqueKey];
    [_model.EventCenter FireEvent:_event :_result ];
}

@end

@implementation do_TextField_UIView
{
    doInvokeResult *_invokeResult;
    
    NSString *_hintColor;

    NSString *_clearImg;
    
    BOOL _isClearAll;
    
}
@synthesize maxLength,delegateClass = _delegateClass;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _delegateClass = [[DelegateClass alloc] init];
    //为了解决iOS7.0环境下，delegate = self，cpu使用接近100%的问题。iOS7.1之后的版本无问题
    _delegateClass.model = _model;
    self.delegate =_delegateClass;

    self.backgroundColor = [UIColor clearColor];
    
    self.borderStyle = UITextBorderStyleLine;
    self.borderStyle = UITextBorderStyleNone;
    
    _myFontStyle = @"normal";
    _myFontFlag = @"normal";
    _currentFont = [UIFont systemFontOfSize:[doUIModuleHelper GetDeviceFontSize:17 :_model.XZoom :_model.YZoom]];
    
    [self change_fontColor:[_model GetProperty:@"fontColor"].DefaultValue];
    [self change_hint:[_model GetProperty:@"hint"].DefaultValue];
    [self change_inputType:[_model GetProperty:@"inputType"].DefaultValue];
    [self change_password:[_model GetProperty:@"password"].DefaultValue];
    [self change_clearAll:[_model GetProperty:@"clearAll"].DefaultValue];
    [self change_fontSize:[_model GetProperty:@"fontSize"].DefaultValue];
    [self change_maxLength:[_model GetProperty:@"maxLength"].DefaultValue];
    [self change_enabled:[_model GetProperty:@"enabled"].DefaultValue];
    [self change_cursorColor:[_model GetProperty:@"cursorColor"].DefaultValue];

    self.spellCheckingType = UITextSpellCheckingTypeNo;
    self.autocorrectionType = UITextAutocorrectionTypeNo;
    self.returnKeyType=UIReturnKeyDefault;
    
    self.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    _hintColor = [_model GetProperty:@"hintColor"].DefaultValue;
    
    _isClearAll = NO;
    _leftRightPadding = 2.0;
    _topBottomPadding = 1.0;
    
    _attributeDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      _currentFont,NSFontAttributeName,
                      _currentTextColor,NSForegroundColorAttributeName,
                      @(NSUnderlineStyleNone),NSUnderlineStyleAttributeName,nil];
}

//销毁所有的全局对象
- (void) OnDispose
{
    _model = nil;
    _myFontStyle = nil;
    _myFontFlag = nil;
    _invokeResult = nil;
    self.rightView = nil;
    _delegateClass = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];

    [self setClearImg];
}
#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */

- (void)change_enterText:(NSString *)newValue
{
    if ([newValue isEqualToString:@"go"]) {
        self.returnKeyType = UIReturnKeyGo;
    }
    else if ([newValue isEqualToString:@"send"])
    {
        self.returnKeyType = UIReturnKeySend;
    }
    else if ([newValue isEqualToString:@"next"])
    {
        self.returnKeyType = UIReturnKeyNext;
    }
    else if ([newValue isEqualToString:@"done"])
    {
        self.returnKeyType= UIReturnKeyDone;
    }
    else if ([newValue isEqualToString:@"search"])
    {
        self.returnKeyType=UIReturnKeySearch;
    }
    else//default
    {
        self.returnKeyType=UIReturnKeyDefault;
    }

}
- (void)change_enabled:(NSString *)newValue
{
    self.userInteractionEnabled = [newValue boolValue];
    self.enabled = [newValue boolValue];
}
- (void)change_text:(NSString *)newValue{
    UITextRange *range = self.selectedTextRange;
    NSInteger number = [newValue length];
    NSString *txt = newValue;
    BOOL _isBeyond = NO;
    if (maxLength>=0) {
        if (number > maxLength) {
            _isBeyond = YES;
            txt = [txt substringToIndex:maxLength];
        }
    }
    if (!self.markedTextRange) {
        [_model SetPropertyValue:@"text" :txt];
        if (!_isBeyond) {
            [self fireEvent];
        }
        if (_myFontFlag)
            [self change_textFlag:_myFontFlag];
        if(_myFontStyle)
            [self change_fontStyle:_myFontStyle];
        else
            [self setText:txt];
    }
    self.selectedTextRange = range;
}
- (void)change_fontColor:(NSString *)newValue{
    _currentTextColor = [doUIModuleHelper GetColorFromString:newValue :[UIColor blackColor]];
    [_attributeDict setObject:_currentTextColor forKey:NSForegroundColorAttributeName];

    [self setTextColor:[doUIModuleHelper GetColorFromString:newValue :[UIColor blackColor]]];
}
- (void)change_fontSize:(NSString *)newValue{
    UIFont * font = [UIFont systemFontOfSize:[newValue intValue]];
    _intFontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[newValue intValue]] :_model.XZoom :_model.YZoom];
    _currentFont = [font fontWithSize:_intFontSize];
    self.font = [font fontWithSize:_intFontSize];
    if (_myFontFlag)
        [self change_textFlag:_myFontFlag];
    if(_myFontStyle)
        [self change_fontStyle:_myFontStyle];
}
- (void)change_fontStyle:(NSString *)newValue
{
    //自己的代码实现
    _myFontStyle = [NSString stringWithFormat:@"%@",newValue];
    if (self.text==nil || [self.text isEqualToString:@""]) return;
    UIFont *font;
    if([newValue isEqualToString:@"normal"]) {
        [_attributeDict setObject:@0 forKey:NSObliquenessAttributeName];

        font = [UIFont systemFontOfSize:_intFontSize];
        
    }
    else if([newValue isEqualToString:@"bold"]) {
        [_attributeDict setObject:@0 forKey:NSObliquenessAttributeName];
        font = [UIFont boldSystemFontOfSize:_intFontSize];
    }
    else if([newValue isEqualToString:@"italic"])
    {
        [_attributeDict setObject:@0.33 forKey:NSObliquenessAttributeName];
        
        font = [UIFont systemFontOfSize:_intFontSize];
    }
    else if([newValue isEqualToString:@"bold_italic"]){
        [_attributeDict setObject:@0.33 forKey:NSObliquenessAttributeName];
        font = [UIFont boldSystemFontOfSize:_intFontSize];
    }
    [_attributeDict setObject:font forKey:NSFontAttributeName];
    _currentFont = font;
    self.attributedText = [[NSMutableAttributedString alloc] initWithString:self.text attributes:_attributeDict];
}
- (void)change_textFlag:(NSString *)newValue
{
    //自己的代码实现
    _myFontFlag = [NSString stringWithFormat:@"%@",newValue];
    NSString *currentText = [_model GetPropertyValue:@"text"];
    if (!IOS_8 && _intFontSize < 18) {
        [self setText:currentText];
        return;
    }
    if (!currentText || currentText.length == 0) {
        self.attributedText = [[NSAttributedString alloc] initWithString:@""];
        return;
    }
    
    if ([_myFontFlag isEqualToString:@"normal"]) {
        _attributeDict[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleNone);
        _attributeDict[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleNone);
        
    }else if ([_myFontFlag isEqualToString:@"underline"]) {
        _attributeDict[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
        
    }else if ([_myFontFlag isEqualToString:@"strikethrough"]) {
        [_attributeDict setObject:@(NSUnderlineStyleSingle) forKey:NSStrikethroughStyleAttributeName];
    }
    
    // 设置字体
    [_attributeDict setObject:_currentFont forKey:NSFontAttributeName];
    // 字体颜色
    [_attributeDict setObject:_currentTextColor forKey:NSForegroundColorAttributeName];
    
    self.attributedText = [[NSMutableAttributedString alloc] initWithString:currentText attributes:_attributeDict];
}

- (void)change_hint:(NSString *)newValue
{
    if (!newValue || newValue.length == 0) {
        return;
    }
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:newValue];
    [self setAttributedPlaceholder:string];
    [self change_hintColor:_hintColor];
}
- (void)change_hintColor:(NSString *)newValue
{
    _hintColor = newValue;
    if (!newValue || newValue.length == 0 || !self.attributedPlaceholder || self.attributedPlaceholder.length == 0) {
        return;
    }
    NSString *defaultColor = [_model GetProperty:@"hintColor"].DefaultValue;
    UIColor *dColor = [doUIModuleHelper GetColorFromString:defaultColor :[UIColor blueColor]];
    UIColor *hintColor = [doUIModuleHelper GetColorFromString:newValue :dColor];
    
    NSMutableDictionary *attribute = [NSMutableDictionary dictionary];
    [attribute setObject:[UIFont systemFontOfSize:_currentFont.pointSize] forKey:NSFontAttributeName];
    [attribute setObject:hintColor forKey:NSForegroundColorAttributeName];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:self.placeholder attributes:attribute];
    [self setAttributedPlaceholder:string];
}
- (void)change_inputType:(NSString *)newValue{
    if ([newValue isEqualToString:@"ASC"]) {
        self.keyboardType = UIKeyboardTypeDefault;
    }else if([newValue isEqualToString:@"PHONENUMBER"]){
        self.keyboardType = UIKeyboardTypePhonePad;
    }else if([newValue isEqualToString:@"URL"]){
        self.keyboardType = UIKeyboardTypeURL;
    }else if ([newValue isEqualToString:@"ENG"]) {
        self.keyboardType = UIKeyboardTypeASCIICapable;
    }else if ([newValue isEqualToString:@"DECIMAL"]) {
        self.keyboardType = UIKeyboardTypeDecimalPad;
    }else{
        self.keyboardType = UIKeyboardTypeDefault;
    }
}
- (void)change_password:(NSString *)newValue{
    self.secureTextEntry = [newValue boolValue];
    if(self.text.length <= 0)return;
    [self change_text:[_model GetPropertyValue:@"text"]];
}
- (void)change_clearAll:(NSString *)newValue{
    _isClearAll = [newValue boolValue];
    if([newValue isEqualToString:@"true"] || [newValue isEqualToString:@"1"])
    {
        self.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    else
    {
        self.clearButtonMode = UITextFieldViewModeNever;
    }
}
- (void)change_maxLength:(NSString *)newValue
{
    maxLength = [[doTextHelper Instance] StrToInt:newValue :100];
    NSString *str = self.text;
    if(maxLength < str.length)
        self.attributedText = [self.attributedText attributedSubstringFromRange:NSMakeRange(0, str.length)];
}
- (void)change_textAlign:(NSString *)newValue
{
    if ([newValue isEqualToString:@"right"]) {
        self.textAlignment = NSTextAlignmentRight;
    }
    else if ([newValue isEqualToString:@"center"])
    {
        self.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        self.textAlignment = NSTextAlignmentLeft;
    }
}
- (void)change_cursorColor:(NSString *)newValue
{
    self.tintColor = [doUIModuleHelper GetColorFromString:newValue : [UIColor clearColor]];
}
- (void)change_clearImg:(NSString *)newValue
{
    _clearImg = newValue;
    if (CGRectGetHeight(self.frame)>0 && CGRectGetWidth(self.frame)>0) {
        [self setClearImg];
    }
}
- (void)setClearImg
{
    if (!_clearImg || _clearImg.length == 0) {
        self.rightView = nil;
        self.rightViewMode=UITextFieldViewModeNever;
    }else{
        if (!_isClearAll) {
            return;
        }
        //验证图片文件是否存在
        NSString *imgPath = [doIOHelper GetLocalFileFullPath:_model.CurrentPage.CurrentApp :_clearImg];
        UIImage *img = [UIImage imageWithContentsOfFile:imgPath];
        if (!img) {
            self.rightView = nil;
            self.clearButtonMode=UITextFieldViewModeWhileEditing;//默认的清楚图标
            return;
        }
        self.rightView = [self clearView:img];
        self.rightViewMode=UITextFieldViewModeWhileEditing;
    }
}
- (UIButton *)clearView:(UIImage *)img
{
    UIButton *right = [UIButton buttonWithType:UIButtonTypeCustom];
    [right setBackgroundColor:[UIColor clearColor]];
    right.userInteractionEnabled = YES;

    right.frame = CGRectMake(0, 0, img.size.width  * _model.XZoom , img.size.height * _model.YZoom);
    [right setBackgroundImage:img forState:UIControlStateNormal];

    [right addTarget:self action:@selector(clearContent) forControlEvents:UIControlEventTouchUpInside];

    return right;
}
- (void)clearContent
{
    if (self.text.length==0||!self.text) {
        return;
    }
    [self change_text:@""];
}

- (void)setFocus:(NSArray *)params
{
    NSDictionary *dic = [params objectAtIndex:0];
    BOOL value = [doJsonHelper GetOneBoolean:dic :@"value" :NO];
    if (value) {
        [self becomeFirstResponder];
    }else
        [self resignFirstResponder];
}
- (void)setSelection:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //自己的代码实现
    NSString *startStr = [doJsonHelper GetOneText:_dictParas :@"position" :@""];
    [self Help_moveCursorWithDirection:UITextLayoutDirectionLeft offset:(self.text.length -[startStr integerValue])];
}
- (void)Help_moveCursorWithDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    UITextPosition* endPosition = self.endOfDocument;
    UITextPosition* start = [self positionFromPosition:endPosition inDirection:direction offset:offset];
    if (start)
    {
        [self setSelectedTextRange:[self textRangeFromPosition:start toPosition:start]];
    }
}
// 0,0,0,0 上右下左
- (void)change_padding:(NSString *)newValue {
    if (![newValue containsString:@","]) {
        [[doServiceContainer Instance].LogEngine WriteDebug:@"参数格式错误"];
        return;
    }
    NSArray *paramArr = [newValue componentsSeparatedByString:@","];
    if (paramArr.count != 4){
        [[doServiceContainer Instance].LogEngine WriteDebug:@"参数格式错误"];
        return;
    }else {
        float topPadding = [paramArr[0] floatValue];
        float rightPadding = [paramArr[1] floatValue];
        float bottomPadding = [paramArr[2] floatValue];
        float leftPadding = [paramArr[3] floatValue];
        
        if (topPadding*2 >= _model.Height*_model.YZoom || bottomPadding*2 >= _model.Height*_model.YZoom) {
            [[doServiceContainer Instance].LogEngine WriteDebug:@"参数大小错误"];
            return;
        }
        
        if (rightPadding > 50 || leftPadding > 50) {
            [[doServiceContainer Instance].LogEngine WriteDebug:@"参数大小错误"];
            return;
        }
    
        if (topPadding > 0) {
            self.topBottomPadding = topPadding;
        }else {
            if (bottomPadding > 0) {
                self.topBottomPadding = bottomPadding;
            }else {
                self.topBottomPadding = 1.0;
            }
        }
        
        if (rightPadding > 0) {
            self.leftRightPadding = rightPadding;
        }else {
            if (leftPadding > 0) {
                self.leftRightPadding = leftPadding;
            }else {
                self.leftRightPadding = 2.0;
            }
        }
    }
}

#pragma mark -
#pragma mark keyBoardchangeView
//visible=false，取消编辑状态
- (void)setHidden:(BOOL)_hidden
{
    [super setHidden:_hidden];
    [self resignFirstResponder];
}

- (void) registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    
}
- (void) keyboardWasShown:(NSNotification *) notif
{
    NSDictionary *info = [notif userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:keyboardShow object:self userInfo:info];
}
- (void)keyboardDidBeginEditing:(NSNotification *) notif
{
    NSDictionary *info = [notif userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:didBeginEdit object:self userInfo:info];
}

- (void)textFieldChanged:(id)sender
{
    [self change_text:self.text];
    if ([self.text isEqualToString:@""]) {
        
        dispatch_once(&onceToken, ^{ // 为了解决默认有文本第一聚焦删除文本内容，placeHolder和光标下移问题
            shouldFireFocusInOutEvent = false;
            [self resignFirstResponder];
            [self becomeFirstResponder];
            shouldFireFocusInOutEvent = true;
        });
        [self change_hint:self.placeholder];
    }
}
- (NSString *)textInRange:(UITextRange *)range
{
    NSString *txt = [super textInRange:range];
    if (maxLength<0) {
        return txt;
    }
    NSInteger number = [self.text length];
    if (number > maxLength) {
        return nil;
    }
    return txt;
}
- (void)fireEvent
{
    //change事件
    if (!_invokeResult) {
        _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    }
    [_model.EventCenter FireEvent:@"textChanged":_invokeResult];
}

#pragma  mark - 私有方法

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    NSString *key = @"text";
    if ([_changedValues.allKeys containsObject:key]) {
        NSString *txt = [_changedValues objectForKey:key];
        NSInteger number = txt.length;
        if (maxLength>=0) {
            if (number > maxLength) {
                txt = [txt substringToIndex:maxLength];
                [_changedValues setObject:txt forKey:key];
            }
        }
    }
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResults
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResults];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

#pragma mark - UITextField change padding of text / editing text
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds ,self.leftRightPadding ,self.topBottomPadding);
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectInset(bounds ,self.leftRightPadding ,self.topBottomPadding);
}
@end
