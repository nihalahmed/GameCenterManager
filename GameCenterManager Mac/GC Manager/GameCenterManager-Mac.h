//
//  GameCenterManager.h
//
//  Created by iRare Media on 7/2/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
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

enum {
    GCMErrorUnknown = 1,
    GCMErrorNotAvailable = 2,
    GCMErrorChallengeNotAvailable = 3,
    GCMErrorInternetNotAvailable = 4,
    GCMErrorAchievementDataMissing = 5
}; typedef NSInteger GCMErrorCode;

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

/** Gets a list of challenges for the current player and game. If GameCenter is not available it will return nil and provide an error using the gameCenterManager:error: delegate method. Use the completion handler to get challenges.
 @param handler Completion handler with an NSArray containing challenges and an NSError. The NSError object will be nil if there is no error.
 */
- (void)getChallengesWithCompletion:(void (^)(NSArray *challenges, NSError *error))handler;

/** Resets local player's achievements */
- (void)resetAchievements;

// Returns currently authenticated local player. If no player is authenticated, "unknownPlayer" is returned.
- (NSString *)localPlayerId;
- (GKLocalPlayer *)localPlayerData;
- (void)localPlayerPhoto:(void (^)(NSImage *playerPhoto))handler;

/** Checks for an active internet connection.
  @return BOOL value, YES if an active internet connection is available, NO if there is no internet connection.
 */
- (BOOL)isInternetAvailable;

// Check if GameCenter is supported
- (BOOL)checkGameCenterAvailability;

// Use this property to check if Game Center is available and supported on the current device.
@property (nonatomic, assign) BOOL isGameCenterAvailable;

@end


//GameCenterManager Mac Delegate
@protocol GameCenterManagerDelegate <NSObject>
@optional
- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation;
- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error;
- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation;
- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation;
- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score;
- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation;
- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error;
@end



