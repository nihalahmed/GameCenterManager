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

//------------------------------------------------------------------------------------------------------------//
//Region: View Lifecycle -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Setup ViewController Appearance
    self.view.backgroundColor = [UIColor underPageBackgroundColor];
    scrollView.contentSize = CGSizeMake(320, 484);
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"GCBar"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    toolBar.layer.shadowOffset = CGSizeMake(1, 1.5);
    toolBar.layer.shadowOpacity = 0.5;
    header.layer.shadowOffset = CGSizeMake(1, 1.5);
    header.layer.shadowOpacity = 0.5;
    
    //Set GameCenter Manager Delegate
    [[GameCenterManager sharedManager] setDelegate:self];
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
        } else {
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
    [super viewDidUnload];
}

//------------------------------------------------------------------------------------------------------------//
//Region: GameCenter Scores ----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Scores

- (IBAction)reportScore {
    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"HighScores"];
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
    [[GameCenterManager sharedManager] saveAndReportAchievement:@"1000Points" percentComplete:50 shouldDisplayNotification:YES];
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
    //This feature is only supported in iOS 6 and higher
    NSArray *challenges = [[GameCenterManager sharedManager] getChallenges];
    actionLabel.text = [NSString stringWithFormat:@"Loaded GameCenter challenges."];
    NSLog(@"GC Challenges: %@", challenges);
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
    statusDetailLabel.text = [availabilityInformation objectForKey:@"error"];
}

- (void)gameCenterManager:(GameCenterManager *)manager error:(NSDictionary *)error {
    NSLog(@"GC Error: %@", error);
    if ([[error objectForKey:@"error"] isEqualToString:@"Could not save achievement. Data missing."]) {
        actionLabel.text = [NSString stringWithFormat:@"Could not save achievement. Data missing."];
    }
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



