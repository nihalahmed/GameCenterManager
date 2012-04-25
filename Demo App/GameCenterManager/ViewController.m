//
//  ViewController.m
//  GameCenterManager
//
//  Created by Nihal Ahmed on 12-03-17.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callback:)
                                                 name:kGameCenterManagerReportScoreNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callback:)
                                                 name:kGameCenterManagerReportAchievementNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callback:)
                                                 name:kGameCenterManagerResetAchievementNotification object:nil];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0, 0, 175, 40)];
    [btn setCenter:CGPointMake(self.view.bounds.size.width/2, 100)];
    [btn addTarget:self action:@selector(reportScore) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [btn setTitle:@"Report Score" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0, 0, 175, 40)];
    [btn setCenter:CGPointMake(self.view.bounds.size.width/2, 150)];
    [btn addTarget:self action:@selector(reportAchievement) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [btn setTitle:@"Report Achievement" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0, 0, 175, 40)];
    [btn setCenter:CGPointMake(self.view.bounds.size.width/2, 200)];
    [btn addTarget:self action:@selector(showLeaderboard) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [btn setTitle:@"Leaderboard" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0, 0, 175, 40)];
    [btn setCenter:CGPointMake(self.view.bounds.size.width/2, 250)];
    [btn addTarget:self action:@selector(showAchievements) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [btn setTitle:@"Achievements" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setFrame:CGRectMake(0, 0, 175, 40)];
    [btn setCenter:CGPointMake(self.view.bounds.size.width/2, 300)];
    [btn addTarget:self action:@selector(resetAchievements) forControlEvents:UIControlEventTouchUpInside];
    [btn setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [btn setTitle:@"Reset Achievements" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
    [lbl setCenter:CGPointMake(self.view.bounds.size.width/2, 400)];
    [lbl setTextAlignment:UITextAlignmentCenter];
    [self.view addSubview:lbl];
    [lbl release];
    _lbl = lbl;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"HighScores"];
}

- (void)reportAchievement {
    [[GameCenterManager sharedManager] saveAndReportAchievement:@"1000Points" percentComplete:50];
}

- (void)showLeaderboard {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
        leaderboardViewController.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardViewController.leaderboardDelegate = self;
        [self presentModalViewController:leaderboardViewController animated:YES];
        [leaderboardViewController release];
    }
    else {
        [_lbl setText:@"Game Center unavailable"];
    }
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)showAchievements {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        GKAchievementViewController *achievementViewController = [[GKAchievementViewController alloc] init];
        achievementViewController.achievementDelegate = self;
        [self presentModalViewController:achievementViewController animated:YES];
        [achievementViewController release];
    }
    else {
        [_lbl setText:@"Game Center unavailable"];
    }
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)resetAchievements {
    [[GameCenterManager sharedManager] resetAchievements];
}

- (void)callback:(NSNotification *)notification {
    if([notification.userInfo objectForKey:@"error"] == nil) {
        [_lbl setText:@"Success"];
    }
    else {
        [_lbl setText:[NSString stringWithFormat:@"Error: %@", [notification.userInfo objectForKey:@"error"]]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
