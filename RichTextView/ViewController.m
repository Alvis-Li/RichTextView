//
//  ViewController.m
//  RichTextView
//
//  Created by levy on 15/8/3.
//  Copyright (c) 2015年 levy. All rights reserved.
//

#import "ViewController.h"
#import "RichTextView.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RichTextView * richTextView = [[RichTextView alloc]initWithFrame:CGRectMake(100, 100, CGRectGetWidth(self.view.frame), 10)];
    richTextView.text = @"dfjghdfkjghsl[大哭]5465456+768485[微笑]";
    richTextView.backgroundColor = [UIColor clearColor];
    CGRect rect = richTextView.frame;
    rect.size = [richTextView draw];
    richTextView.frame = rect;
    [self.view addSubview: richTextView];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
