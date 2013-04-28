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
    return [self sharedManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;    
}

#pragma mark - Methods

- (void)initGameCenter {
    //Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    //Check for existance of GameKit. The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    BOOL isGameCenterAPIAvailable = (localPlayerClassAvailable && osVersionSupported);
    
    //Check for existance of GameKit
    if(isGameCenterAPIAvailable) {
        //Set GameCenter as available
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:YES];
        
        //Check if the local player is authenticated
        [[GKLocalPlayer localPlayer] setAuthenticateHandler:^(UIViewController *view, NSError *error) {
            if (error == nil) {
                if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]] ||
                   ![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
                    [[GameCenterManager sharedManager] syncGameCenter];
                } else {
                    [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                }
            } else {
                if (error.code == GKErrorNotSupported) {
                    [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                } else {
                    [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                    NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error forKey:@"error"];
                    NSLog(@"%@", error);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification object:[GameCenterManager sharedManager] userInfo:errorDictionary];
                }
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerAvailabilityNotification
                                                                object:[GameCenterManager sharedManager] userInfo:[NSDictionary dictionary]];
        }];
        
        if (![GKLocalPlayer localPlayer].authenticated) {
            [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
            NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:@"GKErrorNotAuthenticated, the local player has not been authenticated." forKey:@"error"];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification object:[GameCenterManager sharedManager] userInfo:errorDictionary];
        } else {
            NSLog(@"Player Authenticated");
        }
        
    } else {
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
    }
}

- (void)syncGameCenter {
    if([[GameCenterManager sharedManager] isInternetAvailable]) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
            if(_leaderboards == nil) {
                [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                    if(error == nil) {
                        _leaderboards = [[NSMutableArray alloc] initWithArray:leaderboards];
                        [[GameCenterManager sharedManager] syncGameCenter];
                    } else {
                        [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                        NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error forKey:@"error"];
                        NSLog(@"%@", error);
                        [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification object:[GameCenterManager sharedManager] userInfo:errorDictionary];
                    }
                }];
                return;
            }
            
            if(_leaderboards.count > 0) {
                GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[[GameCenterManager sharedManager] localPlayerId]]];
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
                    } else {
                        [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                        NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error forKey:@"error"];
                        NSLog(@"%@", error);
                        [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification object:[GameCenterManager sharedManager] userInfo:errorDictionary];
                    }
                }];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                [[GameCenterManager sharedManager] syncGameCenter];
            }
        } else if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
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
                } else {
                    [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
                    NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:error forKey:@"error"];
                    NSLog(@"%@", error);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification object:[GameCenterManager sharedManager] userInfo:errorDictionary];
                }
            }];
        }
    } else {
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
        NSDictionary *errorDictionary = [NSDictionary dictionaryWithObject:@"Internet unavailable. Could not connect to the internet." forKey:@"error"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerErrorNotification
                                                            object:[GameCenterManager sharedManager]
                                                          userInfo:errorDictionary];
    }
}

//Save score and report it to GameCenter
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
                GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
                gkScore.value = score;
                [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    } else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerReportScoreNotification
                                                                        object:[GameCenterManager sharedManager] userInfo:dict];
                }];
            }
            else {
                GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
                [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
            }
        }
    }
}

//Save achievement and report it to GameCenter
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
                GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
                achievement.percentComplete = percentComplete;
                [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    } else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerReportAchievementNotification
                                                                        object:[GameCenterManager sharedManager]
                                                                      userInfo:dict];
                }];
            } else {
                [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
            }
        }
    }
}

//Save score to report later
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

//Get leaderboard high scores
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
    
    return highScoreDict;
}

//Get achievement progress
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

//Returns local player's percent completed for multiple achievements.
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
    
    return percentDict;
}

//Returns local player's challenges for this game
- (NSArray *)getChallenges {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        __block NSArray *challengesList = nil;
        [GKChallenge loadReceivedChallengesWithCompletionHandler:^(NSArray *challenges, NSError *error) {
            if (error == nil) {
                challengesList = [NSArray arrayWithArray:challenges];
            } else {
                challengesList = [NSArray arrayWithObject:error];
            }
        }];
        return challengesList;
    } else {
        return nil;
    }
}

//Report data when the internet is available again
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
                    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
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

//Reset all achievements and progress
- (void)resetAchievements {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            if(error == nil) {
                dict = [NSDictionary dictionary];
            } else {
                dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterManagerResetAchievementNotification
                                                                object:[GameCenterManager sharedManager]
                                                              userInfo:dict];
        }];
    }
}

//Checks if player is authenticated and gets his / her ID
- (NSString *)localPlayerId {
    if([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if ([GKLocalPlayer localPlayer].authenticated) {
            return [GKLocalPlayer localPlayer].playerID;
        }
    }
    return @"unknownPlayer";
}

//Check for internet with Reachability
- (BOOL)isInternetAvailable {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];    
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    if (internetStatus != NotReachable) {
        return YES;
    }
    return NO;
}

@end