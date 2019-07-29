//
//  ViewController.m
//  Binance DEX
//
//  Created by inshow on 2019/7/18.
//  Copyright © 2019年 云. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "UIColor+Hex.h"

@interface ViewController ()<WKNavigationDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithHexString:@"12161C"];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];
    [self.view addSubview:self.activityIndicator];
    [self loadingPage];
    
    // 监测网页加载进度
    [self.webView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                      options:0
                      context:nil];

}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == _webView) {
        self.progressView.progress = _webView.estimatedProgress;
        NSLog(@"estimatedProgress: %f",_webView.estimatedProgress);
        if (_webView.estimatedProgress >= 1.0f) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.progress = 0;
                [self.activityIndicator stopAnimating];
            });
        }else{
            [self.activityIndicator startAnimating];
        }
    }else{
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

#pragma mark -- 懒加载
- (UIProgressView *)progressView
{
    if (!_progressView){
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, StatusBarHeight, self.view.frame.size.width, 1)];
        _progressView.tintColor = [UIColor colorWithHexString:@"#f0b90b"];
        _progressView.trackTintColor = [UIColor clearColor];
    }
    return _progressView;
}

- (WKWebView *)webView{
    if(_webView == nil){
        // 创建网页配置对象
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        WKPreferences *preference = [[WKPreferences alloc] init];
        preference.minimumFontSize = 0;
        preference.javaScriptEnabled = YES;
        preference.javaScriptCanOpenWindowsAutomatically = YES;
        config.preferences = preference;
        config.allowsInlineMediaPlayback = YES;
        config.mediaTypesRequiringUserActionForPlayback = YES;
        
        _webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:config];
        _webView.navigationDelegate = self;
        _webView.allowsBackForwardNavigationGestures = YES;
    }
    return _webView;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (_activityIndicator == nil) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
        self.activityIndicator.frame= CGRectMake((SCREEN_WIDTH - 100)/2, (SCREEN_HEIGHT - 200)/2, 100, 100);
        self.activityIndicator.color = [UIColor colorWithHexString:@"#f0b90b"];
        self.activityIndicator.backgroundColor = [UIColor clearColor];
        self.activityIndicator.hidesWhenStopped = YES;
    }
    return _activityIndicator;
}

#pragma mark - WKNavigation Delegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"页面开始加载时调用: %@",navigation);
}
// 页面返回内容时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"页面返回内容时调用: %@",navigation);
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"页面加载失败时调用: %@",error);
    if (error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提 醒" message:@"未连接到互联网，请重试" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *centain = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self loadingPage];
        }];
        [alert addAction:centain];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [self.activityIndicator startAnimating];
        }];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    // Fix HomePage backgroundColor
    NSString *jsFont = [NSString stringWithFormat:@"document.body.style.backgroundColor='#12161C'"];
    [self.webView evaluateJavaScript:jsFont completionHandler:nil];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)loadingPage {
    //allWebsiteDataTypes清除所有缓存
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.binance.org/cn/"]];
        [self.webView loadRequest:request];
    }];
}

#pragma mark -- TabBar
- (void)addTabBar{
    UIView *tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - TabbarHeight, SCREEN_WIDTH, TabbarHeight)];
    tabBar.backgroundColor = [UIColor grayColor];
    [self.view addSubview:tabBar];
}
- (void)setupNavigationItem{
    // 后退
    UIButton *goBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [goBackButton setImage:[UIImage imageNamed:@"backbutton"] forState:UIControlStateNormal];
    [goBackButton addTarget:self action:@selector(goBackAction:) forControlEvents:UIControlEventTouchUpInside];
    goBackButton.frame = CGRectMake(0, 0, 30, StatusBarAndNavigationBarHeight);
    UIBarButtonItem * goBackButtonItem = [[UIBarButtonItem alloc] initWithCustomView:goBackButton];
    self.navigationItem.leftBarButtonItems = @[goBackButtonItem];
    
    // 刷新
    UIButton * refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setImage:[UIImage imageNamed:@"webRefreshButton"] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventTouchUpInside];
    refreshButton.frame = CGRectMake(0, 0, 30, StatusBarAndNavigationBarHeight);
    UIBarButtonItem * refreshButtonItem = [[UIBarButtonItem alloc] initWithCustomView:refreshButton];
    self.navigationItem.rightBarButtonItems = @[refreshButtonItem];
}
- (void)goBackAction:(id)sender{
    [_webView goBack];
}

- (void)refreshAction:(id)sender{
    [_webView reload];
}
@end
