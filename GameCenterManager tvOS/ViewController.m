//
//  ViewController.m
//  GameCenterManager
//
//  Created by iRare Media on Sepetmber 21, 2013.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//  Copyright (c) 2015 Daniel Rosser. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize scrollView;
@synthesize statusDetailLabel, actionLabel, actionBarLabel;
@synthesize playerPicture, playerName, playerStatus, tvOSInfo;
@synthesize buttonReportScore, buttonReportAchievement, buttonFetchChallenges, buttonOpenAchievements, buttonOpenLeaderboards, buttonResetAchievements;

//------------------------------------------------------------------------------------------------------------//
//------- View Lifecycle -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - View Lifecycle

- (UIView *)preferredFocusedView
{
    if (buttonReportScore) {
        return buttonReportScore;
    }
    
    return self.view.preferredFocusedView;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup ViewController Appearance
    scrollView.contentSize = CGSizeMake(320, 450);
    playerPicture.layer.cornerRadius = playerPicture.frame.size.height/2;
    playerPicture.layer.masksToBounds = YES;
    [actionBarLabel setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10]} forState:UIControlStateNormal];
    
    // Set GameCenter Manager Delegate
    [[GameCenterManager sharedManager] setDelegate:self];
    
    UIFocusGuide *focusGuide = [[UIFocusGuide alloc]init];
    focusGuide.preferredFocusedView = [self preferredFocusedView];
    [self.view addLayoutGuide:focusGuide];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];

    BOOL available = [[GameCenterManager sharedManager] checkGameCenterAvailability:YES];
    if (available) {
        [self.navigationController.navigationBar setValue:@"GameCenter Available" forKeyPath:@"prompt"];
    } else {
        [self.navigationController.navigationBar setValue:@"GameCenter Unavailable" forKeyPath:@"prompt"];
    }
    
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            actionBarLabel.title = [NSString stringWithFormat:@"%@ signed in.", player.displayName];
            playerName.text = player.displayName;
            playerStatus.text = @"Player is not underage";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(UIImage *playerPhoto) {
                playerPicture.image = playerPhoto;
            }];
        } else {
            playerName.text = player.displayName;
            playerStatus.text = @"Player is underage";
            actionBarLabel.title = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        actionBarLabel.title = [NSString stringWithFormat:@"No GameCenter player found."];
    }
    
    #if TARGET_OS_SIMULATOR
        tvOSInfo.text = @"With the tvOS Simulator use the Keyboard: Cursor Control Keys (Up Down), Enter = Select, Escape = Menu/Back";
    #endif
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Scores ----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Scores

- (IBAction)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:[[GameCenterManager sharedManager] highScoreForLeaderboard:@"grp.GameCenterManager.PlayerScores"]+1 leaderboard:@"grp.GameCenterManager.PlayerScores" sortOrder:GameCenterSortOrderHighToLow];
    actionBarLabel.title = [NSString stringWithFormat:@"Score recorded."];
}

- (IBAction)showLeaderboard {
    [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:self withLeaderboard:@"grp.GameCenterManager.PlayerScores"];
    actionBarLabel.title = [NSString stringWithFormat:@"Displayed GameCenter Leaderboards."];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Achievements ----------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Achievements

- (IBAction)reportAchievement {
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.GameCenterManager.FirstAchievement"] == 100) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.GameCenterManager.SecondAchievement" percentComplete:100 shouldDisplayNotification:YES];
    }
    
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.GameCenterManager.FirstAchievement"] == 0) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.GameCenterManager.FirstAchievement" percentComplete:100 shouldDisplayNotification:YES];
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.GameCenterManager.SecondAchievement" percentComplete:50 shouldDisplayNotification:NO];
    }
    
    NSLog(@"Achievement One Progress: %f | Achievement Two Progress: %f", [[GameCenterManager sharedManager] progressForAchievement:@"grp.GameCenterManager.FirstAchievement"], [[GameCenterManager sharedManager] progressForAchievement:@"grp.GameCenterManager.SecondAchievement"]);
    actionBarLabel.title = [NSString stringWithFormat:@"Achievement recorded."];
}

- (IBAction)showAchievements {
    [[GameCenterManager sharedManager] presentAchievementsOnViewController:self];
    actionBarLabel.title = [NSString stringWithFormat:@"Displayed GameCenter Achievements."];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Challenges ------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Challenges

- (IBAction)loadChallenges {
    // This feature is only supported in iOS 6 and higher (don't worry - GC Manager will check for you and return NIL if it isn't available)
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        actionBarLabel.title = [NSString stringWithFormat:@"Loaded GameCenter challenges. Check log."];
        NSLog(@"GC Challenges: %@ | Error: %@", challenges, error);
    }];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameKit Delegate -----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameKit Delegate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Delegate ------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Manager Delegate

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    [self presentViewController:gameCenterLoginController animated:YES completion:^{
        NSLog(@"Finished Presenting Authentication Controller");
    }];
}

- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation {
    NSLog(@"GC Availabilty: %@", availabilityInformation);
    if ([[availabilityInformation objectForKey:@"status"] isEqualToString:@"GameCenter Available"]) {
        [self.navigationController.navigationBar setValue:@"GameCenter Available" forKeyPath:@"prompt"];
        statusDetailLabel.text = @"Game Center is online, the current player is logged in, and this app is setup.";
    } else {
        [self.navigationController.navigationBar setValue:@"GameCenter Unavailable" forKeyPath:@"prompt"];
        statusDetailLabel.text = [availabilityInformation objectForKey:@"error"];
    }
    
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            actionBarLabel.title = [NSString stringWithFormat:@"%@ signed in.", player.displayName];
            playerName.text = player.displayName;
            playerStatus.text = @"Player is not underage and is signed-in";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(UIImage *playerPhoto) {
                playerPicture.image = playerPhoto;
            }];
        } else {
            playerName.text = player.displayName;
            playerStatus.text = @"Player is underage";
            actionBarLabel.title = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        actionBarLabel.title = [NSString stringWithFormat:@"No GameCenter player found."];
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error {
    NSLog(@"GCM Error: %@", error);
    actionBarLabel.title = error.domain;
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(GKAchievement *)achievement withError:(NSError *)error {
    if (!error) {
        NSLog(@"GCM Reported Achievement: %@", achievement);
        actionBarLabel.title = [NSString stringWithFormat:@"Reported achievement with %.1f percent completed", achievement.percentComplete];
    } else {
        NSLog(@"GCM Error while reporting achievement: %@", error);
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(GKScore *)score withError:(NSError *)error {
    if (!error) {
        NSLog(@"GCM Reported Score: %@", score);
        actionBarLabel.title = [NSString stringWithFormat:@"Reported leaderboard score: %lld", score.value];
    } else {
        NSLog(@"GCM Error while reporting score: %@", error);
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager didSaveScore:(GKScore *)score {
    NSLog(@"Saved GCM Score with value: %lld", score.value);
    actionBarLabel.title = [NSString stringWithFormat:@"Score saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager didSaveAchievement:(GKAchievement *)achievement {
    NSLog(@"Saved GCM Achievement: %@", achievement);
    actionBarLabel.title = [NSString stringWithFormat:@"Achievement saved for upload to GameCenter."];
}

- (IBAction)resetAchievements {
    [[GameCenterManager sharedManager] resetAchievementsWithCompletion:^(NSError *error) {
        if (error) NSLog(@"Error Resetting Achievements: %@", error);
    }];
}


@end

