//
//  NotificationManager.m
//
//  Created by Nihal Ahmed on 12-03-16.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "GameCenterManager.h"


#pragma mark - Game Center Manager Singleton

@implementation GameCenterManager

@synthesize isGameCenterAvailable;

static GameCenterManager *defaultManager = nil;

+ (GameCenterManager *)defaultManager {
    if(defaultManager == nil) {
        defaultManager = [[super allocWithZone:NULL] init];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kGameCenterPreferencePath]) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:0];
            [dict writeToFile:kGameCenterPreferencePath atomically:YES];
            [dict release];
        }
    }
    return defaultManager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self defaultManager] retain];
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
    if([[GameCenterManager defaultManager] isGameCenterAPIAvailable]) {
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {        
            if(error == nil) {
                [[GameCenterManager defaultManager] setIsGameCenterAvailable:YES];
                if(![[NSUserDefaults standardUserDefaults] boolForKey:@"scoresSynced"] ||
                   ![[NSUserDefaults standardUserDefaults] boolForKey:@"achievementsSynced"]) {
                    [[GameCenterManager defaultManager] syncGameCenter];
                }
                else {
                    [[GameCenterManager defaultManager] reportSavedScoresAndAchievements];
                }
            }
            else {
                [[GameCenterManager defaultManager] setIsGameCenterAvailable:NO];
            }
        }];
    }
}

- (void)syncGameCenter {
    NSLog(@"syncGameCenter called");
    
    if([[GameCenterManager defaultManager] isInternetAvailable]) {
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"scoresSynced"]) {
            GKLeaderboard *leaderboardRequest = [[[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[[GameCenterManager defaultManager] localPlayerId]]] autorelease];
            [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error){
                if(error == nil) {
                    if([scores count] > 0) {
                        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
                        NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager defaultManager] localPlayerId]];
                        if(playerDict == nil) {
                            playerDict = [NSMutableDictionary dictionary];
                        }
                        for(GKScore *score in scores) {
                            NSLog(@"%@, %lld", score.category, score.value);
                            
                            int savedHighScoreValue = 0;
                            NSNumber *savedHighScore = [playerDict objectForKey:score.category];
                            if(savedHighScore != nil) {
                                savedHighScoreValue = [savedHighScore intValue];
                            }
                            [playerDict setObject:[NSNumber numberWithInt:MAX(score.value, savedHighScoreValue)] forKey:score.category];
                        }
                        [plistDict setObject:playerDict forKey:[[GameCenterManager defaultManager] localPlayerId]];
                        [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
                        [plistDict release];                    
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"scoresSynced"];
                    [[GameCenterManager defaultManager] syncGameCenter];
                }
            }];
        }
        else if(![[NSUserDefaults standardUserDefaults] boolForKey:@"achievementsSynced"]) {
            [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                if(error == nil) {
                    if([achievements count] > 0) {
                        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
                        NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager defaultManager] localPlayerId]];
                        if(playerDict == nil) {
                            playerDict = [NSMutableDictionary dictionary];
                        }
                        for(GKAchievement *achievement in achievements) {
                            NSLog(@"%@, %f", achievement.identifier, achievement.percentComplete);
                            
                            if(achievement.completed) {
                                [playerDict setObject:[NSNumber numberWithBool:YES] forKey:achievement.identifier];
                            }
                        }
                        [plistDict setObject:playerDict forKey:[[GameCenterManager defaultManager] localPlayerId]];
                        [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
                        [plistDict release];                    
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"achievementsSynced"];
                    [[GameCenterManager defaultManager] syncGameCenter];
                }
            }];
        }
    }
}

- (void)reportScore:(int)score leaderboard:(NSString *)identifier {
    if([[GameCenterManager defaultManager] isGameCenterAvailable]) {
        if([GKLocalPlayer localPlayer].authenticated) {
            if([[GameCenterManager defaultManager] isInternetAvailable]) {
                GKScore *gkScore = [[[GKScore alloc] initWithCategory:identifier] autorelease];
                gkScore.value = score;
                [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    }
                    else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager defaultManager] saveScore:gkScore];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterReportScoreNotification
                                                                        object:self
                                                                      userInfo:dict];
                }];
            }
            else {
                GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
                [[GameCenterManager defaultManager] saveScore:gkScore];
                [gkScore release];
            }
        }
    }
}

