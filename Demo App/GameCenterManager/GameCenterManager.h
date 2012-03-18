//
//  NotificationManager.h
//
//  Created by Nihal Ahmed on 12-03-16.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define kGameCenterPreferenceFile @"GameCenterManager.plist"
#define kGameCenterPreferencePath [DOCUMENTS_FOLDER stringByAppendingPathComponent:kGameCenterPreferenceFile]
#define kGameCenterReportScoreNotification @"GameCenterReportScoreNotification"
#define kGameCenterReportAchievementNotification @"GameCenterReportAchievementNotification"
#define kGameCenterResetAchievementNotification @"GameCenterResetAchievementNotification"

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Reachability.h"

@interface GameCenterManager : NSObject

+ (GameCenterManager *)defaultManager;
- (void)initGameCenter;
- (void)syncGameCenter;
- (void)reportScore:(int)score leaderboard:(NSString *)identifier;
- (void)reportAchievement:(NSString *)identifier percentComplete:(double)percentComplete;
- (void)reportSavedScoresAndAchievements;
- (void)saveScore:(GKScore *)score;
- (void)saveAchievement:(NSString *)identifier percentComplete:(double)percentComplete;
- (void)resetAchievements;
- (NSString *)localPlayerId;
- (BOOL)isInternetAvailable;
- (BOOL)isGameCenterAPIAvailable;

@property (nonatomic, assign) BOOL isGameCenterAvailable;

@end