//
//  ViewController.m
//  GameCenterManager
//
//  Created by Nihal Ahmed on 12-03-17.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize statusLabel;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callback:)
                                                 name:kGameCenterManagerReportScoreNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callback:)
                                                 name:kGameCenterManagerReportAchievementNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callback:)
                                                 name:kGameCenterManagerResetAchievementNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"HighScores"];
}

- (IBAction)reportAchievement {
    [[GameCenterManager sharedManager] saveAndReportAchievement:@"1000Points" percentComplete:50];
}

- (IBAction)showLeaderboard {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        statusLabel.Text = @"Status: GameCenter Available";
        GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
        leaderboardViewController.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardViewController.leaderboardDelegate = self;
        [self presentViewController:leaderboardViewController animated:YES completion:nil];
    } else {
        statusLabel.Text = @"Status: GameCenter Unavailable";
    }
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showAchievements {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        statusLabel.Text = @"Status: GameCenter Available";
        GKAchievementViewController *achievementViewController = [[GKAchievementViewController alloc] init];
        achievementViewController.achievementDelegate = self;
        [self presentViewController:achievementViewController animated:YES completion:nil];
    } else {
        statusLabel.Text = @"Status: Game Center Unavailable";
    }
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetAchievements {
    [[GameCenterManager sharedManager] resetAchievements];
}

- (void)callback:(NSNotification *)notification {
    if([notification.userInfo objectForKey:@"error"] == nil) {
        statusLabel.Text = @"Status: Success";
    } else {
        statusLabel.Text = [NSString stringWithFormat:@"Status: GameCenter Error %@", [notification.userInfo objectForKey:@"error"]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
