//
//  ViewController.m
//  GameCenterManager
//
//  Created by Nihal Ahmed on March 17, 2012. Edited and updated by iRare Media on April 28, 2013.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize statusLabel, statusDetailLabel, actionLabel;
@synthesize toolBar, header, scrollView;
@synthesize playerPicture, playerName, playerStatus;

//------------------------------------------------------------------------------------------------------------//
//Region: View Lifecycle -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Setup ViewController Appearance
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    scrollView.contentSize = CGSizeMake(320, 554);
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"GCBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    toolBar.layer.shadowOffset = CGSizeMake(1, 1.5);
    toolBar.layer.shadowOpacity = 0.5;
    header.layer.shadowOffset = CGSizeMake(1, 1.5);
    header.layer.shadowOpacity = 0.5;
    playerPicture.layer.BorderColor = [[UIColor whiteColor] CGColor];
    playerPicture.layer.BorderWidth = 2.0;
    playerPicture.layer.shadowOffset = CGSizeMake(1, 1.5);
    playerPicture.layer.shadowOpacity = 0.5;
    
    //Set GameCenter Manager Delegate
    [[GameCenterManager sharedManager] setDelegate:self];
    [[GameCenterManager sharedManager] initGameCenter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];

    BOOL available = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    if (available) {
        statusLabel.Text = @"GAME CENTER AVAILABLE";
    } else {
        statusLabel.Text = @"GAME CENTER UNAVAILABLE";
    }
    
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            actionLabel.text = [NSString stringWithFormat:@"%@ signed in.", player.displayName];
            playerName.text = player.displayName;
            playerStatus.text = @"Player is not underage";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(UIImage *playerPhoto) {
                playerPicture.image = playerPhoto;
            }];
        } else {
            playerName.text = player.displayName;
            playerStatus.text = @"Player is underage";
            actionLabel.text = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        actionLabel.text = [NSString stringWithFormat:@"No GameCenter player found."];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidUnload {
    [self setToolBar:nil];
    [self setHeader:nil];
    [self setScrollView:nil];
    [self setStatusDetailLabel:nil];
    [self setActionLabel:nil];
    [self setPlayerPicture:nil];
    [self setPlayerName:nil];
    [self setPlayerStatus:nil];
    [super viewDidUnload];
}

//------------------------------------------------------------------------------------------------------------//
//Region: GameCenter Scores ----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Scores

- (IBAction)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:[[GameCenterManager sharedManager] highScoreForLeaderboard:@"grp.PlayerScores"]+1 leaderboard:@"grp.PlayerScores" sortOrder:GameCenterSortOrderHighToLow];
    actionLabel.text = [NSString stringWithFormat:@"Score recorded."];
}

- (IBAction)showLeaderboard {
    GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
    leaderboardViewController.timeScope = GKLeaderboardTimeScopeAllTime;
    leaderboardViewController.leaderboardDelegate = self;
    [self presentViewController:leaderboardViewController animated:YES completion:nil];
    actionLabel.text = [NSString stringWithFormat:@"Attempting to display GameCenter leaderboards."];
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    actionLabel.text = [NSString stringWithFormat:@"Displayed GameCenter leaderboard."];
}

//------------------------------------------------------------------------------------------------------------//
//Region: GameCenter Achievements ----------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Achievements

- (IBAction)reportAchievement {
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"] == 100) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.SecondAchievement" percentComplete:100 shouldDisplayNotification:YES];
    }
    
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"] == 0) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.FirstAchievement" percentComplete:100 shouldDisplayNotification:YES];
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.SecondAchievement" percentComplete:50 shouldDisplayNotification:NO];
    }
    
    NSLog(@"Achievement One Progress: %f | Achievement Two Progress: %f", [[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"], [[GameCenterManager sharedManager] progressForAchievement:@"grp.SecondAchievement"]);
    actionLabel.text = [NSString stringWithFormat:@"Achievement recorded."];
}

- (IBAction)showAchievements {
    GKAchievementViewController *achievementViewController = [[GKAchievementViewController alloc] init];
    achievementViewController.achievementDelegate = self;
    [self presentViewController:achievementViewController animated:YES completion:nil];
    actionLabel.text = [NSString stringWithFormat:@"Attempting to display GameCenter achievements."];
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    actionLabel.text = [NSString stringWithFormat:@"Displayed GameCenter achievements."];
}

- (IBAction)resetAchievements {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Really Reset ALL Achievements?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Reset Achievements" otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

//------------------------------------------------------------------------------------------------------------//
//Region: GameCenter Challenges ------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Challenges

- (IBAction)loadChallenges {
    //This feature is only supported in iOS 6 and higher (don't worry - GC Manager will check for you and return NIL if it isn't available)
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        actionLabel.text = [NSString stringWithFormat:@"Loaded GameCenter challenges."];
        NSLog(@"GC Challenges: %@ | Error: %@", challenges, error);
    }];
}

//------------------------------------------------------------------------------------------------------------//
//Region: GameCenter Manager Delegate ------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Manager Delegate

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    [self presentViewController:gameCenterLoginController animated:YES completion:^{
        NSLog(@"Done");
    }];
}

- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation {
    NSLog(@"GC Availabilty: %@", availabilityInformation);
    if ([[availabilityInformation objectForKey:@"status"] isEqualToString:@"GameCenter Available"]) {
        statusLabel.text = @"GAME CENTER AVAILABLE";
        statusDetailLabel.text = @"Game Center is online, the current player is logged in, and this app is setup.";
    } else {
        statusLabel.Text = @"GAME CENTER UNAVAILABLE";
        statusDetailLabel.text = [availabilityInformation objectForKey:@"error"];
    }
    
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            playerName.text = player.displayName;
            playerStatus.text = @"Player is not underage and is signed-in";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(UIImage *playerPhoto) {
                playerPicture.image = playerPhoto;
            }];
        } else {
            playerName.text = player.displayName;
            playerStatus.text = @"Player is underage";
            actionLabel.text = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        actionLabel.text = [NSString stringWithFormat:@"No GameCenter player found."];
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error {
    NSLog(@"GC Error: %@", error);
    actionLabel.text = error.domain;
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation {
    NSLog(@"GC Reported Score: %@", scoreInformation);
    actionLabel.text = [NSString stringWithFormat:@"Reported leaderboard score to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score {
    NSLog(@"Saved GC Score with value: %lld", score.value);
    actionLabel.text = [NSString stringWithFormat:@"Score saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"Saved GC Achievement, %@", [achievementInformation objectForKey:@"id"]);
    actionLabel.text = [NSString stringWithFormat:@"Achievement saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"GC Reported Achievement: %@", achievementInformation);
    actionLabel.text = [NSString stringWithFormat:@"Reported achievement to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error {
    if (error) {
        actionLabel.text = [NSString stringWithFormat:@"Error reseting all GameCenter achievements."];
    } else {
        actionLabel.text = [NSString stringWithFormat:@"Reset all GameCenter achievements."];
    }
}

//------------------------------------------------------------------------------------------------------------//
//Region: UIActionSheet Delegate -----------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Reset Achievements"]) {
       [[GameCenterManager sharedManager] resetAchievements]; 
    } else {
        //Cancel
    }
}

@end



