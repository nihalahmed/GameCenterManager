//
//  ViewController.m
//  GameCenterManager
//
//  Created by iRare Media on Sepetmber 21, 2013.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize scrollView;
@synthesize statusDetailLabel, actionLabel, actionBarLabel;
@synthesize playerPicture, playerName, playerStatus;

//------------------------------------------------------------------------------------------------------------//
//------- View Lifecycle -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup ViewController Appearance
    scrollView.contentSize = CGSizeMake(320, 450);
    playerPicture.layer.cornerRadius = 25;
    playerPicture.layer.masksToBounds = YES;
    [actionBarLabel setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15<=10], NSFontAttributeName,nil] forState:UIControlStateNormal];
    
    // Set GameCenter Manager Delegate
    [[GameCenterManager sharedManager] setDelegate:self];
    [[GameCenterManager sharedManager] initGameCenter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];

    BOOL available = [[GameCenterManager sharedManager] checkGameCenterAvailability];
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
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidUnload {
    [self setScrollView:nil];
    [self setStatusDetailLabel:nil];
    [self setActionLabel:nil];
    [self setPlayerPicture:nil];
    [self setPlayerName:nil];
    [self setPlayerStatus:nil];
    [super viewDidUnload];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Scores ----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Scores

- (IBAction)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:[[GameCenterManager sharedManager] highScoreForLeaderboard:@"grp.PlayerScores"]+1 leaderboard:@"grp.PlayerScores" sortOrder:GameCenterSortOrderHighToLow];
    actionBarLabel.title = [NSString stringWithFormat:@"Score recorded."];
}

- (IBAction)showLeaderboard {
    GKGameCenterViewController *leaderboardViewController = [[GKGameCenterViewController alloc] init];
    leaderboardViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    leaderboardViewController.gameCenterDelegate = self;
    [self presentViewController:leaderboardViewController animated:YES completion:nil];
    actionBarLabel.title = [NSString stringWithFormat:@"Attempting to display GameCenter leaderboards."];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Achievements ----------------------------------------------------------------------------//
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
    actionBarLabel.title = [NSString stringWithFormat:@"Achievement recorded."];
}

- (IBAction)showAchievements {
    GKGameCenterViewController *achievementViewController = [[GKGameCenterViewController alloc] init];
    achievementViewController.viewState = GKGameCenterViewControllerStateAchievements;
    achievementViewController.gameCenterDelegate = self;
    [self presentViewController:achievementViewController animated:YES completion:nil];
    actionBarLabel.title = [NSString stringWithFormat:@"Attempting to display GameCenter achievements."];
}

- (IBAction)resetAchievements {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Really Reset ALL Achievements?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Reset Achievements" otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Challenges ------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Challenges

- (IBAction)loadChallenges {
    // This feature is only supported in iOS 6 and higher (don't worry - GC Manager will check for you and return NIL if it isn't available)
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        actionBarLabel.title = [NSString stringWithFormat:@"Loaded GameCenter challenges."];
        NSLog(@"GC Challenges: %@ | Error: %@", challenges, error);
    }];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameKit Delegate -----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameKit Delegate

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (gameCenterViewController.viewState == GKGameCenterViewControllerStateAchievements) {
        actionBarLabel.title = [NSString stringWithFormat:@"Displayed GameCenter achievements."];
    } else if (gameCenterViewController.viewState == GKGameCenterViewControllerStateLeaderboards) {
        actionBarLabel.title = [NSString stringWithFormat:@"Displayed GameCenter leaderboard."];
    } else {
        actionBarLabel.title = [NSString stringWithFormat:@"Displayed GameCenter controller."];
    }
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
    NSLog(@"GC Error: %@", error);
    actionBarLabel.title = error.domain;
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation {
    NSLog(@"GC Reported Score: %@", scoreInformation);
    actionBarLabel.title = [NSString stringWithFormat:@"Reported leaderboard score to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score {
    NSLog(@"Saved GC Score with value: %lld", score.value);
    actionBarLabel.title = [NSString stringWithFormat:@"Score saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"Saved GC Achievement, %@", [achievementInformation objectForKey:@"id"]);
    actionBarLabel.title = [NSString stringWithFormat:@"Achievement saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"GC Reported Achievement: %@", achievementInformation);
    actionBarLabel.title = [NSString stringWithFormat:@"Reported achievement to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error {
    if (error) {
        actionBarLabel.title = [NSString stringWithFormat:@"Error reseting all GameCenter achievements."];
    } else {
        actionBarLabel.title = [NSString stringWithFormat:@"Reset all GameCenter achievements."];
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- UIActionSheet Delegate -----------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Reset Achievements"]) {
       [[GameCenterManager sharedManager] resetAchievementsWithCompletion:^(NSError *error) {
           if (error) NSLog(@"Error Resetting Achievements: %@", error);
       }];
    }
}

@end



