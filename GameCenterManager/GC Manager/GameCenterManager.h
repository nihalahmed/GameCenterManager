//
//  GameCenterManager.h
//
//  Created by Nihal Ahmed on 12-03-16. Updated by iRare Media on 7/2/13.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#warning Definition of GameCenterManagerKey is required. Change this value to your own secret key.
#define kGameCenterManagerKey [@"MyKey" dataUsingEncoding:NSUTF8StringEncoding]

#define LIBRARY_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
#define kGameCenterManagerDataFile @"GameCenterManager.plist"
#define kGameCenterManagerDataPath [LIBRARY_FOLDER stringByAppendingPathComponent:kGameCenterManagerDataFile]
#define __GK_USES_LEADERBOARD_ID [[GKLeaderboard alloc] respondsToSelector:@selector(leaderboardIdentifier)] == YES
#define __GK_USES_IDENTIFIER ([[GKLeaderboard alloc] respondsToSelector:@selector(identifier)])

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
    GCMErrorFeatureNotAvailable = 3,
    GCMErrorInternetNotAvailable = 4,
    GCMErrorAchievementDataMissing = 5
};
typedef NSInteger GCMErrorCode;


@protocol GameCenterManagerDelegate;
@interface GameCenterManager : NSObject {
    NSMutableArray *_leaderboards;
    UIBackgroundTaskIdentifier backgroundProcess;
}

// Sets up the Delegate
@property (nonatomic, weak) id <GameCenterManagerDelegate> delegate;

// Returns the shared instance of GameCenterManager.
+ (GameCenterManager *)sharedManager;



/// Initializes Game Center Manager. Should be called at app launch.
- (void)initGameCenter;

/// Synchronizes local player data with Game Center data.
- (void)syncGameCenter;



/// Saves score locally and reports it to Game Center. If error occurs, score is saved to be submitted later.
- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order;

/// Saves achievement locally and reports it to Game Center. If error occurs, achievement is saved to be submitted later.
- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete shouldDisplayNotification:(BOOL)displayNotification;



/// Reports scores and achievements which could not be reported earlier.
- (void)reportSavedScoresAndAchievements;

/// Saves score to be submitted later.
- (void)saveScoreToReportLater:(GKScore *)score;

/// Saves achievement to be submitted later.
- (void)saveAchievementToReportLater:(NSString *)identifier percentComplete:(double)percentComplete;



/// Returns local player's high score for specified leaderboard.
- (int)highScoreForLeaderboard:(NSString *)identifier;

/// Returns local player's high scores for multiple leaderboards.
- (NSDictionary *)highScoreForLeaderboards:(NSArray *)identifiers;



/// Returns local player's percent completed for specified achievement.
- (double)progressForAchievement:(NSString *)identifier;

/// Returns local player's percent completed for multiple achievements.
- (NSDictionary *)progressForAchievements:(NSArray *)identifiers;



/** Gets a list of challenges for the current player and game. If GameCenter is not available it will return nil and provide an error using the gameCenterManager:error: delegate method. Use the completion handler to get challenges.
 @param handler Completion handler with an NSArray containing challenges and an NSError. The NSError object will be nil if there is no error.
 */
- (void)getChallengesWithCompletion:(void (^)(NSArray *challenges, NSError *error))handler;



/// Resets local player's achievements
- (void)resetAchievementsWithCompletion:(void (^)(NSError *error))handler;



/// Returns currently authenticated local player ID. If no player is authenticated, "unknownPlayer" is returned.
- (NSString *)localPlayerId;

/// Returns currently authenticated local player's display name (alias or actual name depending on friendship). If no player is authenticated, "unknownPlayer" is returned. Player Alias will be returned if the Display Name property is not available
- (NSString *)localPlayerDisplayName;

/// Returns currently authenticated local player and all associated data. If no player is authenticated, `nil` is returned.
- (GKLocalPlayer *)localPlayerData;

/// Fetches a UIImage with the local player's profile picture at full resolution. The completion handler passes a UIImage object when the image is downloaded from the GameCenter Servers
- (void)localPlayerPhoto:(void (^)(UIImage *playerPhoto))handler;



/// Returns YES if an active internet connection is available.
- (BOOL)isInternetAvailable;

/// Check if GameCenter is supported
- (BOOL)checkGameCenterAvailability;

/// Use this property to check if Game Center is available and supported on the current device.
@property (nonatomic, assign) BOOL isGameCenterAvailable;


@end


/// GameCenterManager Delegate
@protocol GameCenterManagerDelegate <NSObject>

@required
/// Required Delegate Method called when the user needs to be authenticated using the GameCenter Login View Controller
- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController;

@optional
/// Delegate Method called when the availability of GameCenter changes
- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation;
/// Delegate Method called when the there is an error with GameCenter or GC Manager
- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error;

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation;
- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation;
- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score;
- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation;

- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error __deprecated;
@end



