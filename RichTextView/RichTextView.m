//
//  RichTextView.m
//  RichTextView
//
//  Created by levy on 15/8/3.
//  Copyright (c) 2015年 levy. All rights reserved.
//

#import "RichTextView.h"

@implementation RichTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _text = @"";
        _font = [UIFont systemFontOfSize:12.0];
        _textColor = [UIColor blackColor];
        _lineSpacing = 1.5;
        //
        _richTextRunsArray = [[NSMutableArray alloc] init];
        _richTextRunRectDic = [[NSMutableDictionary alloc] init];
        //_textAnalyzed = [self analyzeText:_text];
    }
    return self;
}

#pragma mark - Draw Rect
- (void)drawRect:(CGRect)rect
{
    //解析文本
    _textAnalyzed = [self analyzeText:_text];
    //要绘制的文本
    NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithString:self.textAnalyzed];
    
    //设置字体
    CTFontRef aFont = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [attString addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)aFont range:NSMakeRange(0,attString.length)];
    CFRelease(aFont);
    
    //设置颜色
    [attString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0,attString.length)];
    
    //文本处理
    for (RichTextBaseRun *textRun in self.richTextRunsArray)
    {
        [textRun replaceTextWithAttributedString:attString];
    }
    
    //绘图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //修正坐标系
    CGAffineTransform textTran = CGAffineTransformIdentity;
    textTran = CGAffineTransformMakeTranslation(0.0, self.bounds.size.height);
    textTran = CGAffineTransformScale(textTran, 1.0, -1.0);
    CGContextConcatCTM(context, textTran);
    
    //绘制
    int lineCount = 0;
    CFRange lineRange = CFRangeMake(0,0);
    CTTypesetterRef typeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
    float drawLineX = 0;
    float drawLineY = self.bounds.origin.y + self.bounds.size.height - self.font.ascender;
    BOOL drawFlag = YES;
    [self.richTextRunRectDic removeAllObjects];
    
    while(drawFlag)
    {
        CFIndex testLineLength = CTTypesetterSuggestLineBreak(typeSetter,lineRange.location,self.bounds.size.width);
    check:  lineRange = CFRangeMake(lineRange.location,testLineLength);
        CTLineRef line = CTTypesetterCreateLine(typeSetter,lineRange);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        
        //边界检查
        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1);
        CGFloat lastRunAscent;
        CGFloat laseRunDescent;
        CGFloat lastRunWidth  = CTRunGetTypographicBounds(lastRun, CFRangeMake(0,0), &lastRunAscent, &laseRunDescent, NULL);
        CGFloat lastRunPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(lastRun).location, NULL);
        
        if ((lastRunWidth + lastRunPointX) > self.bounds.size.width)
        {
            testLineLength--;
            CFRelease(line);
            goto check;
        }
        
        //绘制普通行元素
        drawLineX = CTLineGetPenOffsetForFlush(line,0,self.bounds.size.width);
        CGContextSetTextPosition(context,drawLineX,drawLineY);
        CTLineDraw(line,context);
        
        //绘制替换过的特殊文本单元
        for (int i = 0; i < CFArrayGetCount(runs); i++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, i);
            NSDictionary* attributes = (__bridge NSDictionary*)CTRunGetAttributes(run);
            RichTextBaseRun *textRun = [attributes objectForKey:@"RichTextAttribute"];
            if (textRun)
            {
                CGFloat runAscent,runDescent;
                CGFloat runWidth  = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
                CGFloat runHeight = runAscent + (-runDescent);
                CGFloat runPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                CGFloat runPointY = drawLineY - (-runDescent);
                
                CGRect runRect = CGRectMake(runPointX, runPointY, runWidth, runHeight);
                
                BOOL isDraw = [textRun drawRunWithRect:runRect];
                
                if (textRun.isResponseTouch)
                {
                    if (isDraw)
                    {
                        [self.richTextRunRectDic setObject:textRun forKey:[NSValue valueWithCGRect:runRect]];
                    }
                    else
                    {
                        runRect = CTRunGetImageBounds(run, context, CFRangeMake(0, 0));
                        runRect.origin.x = runPointX;
                        [self.richTextRunRectDic setObject:textRun forKey:[NSValue valueWithCGRect:runRect]];
                    }
                }
                
            }
        }
        
        CFRelease(line);
        
        if(lineRange.location + lineRange.length >= attString.length)
        {
            drawFlag = NO;
        }
        
        lineCount++;
        drawLineY -= self.font.ascender + (- self.font.descender) + self.lineSpacing;
        lineRange.location += lineRange.length;
    }
    CFRelease(typeSetter);
}
-(CGSize )draw
{
    CGFloat maxWidth = 0;
    //解析文本
    _textAnalyzed = [self analyzeText:_text];
    
    //要绘制的文本
    NSMutableAttributedString* attString = [[NSMutableAttributedString alloc] initWithString:self.textAnalyzed];
    
    //设置字体
    CTFontRef aFont = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    [attString addAttribute:(NSString*)kCTFontAttributeName value:(__bridge id)aFont range:NSMakeRange(0,attString.length)];
    CFRelease(aFont);
    
    //设置颜色
    [attString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)self.textColor.CGColor range:NSMakeRange(0,attString.length)];
    
    //文本处理
    for (RichTextBaseRun *textRun in self.richTextRunsArray)
    {
        [textRun replaceTextWithAttributedString:attString];
    }
    
    //绘图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //修正坐标系
    CGAffineTransform textTran = CGAffineTransformIdentity;
    textTran = CGAffineTransformMakeTranslation(0.0, self.bounds.size.height);
    textTran = CGAffineTransformScale(textTran, 1.0, -1.0);
    // CGContextConcatCTM(context, textTran);
    
    //绘制
    int lineCount = 0;
    CFRange lineRange = CFRangeMake(0,0);
    CTTypesetterRef typeSetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attString);
    float drawLineX = 0;
    float drawLineY = self.bounds.origin.y + self.bounds.size.height - self.font.ascender;
    BOOL drawFlag = YES;
    [self.richTextRunRectDic removeAllObjects];
    
    while(drawFlag)
    {
        CFIndex testLineLength = CTTypesetterSuggestLineBreak(typeSetter,lineRange.location,self.bounds.size.width);
    check:  lineRange = CFRangeMake(lineRange.location,testLineLength);
        CTLineRef line = CTTypesetterCreateLine(typeSetter,lineRange);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        
        //边界检查
        CTRunRef lastRun = CFArrayGetValueAtIndex(runs, CFArrayGetCount(runs) - 1);
        CGFloat lastRunAscent;
        CGFloat laseRunDescent;
        CGFloat lastRunWidth  = CTRunGetTypographicBounds(lastRun, CFRangeMake(0,0), &lastRunAscent, &laseRunDescent, NULL);
        CGFloat lastRunPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(lastRun).location, NULL);
        maxWidth = maxWidth > (lastRunWidth + lastRunPointX)?maxWidth:(lastRunWidth + lastRunPointX);
        if ((lastRunWidth + lastRunPointX) > self.bounds.size.width)
        {
            testLineLength--;
            CFRelease(line);
            goto check;
        }
        //绘制普通行元素
        drawLineX = CTLineGetPenOffsetForFlush(line,0,self.bounds.size.width);
        //  CGContextSetTextPosition(context,drawLineX,drawLineY);
        //   CTLineDraw(line,context);
        
        //绘制替换过的特殊文本单元
        for (int i = 0; i < CFArrayGetCount(runs); i++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, i);
            NSDictionary* attributes = (__bridge NSDictionary*)CTRunGetAttributes(run);
            RichTextBaseRun *textRun = [attributes objectForKey:@"RichTextAttribute"];
            if (textRun)
            {
                CGFloat runAscent,runDescent;
                CGFloat runWidth  = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
                CGFloat runHeight = runAscent + (-runDescent);
                CGFloat runPointX = drawLineX + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                CGFloat runPointY = drawLineY - (-runDescent);
                
                CGRect runRect = CGRectMake(runPointX, runPointY, runWidth, runHeight);
                
                BOOL isDraw = [textRun isKindOfClass:[RichTextEmojiRun class]] ? YES : NO;
                //[textRun drawRunWithRect:runRect];
                
                if (textRun.isResponseTouch)
                {
                    if (isDraw)
                    {
                        [self.richTextRunRectDic setObject:textRun forKey:[NSValue valueWithCGRect:runRect]];
                    }
                    else
                    {
                        runRect = CTRunGetImageBounds(run, context, CFRangeMake(0, 0));
                        runRect.origin.x = runPointX;
                        [self.richTextRunRectDic setObject:textRun forKey:[NSValue valueWithCGRect:runRect]];
                    }
                }
                
            }
        }
        
        CFRelease(line);
        
        if(lineRange.location + lineRange.length >= attString.length)
        {
            drawFlag = NO;
        }
        
        lineCount++;
        drawLineY -= self.font.ascender + (- self.font.descender) + self.lineSpacing;
        lineRange.location += lineRange.length;
    }
    CFRelease(typeSetter);
    
    // NSLog(@"%f  maxWidth %f ",drawLineY,maxWidth);
    
    return CGSizeMake(maxWidth, -drawLineY);
}

