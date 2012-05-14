//
//  GameCenterManager.m
//
//  Created by Nihal Ahmed on 12-03-16.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "GameCenterManager.h"


#pragma mark - Game Center Manager Singleton

@implementation GameCenterManager

@synthesize isGameCenterAvailable;

static GameCenterManager *sharedManager = nil;

+ (GameCenterManager *)sharedManager {
    if(sharedManager == nil) {
        sharedManager = [[super allocWithZone:NULL] init];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kGameCenterManagerDataPath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict] encryptedWithKey:kGameCenterManagerKey];
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
    }
    
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    if(gameCenterManagerData == nil) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict] encryptedWithKey:kGameCenterManagerKey];
        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    }
    
    return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;    
}

- (id)retain {
    return self;    
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (oneway void)release {
}

- (id)autorelease {
    return self;
}

#pragma mark - Methods

- (void)initGameCenter {
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    BOOL isGameCenterAPIAvailable = (localPlayerClassAvailable && osVersionSupported);
    
    if(isGameCenterAPIAvailable) {
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:YES];
        
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {        
            if(error == nil) {
                if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]] ||
                   ![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
                    [[GameCenterManager sharedManager] syncGameCenter];
                }
                else {
                    [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                }
            }
            else {
                if(error.code == GKErrorNotSupported) {
                    [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerAvailabilityNotification
                                                                object:[GameCenterManager sharedManager]
                                                              userInfo:[NSDictionary dictionary]];
        }];
    }
}

- (void)syncGameCenter {
    if([[GameCenterManager sharedManager] isInternetAvailable]) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
            if(_leaderboards == nil) {
                [GKLeaderboard loadCategoriesWithCompletionHandler:^(NSArray *categories, NSArray *titles, NSError *error) {
                    if(error == nil) {
                        _leaderboards = [[NSMutableArray alloc] initWithArray:categories];
                        [[GameCenterManager sharedManager] syncGameCenter];
                    }
                }];
                return;
            }
            
            if(_leaderboards.count > 0) {
                GKLeaderboard *leaderboardRequest = [[[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[[GameCenterManager sharedManager] localPlayerId]]] autorelease];
                [leaderboardRequest setCategory:[_leaderboards objectAtIndex:0]];
                [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                    if(error == nil) {
                        if(scores.count > 0) {
                            NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                            NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                            if(playerDict == nil) {
                                playerDict = [NSMutableDictionary dictionary];
                            }
                            int savedHighScoreValue = 0;
                            NSNumber *savedHighScore = [playerDict objectForKey:leaderboardRequest.localPlayerScore.category];
                            if(savedHighScore != nil) {
                                savedHighScoreValue = [savedHighScore intValue];
                            }
                            [playerDict setObject:[NSNumber numberWithInt:MAX(leaderboardRequest.localPlayerScore.value, savedHighScoreValue)] forKey:leaderboardRequest.localPlayerScore.category];
                            [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                        }
                        
                        [_leaderboards removeObjectAtIndex:0];
                        [[GameCenterManager sharedManager] syncGameCenter];
                    }
                }];
            }
            else {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                [[GameCenterManager sharedManager] syncGameCenter];
            }
        }
        else if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
            [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                if(error == nil) {
                    if(achievements.count > 0) {
                        NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                        NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                        NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                        if(playerDict == nil) {
                            playerDict = [NSMutableDictionary dictionary];
                        }
                        for(GKAchievement *achievement in achievements) {
                            [playerDict setObject:[NSNumber numberWithDouble:achievement.percentComplete] forKey:achievement.identifier];
                        }
                        [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                    [[GameCenterManager sharedManager] syncGameCenter];
                }
            }];
        }
    }
}

- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    if(playerDict == nil) {
        playerDict = [NSMutableDictionary dictionary];
    }
    NSNumber *savedHighScore = [playerDict objectForKey:identifier];
    if(savedHighScore == nil) {
        savedHighScore = [NSNumber numberWithInt:0];
    }
    int savedHighScoreValue = [savedHighScore intValue];
    if(score > savedHighScoreValue) {
        [playerDict setObject:[NSNumber numberWithInt:score] forKey:identifier];
        [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    }
    
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if([GKLocalPlayer localPlayer].authenticated) {
            if([[GameCenterManager sharedManager] isInternetAvailable]) {
                GKScore *gkScore = [[[GKScore alloc] initWithCategory:identifier] autorelease];
                gkScore.value = score;
                [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    }
                    else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerReportScoreNotification
                                                                        object:[GameCenterManager sharedManager]
                                                                      userInfo:dict];
                }];
            }
            else {
                GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
                [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
                [gkScore release];
            }
        }
    }
}

- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    if(playerDict == nil) {
        playerDict = [NSMutableDictionary dictionary];
    }
    NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
    if(savedPercentComplete == nil) {
        savedPercentComplete = [NSNumber numberWithDouble:0];
    }
    double savedPercentCompleteValue = [savedPercentComplete doubleValue];
    if(percentComplete > savedPercentCompleteValue) {
        [playerDict setObject:[NSNumber numberWithDouble:percentComplete] forKey:identifier];
        [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    }
    
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if([GKLocalPlayer localPlayer].authenticated) {
            if([[GameCenterManager sharedManager] isInternetAvailable]) {
                GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
                achievement.percentComplete = percentComplete;
                [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    }
                    else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerReportAchievementNotification
                                                                        object:[GameCenterManager sharedManager]
                                                                      userInfo:dict];
                }];
            }
            else {
                [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
            }
        }
    }
}