- (void)reportAchievement:(NSString *)identifier percentComplete:(double)percentComplete {
    if([[GameCenterManager defaultManager] isGameCenterAvailable]) {
        if([GKLocalPlayer localPlayer].authenticated) {
            if([[GameCenterManager defaultManager] isInternetAvailable]) {
                GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
                achievement.percentComplete = percentComplete;
                [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                    NSDictionary *dict = nil;
                    if(error == nil) {
                        dict = [NSDictionary dictionary];
                    }
                    else {
                        dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
                        [[GameCenterManager defaultManager] saveAchievement:identifier percentComplete:percentComplete];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterReportAchievementNotification
                                                                        object:self
                                                                      userInfo:dict];
                }];
            }
            else {
                [[GameCenterManager defaultManager] saveAchievement:identifier percentComplete:percentComplete];
            }
        }
    }
}

- (void)saveScore:(GKScore *)score {
    NSData *scoreData = [NSKeyedArchiver archivedDataWithRootObject:score];
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
    NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
    if(savedScores != nil) {
        [savedScores addObject:scoreData];
    }
    else {
        savedScores = [NSArray arrayWithObject:scoreData];
    }
    [plistDict setObject:savedScores forKey:@"SavedScores"];
    [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
    [plistDict release];
    
    NSLog(@"Saved score to report later");
}

- (void)saveAchievement:(NSString *)identifier percentComplete:(double)percentComplete {
    NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager defaultManager] localPlayerId]];
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
            savedAchievements = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
            [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
        }
    }
    else {
        NSDictionary *savedAchievements = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
        playerDict = [NSDictionary dictionaryWithObjectsAndKeys:savedAchievements, @"SavedAchievements", nil];                    
    }
    [plistDict setObject:playerDict forKey:[[GameCenterManager defaultManager] localPlayerId]];
    [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
    [plistDict release];
    
    NSLog(@"Saved achievement to report later");
}

- (void)reportSavedScoresAndAchievements {
    NSLog(@"reportSavedScoresAndAchievements called");
    
    if([[GameCenterManager defaultManager] isInternetAvailable]) {
        GKScore *gkScore = nil;
        
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
        NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
        if(savedScores != nil) {
            if([savedScores count] > 0) {
                gkScore = [NSKeyedUnarchiver unarchiveObjectWithData:[savedScores objectAtIndex:0]];
                [savedScores removeObjectAtIndex:0];
                [plistDict setObject:savedScores forKey:@"SavedScores"];
                [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
            }
        }
        [plistDict release];
        
        if(gkScore != nil) {
            NSLog(@"Reporting saved score");
            
            [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                if(error == nil) {
                    NSLog(@"Saved score reported");
                    
                    [[GameCenterManager defaultManager] reportSavedScoresAndAchievements];
                }
                else {
                    [[GameCenterManager defaultManager] saveScore:gkScore];
                    
                    NSLog(@"Saved score saved again to report later");
                }
            }];
        }
        else {
            if([GKLocalPlayer localPlayer].authenticated) {
                NSString *identifier = nil;
                double percentComplete = 0;
                
                NSMutableDictionary *plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:kGameCenterPreferencePath];
                NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager defaultManager] localPlayerId]];
                if(playerDict != nil) {
                    NSMutableDictionary *savedAchievements = [playerDict objectForKey:@"SavedAchievements"];
                    if(savedAchievements != nil) {
                        if([savedAchievements count] > 0) {
                            identifier = [[savedAchievements allKeys] objectAtIndex:0];
                            percentComplete = [[savedAchievements objectForKey:identifier] doubleValue];
                            [savedAchievements removeObjectForKey:identifier];
                            [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
                            [plistDict setObject:playerDict forKey:[[GameCenterManager defaultManager] localPlayerId]];
                            [plistDict writeToFile:kGameCenterPreferencePath atomically:YES];
                        }
                    }
                }
                [plistDict release];
                
                if(identifier != nil) {
                    NSLog(@"Reporting saved achievement");
                    
                    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
                    achievement.percentComplete = percentComplete;
                    [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                        if(error == nil) {
                            NSLog(@"Saved achievement reported");
                            
                            [[GameCenterManager defaultManager] reportSavedScoresAndAchievements];
                        }
                        else {
                            [[GameCenterManager defaultManager] saveAchievement:achievement.identifier percentComplete:achievement.percentComplete]; 
                            
                            NSLog(@"Saved achievement saved again to report later");
                        }
                    }];
                }
            }
        }
    }
}

- (void)resetAchievements {
    if([[GameCenterManager defaultManager] isGameCenterAvailable]) {
        [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            if(error == nil) {
                dict = [NSDictionary dictionary];
            }
            else {
                dict = [NSDictionary dictionaryWithObject:error.localizedDescription forKey:@"error"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kGameCenterResetAchievementNotification
                                                                object:self
                                                              userInfo:dict];
        }];
    }
}

- (NSString *)localPlayerId {
    if([[GameCenterManager defaultManager] isGameCenterAvailable]) {
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

- (BOOL)isGameCenterAPIAvailable {
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (localPlayerClassAvailable && osVersionSupported);
}

@end