#pragma mark - Analyze Text
//-- 解析文本内容
- (NSString *)analyzeText:(NSString *)string
{
    [self.richTextRunsArray removeAllObjects];
    [self.richTextRunRectDic removeAllObjects];
    
    NSString *result = @"";
    
    NSMutableArray *array = self.richTextRunsArray;
    
    result = [RichTextEmojiRun analyzeText:string runsArray:&array];
    
    result = [RichTextURLRun analyzeText:result runsArray:&array];
    
    [self.richTextRunsArray makeObjectsPerformSelector:@selector(setOriginalFont:) withObject:self.font];
    
    return result;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [(UITouch *)[touches anyObject] locationInView:self];
    CGPoint runLocation = CGPointMake(location.x, self.frame.size.height - location.y);
    
    if (self.delegage && [self.delegage respondsToSelector:@selector(richTextView: touchBeginRun:)])
    {
        __weak RichTextView *weakSelf = self;
        [self.richTextRunRectDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
         {
             CGRect rect = [((NSValue *)key) CGRectValue];
             RichTextBaseRun *run = obj;
             if(CGRectContainsPoint(rect, runLocation))
             {
                 [weakSelf.delegage richTextView:weakSelf touchBeginRun:run];
             }
         }];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [(UITouch *)[touches anyObject] locationInView:self];
    CGPoint runLocation = CGPointMake(location.x, self.frame.size.height - location.y);
    
    if (self.delegage && [self.delegage respondsToSelector:@selector(richTextView: touchEndRun:)])
    {
        [self.richTextRunRectDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
         {
             __weak RichTextView *weakSelf = self;
             CGRect rect = [((NSValue *)key) CGRectValue];
             RichTextBaseRun *run = obj;
             if(CGRectContainsPoint(rect, runLocation))
             {
                 [weakSelf.delegage richTextView:weakSelf touchEndRun:run];
             }
         }];
    }
}

#pragma mark - Set
- (void)setText:(NSString *)text
{
    [self setNeedsDisplay];
    _text = text;
}

- (void)setFont:(UIFont *)font
{
    [self setNeedsDisplay];
    _font = font;
}

- (void)setTextColor:(UIColor *)textColor
{
    [self setNeedsDisplay];
    _textColor = textColor;
}

- (void)setLineSpacing:(float)lineSpacing
{
    [self setNeedsDisplay];
    _lineSpacing = lineSpacing;
}

@end


@implementation RichTextBaseRun

- (id)init
{
    self = [super init];
    if (self) {
        self.isResponseTouch = NO;
    }
    return self;
}

//-- 替换基础文本
- (void)replaceTextWithAttributedString:(NSMutableAttributedString*) attributedString
{
    [attributedString addAttribute:@"RichTextAttribute" value:self range:self.range];
}

//-- 绘制内容
- (BOOL)drawRunWithRect:(CGRect)rect
{
    return NO;
}

@end

@implementation RichTextEmojiRun

- (id)init
{
    self = [super init];
    if (self) {
        self.type = richTextEmojiRunType;
        self.isResponseTouch = NO;
    }
    return self;
}

- (BOOL)drawRunWithRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSString *emojiString = [NSString stringWithFormat:@"%@.png",[[RichTextEmojiRun emojiStringArray] objectForKey:self.originalText]];
    
    UIImage *image = [UIImage imageNamed:emojiString];
    CGRect frame = rect;
    frame.origin.y += -1;
    rect = frame;
    if (image)
    {
        CGContextDrawImage(context, rect, image.CGImage);
    }
    return YES;
}