- (void)saveScoreToReportLater:(GKScore *)score {
    NSData *scoreData = [NSKeyedArchiver archivedDataWithRootObject:score];
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
    if(savedScores != nil) {
        [savedScores addObject:scoreData];
    }
    else {
        savedScores = [NSMutableArray arrayWithObject:scoreData];
    }
    [plistDict setObject:savedScores forKey:@"SavedScores"];
    NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
}

- (void)saveAchievementToReportLater:(NSString *)identifier percentComplete:(double)percentComplete {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    if(playerDict != nil) {
        NSMutableDictionary *savedAchievements = [playerDict objectForKey:@"SavedAchievements"];
        if(savedAchievements != nil) {
            double savedPercentCompleteValue = 0;
            NSNumber *savedPercentComplete = [savedAchievements objectForKey:identifier];
            if(savedPercentComplete != nil) {
                savedPercentCompleteValue = [savedPercentComplete doubleValue];
            }
            savedPercentComplete = [NSNumber numberWithDouble:percentComplete + savedPercentCompleteValue];
            [savedAchievements setObject:savedPercentComplete forKey:identifier];
        }
        else {
            savedAchievements = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
            [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
        }
    }
    else {
        NSMutableDictionary *savedAchievements = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
        playerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:savedAchievements, @"SavedAchievements", nil];                    
    }
    [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];    
}

- (int)highScoreForLeaderboard:(NSString *)identifier {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    if(playerDict != nil) {
        NSNumber *savedHighScore = [playerDict objectForKey:identifier];
        if(savedHighScore != nil) {
            return [savedHighScore intValue];
        }
    }
    return 0;
}

- (NSDictionary *)highScoreForLeaderboards:(NSArray *)identifiers {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSMutableDictionary *highScores = [[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
    for(NSString *identifier in identifiers) {
        if(playerDict != nil) {
            NSNumber *savedHighScore = [playerDict objectForKey:identifier];
            if(savedHighScore != nil) {
                [highScores setObject:[NSNumber numberWithInt:[savedHighScore intValue]] forKey:identifier];
                continue;
            }
        }
        [highScores setObject:[NSNumber numberWithInt:0] forKey:identifier];
    }
    
    NSDictionary *highScoreDict = [NSDictionary dictionaryWithDictionary:highScores];
    [highScores release];
    
    return highScoreDict;
}

- (double)progressForAchievement:(NSString *)identifier {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    if(playerDict != nil) {
        NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
        if(savedPercentComplete != nil) {
            return [savedPercentComplete doubleValue];
        }
    }
    return 0;
}

- (NSDictionary *)progressForAchievements:(NSArray *)identifiers {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSMutableDictionary *percent = [[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
    for(NSString *identifier in identifiers) {
        if(playerDict != nil) {
            NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
            if(savedPercentComplete != nil) {
                [percent setObject:[NSNumber numberWithDouble:[savedPercentComplete doubleValue]] forKey:identifier];
                continue;
            }
        }
        [percent setObject:[NSNumber numberWithDouble:0] forKey:identifier];
    }
    
    NSDictionary *percentDict = [NSDictionary dictionaryWithDictionary:percent];
    [percent release];
    
    return percentDict;
}

- (void)reportSavedScoresAndAchievements {    
    if([[GameCenterManager sharedManager] isInternetAvailable]) {
        GKScore *gkScore = nil;
        
        NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
        NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
        NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
        if(savedScores != nil) {
            if(savedScores.count > 0) {
                gkScore = [NSKeyedUnarchiver unarchiveObjectWithData:[savedScores objectAtIndex:0]];
                [savedScores removeObjectAtIndex:0];
                [plistDict setObject:savedScores forKey:@"SavedScores"];
                NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
            }
        }
        
        if(gkScore != nil) {            
            [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                if(error == nil) {                    
                    [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                }
                else {
                    [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
                }
            }];
        }
        else {
            if([GKLocalPlayer localPlayer].authenticated) {
                NSString *identifier = nil;
                double percentComplete = 0;
                
                NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                if(playerDict != nil) {
                    NSMutableDictionary *savedAchievements = [playerDict objectForKey:@"SavedAchievements"];
                    if(savedAchievements != nil) {
                        if(savedAchievements.count > 0) {
                            identifier = [[savedAchievements allKeys] objectAtIndex:0];
                            percentComplete = [[savedAchievements objectForKey:identifier] doubleValue];
                            [savedAchievements removeObjectForKey:identifier];
                            [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
                            [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                        }
                    }
                }
                
                if(identifier != nil) {
                    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
                    achievement.percentComplete = percentComplete;
                    [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                        if(error == nil) {
                            [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                        }
                        else {
                            [[GameCenterManager sharedManager] saveAchievementToReportLater:achievement.identifier percentComplete:achievement.percentComplete]; 
                        }
                    }];
                }
            }
        }
    }
}

- (void)resetAchievements {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            if(error == nil) {
                dict = [NSDictionary dictionary];
            }
            else {
                dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerResetAchievementNotification
                                                                object:[GameCenterManager sharedManager]
                                                              userInfo:dict];
        }];
    }
}

- (NSString *)localPlayerId {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if([GKLocalPlayer localPlayer].authenticated) {
            return [GKLocalPlayer localPlayer].playerID;
        }
    }
    return @"unknownPlayer";
}

- (BOOL)isInternetAvailable {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];    
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    if (internetStatus != NotReachable) {
        return YES;
    }
    return NO;
}

@end