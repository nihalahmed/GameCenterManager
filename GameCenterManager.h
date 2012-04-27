//
//  GameCenterManager.h
//
//  Created by Nihal Ahmed on 12-03-16.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

// Change this value to your own secret key
#define kGameCenterManagerKey [@"MyKey" dataUsingEncoding:NSUTF8StringEncoding]
#define LIBRARY_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
#define kGameCenterManagerDataFile @"GameCenterManager.plist"
#define kGameCenterManagerDataPath [LIBRARY_FOLDER stringByAppendingPathComponent:kGameCenterManagerDataFile]
#define kGameCenterManagerAvailabilityNotification @"GameCenterManagerAvailabilityNotification"
#define kGameCenterManagerReportScoreNotification @"GameCenterManagerReportScoreNotification"
#define kGameCenterManagerReportAchievementNotification @"GameCenterManagerReportAchievementNotification"
#define kGameCenterManagerResetAchievementNotification @"GameCenterManagerResetAchievementNotification"

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Reachability.h"
#import "NSDataAES256.h"

@interface GameCenterManager : NSObject {
    NSMutableArray *_leaderboards;
}

// Returns the shared instance of GameCenterManager.
+ (GameCenterManager *)sharedManager;

// Initializes Game Center Manager. Should be called at app launch.
- (void)initGameCenter;

// Synchronizes local player data with Game Center data.
- (void)syncGameCenter;

// Saves score locally and reports it to Game Center. If error occurs, score is saved to be submitted later.
- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier;

// Saves achievement locally and reports it to Game Center. If error occurs, achievement is saved to be submitted later.
- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete;

// Reports scores and achievements which could not be reported earlier.
- (void)reportSavedScoresAndAchievements;

// Saves score to be submitted later.
- (void)saveScoreToReportLater:(GKScore *)score;

// Saves achievement to be submitted later.
- (void)saveAchievementToReportLater:(NSString *)identifier percentComplete:(double)percentComplete;

// Returns local player's high score for specified leaderboard.
- (int)highScoreForLeaderboard:(NSString *)identifier;

// Returns local player's high scores for multiple leaderboards.
- (NSDictionary *)highScoreForLeaderboards:(NSArray *)identifiers;

// Returns local player's percent completed for specified achievement.
- (double)progressForAchievement:(NSString *)identifier;

// Returns local player's percent completed for multiple achievements.
- (NSDictionary *)progressForAchievements:(NSArray *)identifiers;

// Resets local player's achievements
- (void)resetAchievements;

// Returns currently authenticated local player. If no player is authenticated, "unknownPlayer" is returned.
- (NSString *)localPlayerId;

// Returns YES if an active internet connection is available.
- (BOOL)isInternetAvailable;

// Use this property to check if Game Center is available and supported on the current device.
@property (nonatomic, assign) BOOL isGameCenterAvailable;

@end