+ (NSDictionary *) emojiStringArray
{
    NSDictionary *emojiNameDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"emojiName" ofType:@"plist"]];
    
    return emojiNameDict;//[NSArray arrayWithObjects:@"[smile]",@"[cry]",nil];
}

+ (NSString *)analyzeText:(NSString *)string runsArray:(NSMutableArray **)runArray
{
    NSString *markL = @"[";
    NSString *markR = @"]";
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    NSMutableString *newString = [[NSMutableString alloc] initWithCapacity:string.length];
    
    //偏移索引 由于会把长度大于1的字符串替换成一个空白字符。这里要记录每次的偏移了索引。以便简历下一次替换的正确索引
    int offsetIndex = 0;
    
    for (int i = 0; i < string.length; i++)
    {
        NSString *s = [string substringWithRange:NSMakeRange(i, 1)];
        
        if (([s isEqualToString:markL]) || ((stack.count > 0) && [stack[0] isEqualToString:markL]))
        {
            if (([s isEqualToString:markL]) && ((stack.count > 0) && [stack[0] isEqualToString:markL]))
            {
                for (NSString *c in stack)
                {
                    [newString appendString:c];
                }
                [stack removeAllObjects];
            }
            
            [stack addObject:s];
            
            if ([s isEqualToString:markR] || (i == string.length - 1))
            {
                NSMutableString *emojiStr = [[NSMutableString alloc] init];
                for (NSString *c in stack)
                {
                    [emojiStr appendString:c];
                }
                
                if ([[[RichTextEmojiRun emojiStringArray] allKeys] containsObject:emojiStr])
                {
                    RichTextEmojiRun *emoji = [[RichTextEmojiRun alloc] init];
                    emoji.range = NSMakeRange(i + 1 - emojiStr.length - offsetIndex, 1);
                    emoji.originalText = emojiStr;
                    [*runArray addObject:emoji];
                    [newString appendString:@" "];
                    
                    offsetIndex += emojiStr.length - 1;
                }
                else
                {
                    [newString appendString:emojiStr];
                }
                
                [stack removeAllObjects];
            }
        }
        else
        {
            [newString appendString:s];
        }
    }
    
    return newString;
}

