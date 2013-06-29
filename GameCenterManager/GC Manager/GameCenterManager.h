//
//  GameCenterManager.h
//
//  Created by Nihal Ahmed on 12-03-16. Updated by iRare Media on 5-27-13.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#warning Definition of GameCenterManagerKey is required. Change this value to your own secret key.
#define kGameCenterManagerKey [@"MyKey" dataUsingEncoding:NSUTF8StringEncoding]

#define LIBRARY_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
#define kGameCenterManagerDataFile @"GameCenterManager.plist"
#define kGameCenterManagerDataPath [LIBRARY_FOLDER stringByAppendingPathComponent:kGameCenterManagerDataFile]

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Reachability.h"
#import "NSDataAES256.h"

typedef enum GameCenterSortOrder {
    GameCenterSortOrderHighToLow,
    GameCenterSortOrderLowToHigh
} GameCenterSortOrder;

@protocol GameCenterManagerDelegate;
@interface GameCenterManager : NSObject {
    NSMutableArray *_leaderboards;
}

// Sets up the Delegate
@property (nonatomic, weak) id <GameCenterManagerDelegate> delegate;

// Returns the shared instance of GameCenterManager.
+ (GameCenterManager *)sharedManager;

// Initializes Game Center Manager. Should be called at app launch.
- (void)initGameCenter;

// Synchronizes local player data with Game Center data.
- (void)syncGameCenter;

// Saves score locally and reports it to Game Center. If error occurs, score is saved to be submitted later.
- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order;

// Saves achievement locally and reports it to Game Center. If error occurs, achievement is saved to be submitted later.
- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete shouldDisplayNotification:(BOOL)displayNotification;

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

// Returns a list of challenges for the current player and game. If GameCenter is not available it will return nil. If there is an error connecting to GameCenter, the first object in the array will be an NSError detailing the error.
- (NSArray *)getChallenges;

// Resets local player's achievements
- (void)resetAchievements;

// Returns currently authenticated local player. If no player is authenticated, "unknownPlayer" is returned.
- (NSString *)localPlayerId;
- (GKLocalPlayer *)localPlayerData;

// Returns YES if an active internet connection is available.
- (BOOL)isInternetAvailable;

// Check if GameCenter is supported
- (BOOL)checkGameCenterAvailability;

// Use this property to check if Game Center is available and supported on the current device.
@property (nonatomic, assign) BOOL isGameCenterAvailable;

@end


//GameCenterManager Delegate
@protocol GameCenterManagerDelegate <NSObject>
@required
- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController;
@optional
- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation;
- (void)gameCenterManager:(GameCenterManager *)manager error:(NSDictionary *)error;
- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation;
- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation;
- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score;
- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation;
- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error;
@end



