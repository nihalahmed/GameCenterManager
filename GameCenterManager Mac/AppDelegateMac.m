//
//  AppDelegate.m
//  GameCenterManager Mac
//
//  Created by iRare Media on 7/2/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "AppDelegateMac.h"

@implementation AppDelegateMac
@synthesize window;
@synthesize gcActionInfo, gcStatusTitle, gcStatusMessage;
@synthesize playerPicture, playerStatus, playerName;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Setup Window
    [window setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"FeltTile.png"]]];
    
    // Setup Image Border
    playerPicture.layer.BorderColor = [[NSColor whiteColor] CGColor];
    playerPicture.layer.BorderWidth = 2.0;
    playerPicture.layer.shadowOffset = CGSizeMake(1, 1.5);
    playerPicture.layer.shadowOpacity = 0.5;
    
    // Setup GameCenter Manager
    [[GameCenterManager sharedManager] setDelegate:self];
    [[GameCenterManager sharedManager] initGameCenter];
    BOOL available = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    if (available) {
        gcStatusTitle.stringValue = @"GAME CENTER AVAILABLE";
    } else {
        gcStatusTitle.stringValue = @"GAME CENTER UNAVAILABLE";
    }
    
    // Get Player Status
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            gcActionInfo.stringValue = [NSString stringWithFormat:@"%@ signed in.", player.displayName];
            playerName.stringValue = player.displayName;
            playerStatus.stringValue = @"Player is not underage";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(NSImage *playerPhoto) {
                playerPicture.image = playerPhoto;
            }];
        } else {
            gcActionInfo.stringValue = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        gcActionInfo.stringValue = [NSString stringWithFormat:@"No GameCenter player found."];
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Delegate ------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Manager Delegate

- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation {
    NSLog(@"GC Availability: %@", availabilityInformation);
    if ([availabilityInformation objectForKey:@"message"]) {
        gcStatusMessage.stringValue = [availabilityInformation objectForKey:@"message"];
    }
    
    if ([[availabilityInformation objectForKey:@"status"] isEqualToString:@"GameCenter Available"]) {
        gcStatusTitle.stringValue = @"GAME CENTER AVAILABLE";
        gcStatusMessage.stringValue = @"Game Center is online, the current player is logged in, and this app is setup.";
    } else {
        gcStatusTitle.stringValue = @"GAME CENTER UNAVAILABLE";
        gcStatusMessage.stringValue = [availabilityInformation objectForKey:@"error"];
    }
    
    // Get Player Status
    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData];
    if (player) {
        if ([player isUnderage] == NO) {
            gcActionInfo.stringValue = [NSString stringWithFormat:@"%@ signed in.", player.displayName];
            playerName.stringValue = player.displayName;
            playerStatus.stringValue = @"Player is not underage and is signed in";
            [[GameCenterManager sharedManager] localPlayerPhoto:^(NSImage *playerPhoto) {
                playerPicture.image = playerPhoto;
                // Setup Image Border
                playerPicture.layer.BorderColor = [[NSColor whiteColor] CGColor];
                playerPicture.layer.BorderWidth = 2.0;
                playerPicture.layer.shadowOffset = CGSizeMake(1, 1.5);
                playerPicture.layer.shadowOpacity = 0.5;
                [playerPicture setNeedsDisplay];
            }];
        } else {
            gcActionInfo.stringValue = [NSString stringWithFormat:@"Underage player, %@, signed in.", player.displayName];
        }
    } else {
        gcActionInfo.stringValue = [NSString stringWithFormat:@"No GameCenter player found."];
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(NSViewController *)gameCenterLoginController {
    NSLog(@"Please Login");
}

- (void)gameCenterManager:(GameCenterManager *)manager error:(NSDictionary *)error {
    NSLog(@"GC Error: %@", error);
    if ([[error objectForKey:@"error"] isEqualToString:@"Could not save achievement. Data missing."]) {
        gcStatusMessage.stringValue = [NSString stringWithFormat:@"Could not save achievement. Data missing."];
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation {
    NSLog(@"GC Reported Score: %@", scoreInformation);
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Reported leaderboard score to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score {
    NSLog(@"Saved GC Score with value: %lld", score.value);
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Score saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"Saved GC Achievement, %@", [achievementInformation objectForKey:@"id"]);
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Achievement saved for upload to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation {
    NSLog(@"GC Reported Achievement: %@", achievementInformation);
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Reported achievement to GameCenter."];
}

- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error {
    if (error) {
        gcActionInfo.stringValue = [NSString stringWithFormat:@"Error reseting all GameCenter achievements."];
    } else {
        gcActionInfo.stringValue = [NSString stringWithFormat:@"Reset all GameCenter achievements."];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Scores ----------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Scores

- (IBAction)reportScore:(id)sender {
    [[GameCenterManager sharedManager] saveAndReportScore:[[GameCenterManager sharedManager] highScoreForLeaderboard:@"grp.PlayerScores"]+1 leaderboard:@"grp.PlayerScores" sortOrder:GameCenterSortOrderHighToLow];
    [gcActionInfo setStringValue:[NSString stringWithFormat:@"Score recorded."]];
}

- (IBAction)showLeaderboard:(id)sender {
    GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
    leaderboardViewController.timeScope = GKLeaderboardTimeScopeAllTime;
    leaderboardViewController.leaderboardDelegate = self;
    if (leaderboardViewController != nil) {
        GKDialogController *gcController = [GKDialogController sharedDialogController];
        gcController.parentWindow = window;
        [gcController presentViewController:leaderboardViewController];
    }
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Attempting to display GameCenter leaderboards."];
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    GKDialogController *gcController = [GKDialogController sharedDialogController];
    [gcController dismiss: self];
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Displayed GameCenter leaderboard."];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Achievements ----------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Achievements

- (IBAction)reportAchievement:(id)sender {
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"] == 100) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.SecondAchievement" percentComplete:100 shouldDisplayNotification:YES];
    }
    
    if ([[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"] == 0) {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.FirstAchievement" percentComplete:100 shouldDisplayNotification:YES];
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"grp.SecondAchievement" percentComplete:50 shouldDisplayNotification:NO];
    }
    
    NSLog(@"Achievement One Progress: %f | Achievement Two Progress: %f", [[GameCenterManager sharedManager] progressForAchievement:@"grp.FirstAchievement"], [[GameCenterManager sharedManager] progressForAchievement:@"grp.SecondAchievement"]);
    [self.gcActionInfo setStringValue:[NSString stringWithFormat:@"Achievement recorded."]];
}

- (IBAction)showAchievements:(id)sender {
    GKAchievementViewController *achievementViewController = [[GKAchievementViewController alloc] init];
    achievementViewController.achievementDelegate = self;
    if (achievementViewController != nil) {
        GKDialogController *gcController = [GKDialogController sharedDialogController];
        gcController.parentWindow = window;
        [gcController presentViewController:achievementViewController];
    }
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Attempting to display GameCenter achievements."];
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    GKDialogController *gcController = [GKDialogController sharedDialogController];
    [gcController dismiss: self];
    gcActionInfo.stringValue = [NSString stringWithFormat:@"Displayed GameCenter achievements."];
}

- (IBAction)resetAchievements:(id)sender {
    [[GameCenterManager sharedManager] resetAchievements];
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Challenges ------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Challenges

- (IBAction)loadChallenges:(id)sender {
    //This feature is only supported in OS X 10.8.2 and higher
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        gcActionInfo.stringValue = [NSString stringWithFormat:@"Loaded GameCenter challenges."];
        NSLog(@"GC Challenges: %@", challenges);
    }];
}

@end