@end


static const float kZoom = 1.1f;

@implementation RichTextImageRun

- (void)replaceTextWithAttributedString:(NSMutableAttributedString*) attString
{
    //删除替换的占位字符
    [attString deleteCharactersInRange:self.range];
    
    CTRunDelegateCallbacks emojiCallbacks;
    emojiCallbacks.version      = kCTRunDelegateVersion1;
    emojiCallbacks.dealloc      = RichTextRunEmojiDelegateDeallocCallback;
    emojiCallbacks.getAscent    = RichTextRunEmojiDelegateGetAscentCallback;
    emojiCallbacks.getDescent   = RichTextRunEmojiDelegateGetDescentCallback;
    emojiCallbacks.getWidth     = RichTextRunEmojiDelegateGetWidthCallback;
    
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
    
    //
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&emojiCallbacks, (__bridge void*)self);
    [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
    CFRelease(runDelegate);
    
    [attString insertAttributedString:imageAttributedString atIndex:self.range.location];
    
    [super replaceTextWithAttributedString:attString];
}

#pragma mark - RunDelegateCallback

void RichTextRunEmojiDelegateDeallocCallback(void *refCon)
{
    
}

//--上行高度
CGFloat RichTextRunEmojiDelegateGetAscentCallback(void *refCon)
{
    RichTextImageRun *run =(__bridge RichTextImageRun *) refCon;
    return run.originalFont.ascender * kZoom;
}

//--下行高度
CGFloat RichTextRunEmojiDelegateGetDescentCallback(void *refCon)
{
    RichTextImageRun *run =(__bridge RichTextImageRun *) refCon;
    return run.originalFont.descender * kZoom;
}

//-- 宽
CGFloat RichTextRunEmojiDelegateGetWidthCallback(void *refCon)
{
    RichTextImageRun *run =(__bridge RichTextImageRun *) refCon;
    return (run.originalFont.ascender - run.originalFont.descender) * kZoom;
}

@end

@implementation RichTextURLRun

- (id)init
{
    self = [super init];
    if (self) {
        self.type = richTextURLRunType;
        self.isResponseTouch = YES;
    }
    return self;
}

//-- 替换基础文本
- (void)replaceTextWithAttributedString:(NSMutableAttributedString*) attributedString
{
    [attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor blueColor].CGColor range:self.range];
    [super replaceTextWithAttributedString:attributedString];
}

//-- 绘制内容
- (BOOL)drawRunWithRect:(CGRect)rect
{
    return NO;
}

//-- 解析文本内容
+ (NSString *)analyzeText:(NSString *)string runsArray:(NSMutableArray **)runArray
{
    //((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
    NSError *error;
    //NSString *regulaStr = @"\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    for (NSTextCheckingResult *match in arrayOfAllMatches)
    {
        NSString* substringForMatch = [string substringWithRange:match.range];
        RichTextURLRun *urlRun = [[RichTextURLRun alloc] init];
        urlRun.range = match.range;
        urlRun.originalText = substringForMatch;
        [*runArray addObject:urlRun];
    }
    return [string copy];
}

@end

