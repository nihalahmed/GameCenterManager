//
//  GameCenterManager.h
//
//  Created by Nihal Ahmed on 12-03-16. Updated by iRare Media on 7/2/13.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

// GameCenterManager uses ARC, check for compatibility before building
#if !__has_feature(objc_arc)
    #error GameCenterManager uses Objective-C ARC. Compile these files with ARC enabled. Add the -fobjc-arc compiler flag to enable ARC for only these files.
#endif

// As of version 5.3, GameCenterManager only runs on iOS 7.0+ and OS X 10.9+, check for compatibility before building. See the GitHub Releases page (https://github.com/nihalahmed/GameCenterManager/releases) for older versions which work with iOS 4.1 and higher and OS X 10.8 and higher. The last supported version for iOS < 7.0 is version 5.2. The last supported version for OS X < 10.9 is also version 5.2.
#if TARGET_OS_IPHONE
    #ifndef __IPHONE_7_0
        #warning GameCenterManager uses features only available in iOS SDK 7.0 and later. Running on an older version of iOS may result in a crash. Download an older release from GitHub for compatibility with iOS SDK < 7.0
    #endif
#else
    #ifndef __MAC_10_9
        #warning GameCenterManager uses features only available in OS X SDK 10.9 and later. Running on an older version of OS X may result in a crash. Download an older release from GitHub for compatibility with OS X SDK < 10.9
    #endif
#endif

#define LIBRARY_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
#define kGameCenterManagerDataFile @"GameCenterManager.plist"
#define kGameCenterManagerDataPath [LIBRARY_FOLDER stringByAppendingPathComponent:kGameCenterManagerDataFile]

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

#import "Reachability.h"
#import "NSDataAES256.h"




/// Leaderboard sort order. Use this value when submitting new leaderboard scores. This value should match the value set in iTunes Connect for the speicifed leaderboard.
typedef enum GameCenterSortOrder {
    /// Scores are sorted highest to lowest. Higher scores are on the top of the leaderboard
    GameCenterSortOrderHighToLow,
    /// Scores are sorted lowest to highest. Lower scores are on the top of the leaderboard
    GameCenterSortOrderLowToHigh
} GameCenterSortOrder;

enum {
    /// An unknown error occurred
    GCMErrorUnknown = 1,
    /// GameCenterManager is unavailable, possibly for a variety of reasons
    GCMErrorNotAvailable = 2,
    /// The requested feature is unavailable on the current device or iOS version
    GCMErrorFeatureNotAvailable = 3,
    /// There is no active internet connection for the requested operation
    GCMErrorInternetNotAvailable = 4,
    /// The achievement data submitted was not valid because there were missing parameters
    GCMErrorAchievementDataMissing = 5
};
/// GameCenterManager error codes that may be passed in a completion handler's error parameter
typedef NSInteger GCMErrorCode;




/// GameCenter Manager helps to manage Game Center in iOS and Mac apps. Report and keep track of high scores, achievements, and challenges for different players. GameCenter Manager also takes care of the heavy lifting - checking internet availability, saving data when offline and uploading it when online, etc.
@class GameCenterManager;
@protocol GameCenterManagerDelegate;
@interface GameCenterManager : NSObject <GKGameCenterControllerDelegate>




/// Returns the shared instance of GameCenterManager.
+ (GameCenterManager *)sharedManager;

/// GameCenterManager delegate property that can be used to set the delegate
@property (nonatomic, weak) id <GameCenterManagerDelegate> delegate;




/** DEPRECTAED. Use \p setupManagerAndSetShouldCryptWithKey: instead.
    @discussion Initializes GameCenterManager. Should be called at app launch. */
- (void)initGameCenter __deprecated;

/** Initializes GameCenterManager. Should be called at app launch. Locally saved scores and achievements will be encrypted with the specified keyword when saved.
 
 @discussion This is more secure, but it may be slower. When submitting an app to the AppStore with GCManager Encryption, you may need to register for US Export Compliance. */
- (void)setupManagerAndSetShouldCryptWithKey:(NSString *)cryptKey;

/** Initializes GameCenterManager. Should be called at app launch. Locally saved scores and achievements will not be encrypted when saved.
 
 @discussion This is less secure, but it may be faster. When submitting an app to the AppStore without using GCManager Encryption, you will not have to register for US Export Compliance (unless other parts of your app require it). */
- (void)setupManager;

/// Synchronizes local player data with Game Center data.
- (void)syncGameCenter;




/** Saves score locally and reports it to Game Center. If error occurs, score is saved to be submitted later. 
 
 @param score The int value of the score to be submitted to Game Center. This score should not be formatted, instead it should be a plain int. For example, if you wanted to submit a score of 45.28 meters then you would submit it as an integer of 4528. To format your scores, you must set the Score Formatter for your leaderboard in iTunes Connect.
 @param identifier The Leaderboard ID set through iTunes Connect. This is different from the name of the leaderboard, and it is not shown to the user. 
 @param order The score sort order that you set in iTunes Connect - either high to low or low to high. This is used to determine if the user has a new highscore before submitting. */
- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order __attribute__((nonnull));

/** Saves achievement locally and reports it to Game Center. If error occurs, achievement is saved to be submitted later.
 
 @param identifier The Achievement ID set through iTunes Connect. This is different from the name of the achievement, and it is not shown to the user.
 @param percentComplete A percentage value that states how far the player has progressed on this achievement. The range of legal values is between 0.0 and 100.0. Submitting 100.0 will mark the achievement as completed. Submitting a percent which is lower than what the user has already achieved will be ignored - the user's achievement progress cannot go down.
 @param displayNotification YES if GCManager should display a Game Center Achievement banner. NO if no banner should be displayed */
- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete shouldDisplayNotification:(BOOL)displayNotification __attribute__((nonnull));




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
 @param handler Completion handler with an NSArray containing challenges and an NSError. The NSError object will be nil if there is no error. */
- (void)getChallengesWithCompletion:(void (^)(NSArray *challenges, NSError *error))handler __attribute__((nonnull));




/// Presents the GameCenter Achievements ViewController over the specified ViewController. Dismissal and delegation is handled by GameCenterManager.
- (void)presentAchievementsOnViewController:(UIViewController *)viewController;

/// Presents the GameCenter Leaderboards ViewController over the specified ViewController. Dismissal and delegation is handled by GameCenterManager.
- (void)presentLeaderboardsOnViewController:(UIViewController *)viewController;

/// Presents the GameCenter Challenges ViewController over the specified ViewController. Dismissal and delegation is handled by GameCenterManager.
- (void)presentChallengesOnViewController:(UIViewController *)viewController;




#if TARGET_OS_IPHONE
/// Resets all of the local player's achievements and progress for the current game
- (void)resetAchievementsWithCompletion:(void (^)(NSError *error))handler __attribute__((nonnull));
#else
/// Resets all of the local player's achievements and progress for the current game
- (void)resetAchievementsWithCompletion:(void (^)(NSError *error))handler __attribute__((nonnull));

/// DEPRECATED. Use resetAchievementsWithCompletion: instead.
- (void)resetAchievements __deprecated __unavailable;
#endif




/// Returns currently authenticated local player ID. If no player is authenticated, "unknownPlayer" is returned.
- (NSString *)localPlayerId;

/// Returns currently authenticated local player's display name (alias or actual name depending on friendship). If no player is authenticated, "unknownPlayer" is returned. Player Alias will be returned if the Display Name property is not available
- (NSString *)localPlayerDisplayName;

/// Returns currently authenticated local player and all associated data. If no player is authenticated, `nil` is returned.
- (GKLocalPlayer *)localPlayerData;

#if TARGET_OS_IPHONE
/// Fetches a UIImage with the local player's profile picture at full resolution. The completion handler passes a UIImage object when the image is downloaded from the GameCenter Servers
- (void)localPlayerPhoto:(void (^)(UIImage *playerPhoto))handler __attribute__((nonnull)) __OSX_AVAILABLE_STARTING(__OSX_10_8,__IPHONE_5_0);
#else
/// Fetches an NSImage with the local player's profile picture at full resolution. The completion handler passes an NSImage object when the image is downloaded from the GameCenter Servers
- (void)localPlayerPhoto:(void (^)(NSImage *playerPhoto))handler __attribute__((nonnull));
#endif




/// Returns YES if an active internet connection is available.
- (BOOL)isInternetAvailable;

/// Check if Game Center is supported
- (BOOL)checkGameCenterAvailability;

/// Use this property to check if Game Center is available and supported on the current device.
@property (nonatomic, assign) BOOL isGameCenterAvailable;

/// @b Readonly. Indicates whether or not locally saved scores and achievements should be encrypted. To turn ON this feature, initialize GameCenterManager using the \p setupManagerAndSetShouldCryptWithKey: method (instead of just \p setupManager)
@property (nonatomic, assign, readonly) BOOL shouldCryptData;

/// @b Readonly. The key used to encrypt and decrypt locally saved scores and achievements. To set the key, setup GameCenterManager using the \p setupManagerAndSetShouldCryptWithKey: method
@property (nonatomic, strong, readonly) NSString *cryptKey;




@end


/// GameCenterManager Delegate. Used for deeper control of the GameCenterManager class - allows for notification subscription, error reporting, and availability handling.
@protocol GameCenterManagerDelegate <NSObject>

#if TARGET_OS_IPHONE
@required
/// Required Delegate Method called when the user needs to be authenticated using the GameCenter Login View Controller
- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController;
#endif

@optional
/// Delegate Method called when the availability of GameCenter changes
- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation;

/// Delegate Method called when the there is an error with GameCenter or GC Manager
- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error;

/// Sent to the delegate when a score is reported to GameCenter
- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(GKScore *)score withError:(NSError *)error;
/// Sent to the delegate when an achievement is reported to GameCenter
- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(GKAchievement *)achievement withError:(NSError *)error;

/// Sent to the delegate when an achievement is saved locally
- (void)gameCenterManager:(GameCenterManager *)manager didSaveAchievement:(GKAchievement *)achievement;
/// Sent to the delegate when a score is saved locally
- (void)gameCenterManager:(GameCenterManager *)manager didSaveScore:(GKScore *)score;


//----------------------------------//
//-- Deprecated Delegate Methods ---//
//----------------------------------//

/// DEPRECATED. Use gameCenterManager: didSaveScore: instead.
- (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score __deprecated;

/// DEPRECATED. Use gameCenterManager: didSaveAchievement: instead.
- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation __deprecated;

/// DEPRECATED. Use gameCenterManager: reportedScore: withError: instead.
- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation __deprecated;

/// DEPRECATED. Use gameCenterManager: reportedAchievement: withError: instead.
- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation __deprecated;

/// DEPRECATED. UNAVAILABLE. Use the completion handler on resetAchievementsWithCompletion:
- (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error __deprecated __unavailable;

@end


