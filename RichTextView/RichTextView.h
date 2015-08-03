//
//  RichTextView.h
//  RichTextView
//
//  Created by levy on 15/8/3.
//  Copyright (c) 2015年 levy. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class RichTextView;
@class RichTextBaseRun;

#pragma mark -- RichTextView
@protocol RichTextViewDelegate<NSObject>
- (void)richTextView:(RichTextView *)view touchBeginRun:(RichTextBaseRun *)run;
- (void)richTextView:(RichTextView *)view touchEndRun:(RichTextBaseRun *)run;

@end

@interface RichTextView : UIView
@property(nonatomic,copy)   NSString           *text;            // default is @""
@property(nonatomic,strong) UIFont             *font;            // default is [UIFont systemFontOfSize:12.0]
@property(nonatomic,strong) UIColor            *textColor;       // default is [UIColor blackColor]
@property(nonatomic)        float               lineSpacing;     // default is 1.5 行间距

//-- 特殊的文本数组。在绘制的时候绘制
@property(nonatomic,readonly)       NSMutableArray *richTextRunsArray;
//-- 特熟文本的绘图边界字典。用来做点击处理定位
@property(nonatomic,readonly)       NSMutableDictionary *richTextRunRectDic;
//-- 原文本通过解析后的文本
@property(nonatomic,readonly,copy)  NSString        *textAnalyzed;

@property(nonatomic,weak) id<RichTextViewDelegate> delegage;
-(CGSize)draw;

@end

#pragma mark -- RichTextBaseRun

typedef enum richTextRunType
{
    //-- URL文本单元类型
    richTextURLRunType,
    //-- 表情文本单元类型
    richTextEmojiRunType,
    
}RichTextRunType;

@interface RichTextBaseRun : NSObject

//-- 文本单元类型
@property (nonatomic) RichTextRunType type;

//-- 原始文本
@property (nonatomic,copy) NSString *originalText;

//-- 原始字体
@property (nonatomic,strong) UIFont *originalFont;

//-- 文本所在位置
@property (nonatomic) NSRange range;

//-- 是否响应触摸
@property (nonatomic) BOOL isResponseTouch;

//-- 替换基本文本样式
- (void)replaceTextWithAttributedString:(NSMutableAttributedString*) attributedString;

//-- 绘制内容 (YES 表示这个函数自己绘制，NO表示CoreText绘制)
- (BOOL)drawRunWithRect:(CGRect)rect;

@end

#pragma mark -- RichTextImageRun

@interface RichTextImageRun : RichTextBaseRun

@end

#pragma mark -- RichTextURLRun

@interface RichTextURLRun : RichTextBaseRun

+ (NSString *)analyzeText:(NSString *)string runsArray:(NSMutableArray **)array;

@end

#pragma mark -- RichTextEmojiRun

@interface RichTextEmojiRun : RichTextImageRun

+ (NSString *)analyzeText:(NSString *)string runsArray:(NSMutableArray **)runArray;

@end






