//
//  GameCenterManager.m
//
//  Created by Nihal Ahmed on 12-03-16. Updated by iRare Media on 5-27-13.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import "GameCenterManager.h"


//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Singleton -----------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark GameCenter Manager

@implementation GameCenterManager
@synthesize isGameCenterAvailable, delegate;

static GameCenterManager *sharedManager = nil;

+ (GameCenterManager *)sharedManager {
    if (sharedManager == nil) {
        sharedManager = [[super allocWithZone:NULL] init];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:kGameCenterManagerDataPath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict] encryptedWithKey:kGameCenterManagerKey];
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
    }
    
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    if (gameCenterManagerData == nil) {
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

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Setup ---------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Manager Setup

- (void)initGameCenter {
    BOOL gameCenterAvailable = [self checkGameCenterAvailability];
    if (gameCenterAvailable) {
        //Set GameCenter as available
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:YES];
        
        if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]] ||
            ![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
            [[GameCenterManager sharedManager] syncGameCenter];
        } else {
            [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
        }
        
    } else {
        [[GameCenterManager sharedManager] setIsGameCenterAvailable:NO];
    }
}

- (BOOL)checkGameCenterAvailability {
    // First, check if the the GameKit Framework exists on the device. Return NO if it does not.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    BOOL isGameCenterAPIAvailable = (localPlayerClassAvailable && osVersionSupported);
    
    if (!isGameCenterAPIAvailable) {
        NSDictionary *errorDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"GameKit Framework not available on this device. GameKit is only available on devices with iOS 4.1 or higher. Some devices running iOS 4.1 may not have GameCenter enabled.", @"GameCenter Unavailable", nil] forKeys:[NSArray arrayWithObjects:@"message", @"title", nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
        });
        
        return NO;
        
    } else {
        // The GameKit Framework is available. Now check if an internet connection can be established
        BOOL internetAvailable = [self isInternetAvailable];
        if (!internetAvailable) {
            NSDictionary *errorDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Cannot connect to the internet. Connect to the internet to establish a connection with GameCenter. Achievements and scores will still be saved locally and then uploaded later.", @"Internet Unavailable", nil] forKeys:[NSArray arrayWithObjects:@"message", @"title", nil]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                    [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
            });
            
            return NO;
            
        } else {
            // The internet is available and the current device is connected. Now check if the player is authenticated
            GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
            localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
                if (viewController != nil) {
                    NSDictionary *errorDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Player is not yet signed into GameCenter. Please prompt the player using the authenticateUser delegate method.", @"No Player", nil] forKeys:[NSArray arrayWithObjects:@"message", @"title", nil]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                            [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                        
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:authenticateUser:)]) {
                            [[self delegate] gameCenterManager:self authenticateUser:viewController];
                        } else {
                            NSLog(@"[ERROR] %@ Fails to Respond to the required delegate method gameCenterManager:authenticateUser:. This delegate method must be properly implemented to use GC Manager", [self delegate]);
                        }
                    });
                } else if (!error) {
                    // Authentication handler completed successfully. Re-check availability
                    [self checkGameCenterAvailability];
                }
            };
            
            if (![[GKLocalPlayer localPlayer] isAuthenticated]) {
                NSDictionary *errorDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Player is not signed into GameCenter, has declined to sign into GameCenter, or GameKit had an issue validating this game / app.", @"Player not Authenticated", nil] forKeys:[NSArray arrayWithObjects:@"message", @"title", nil]];
                
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                    [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                
                return NO;
                
            } else {
                // The current player is logged into GameCenter
                NSDictionary *successDictionary = [NSDictionary dictionaryWithObject:@"GameCenter Available" forKey:@"status"];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                        [[self delegate] gameCenterManager:self availabilityChanged:successDictionary];
                });
                
                self.isGameCenterAvailable = YES;
                
                return YES;
            }
        }
    }
}

// Check for internet with Reachability
- (BOOL)isInternetAvailable {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if (internetStatus == NotReachable) {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"Internet unavailable - could not connect to the internet. Connect to WiFi or a Cellular Network to upload data to GameCenter."] code:GCMErrorInternetNotAvailable userInfo:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                [[self delegate] gameCenterManager:self error:error];
        });
        
        return NO;
    } else {
        return YES;
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Syncing ---------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Syncing

- (void)syncGameCenter {
    // Begin Syncing with GameCenter
    
    // Ensure the task isn't interrupted even if the user exits the app
    backgroundProcess = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //End the Background Process
        [[UIApplication sharedApplication] endBackgroundTask:backgroundProcess];
        backgroundProcess = UIBackgroundTaskInvalid;
    }];
    
    // Move the process to the background thread to avoid clogging up the UI
    dispatch_queue_t syncGameCenterOnBackgroundThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(syncGameCenterOnBackgroundThread, ^{
        
        // Check if GameCenter is available
        if ([[GameCenterManager sharedManager] checkGameCenterAvailability] == YES) {
            // Check if Leaderboard Scores are synced
            if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
                if (_leaderboards == nil) {
                    [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                        if (error == nil) {
                            _leaderboards = [[NSMutableArray alloc] initWithArray:leaderboards];
                            [[GameCenterManager sharedManager] syncGameCenter];
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                    [[self delegate] gameCenterManager:self error:error];
                            });
                        }
                    }];
                    return;
                }
                
                
                if (_leaderboards.count > 0) {
                    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[[GameCenterManager sharedManager] localPlayerId]]];

                    if ([[GKLeaderboard alloc] respondsToSelector:@selector(identifier)]) {
                        [leaderboardRequest setIdentifier:[(GKLeaderboard *)[_leaderboards objectAtIndex:0] identifier]];
                    } else {
                        [leaderboardRequest setCategory:[(GKLeaderboard *)[_leaderboards objectAtIndex:0] category]];
                    }
                    
                    [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                        if (error == nil) {
                            if (scores.count > 0) {
                                NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                                NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                                NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                                
                                if (playerDict == nil) {
                                    playerDict = [NSMutableDictionary dictionary];
                                }
                                
                                float savedHighScoreValue = 0;
                                NSNumber *savedHighScore = [playerDict objectForKey:leaderboardRequest.localPlayerScore.category];
                                
                                if (savedHighScore != nil) {
                                    savedHighScoreValue = [savedHighScore intValue];
                                }
                                
                                [playerDict setObject:[NSNumber numberWithInt:MAX(leaderboardRequest.localPlayerScore.value, savedHighScoreValue)] forKey:leaderboardRequest.localPlayerScore.category];
                                [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                                NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                            }
                            
                            // Seeing an NSRangeException for an empty array when trying to remove the object
                            // Despite the check above in this scope that leaderboards count is > 0
                            if (_leaderboards.count > 0) {
                                [_leaderboards removeObjectAtIndex:0];
                            }
                            
                            [[GameCenterManager sharedManager] syncGameCenter];
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                    [[self delegate] gameCenterManager:self error:error];
                            });
                        }
                    }];
                } else {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"scoresSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                    [[GameCenterManager sharedManager] syncGameCenter];
                }
                
                
                // Check if Achievements are synced
            } else if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]]) {
                [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                    if (error == nil) {
                        NSLog(@"Number of Achievements: %@", achievements);
                        if (achievements.count > 0) {
                            NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                            NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                            
                            if (playerDict == nil) {
                                playerDict = [NSMutableDictionary dictionary];
                            }
                            
                            for (GKAchievement *achievement in achievements) {
                                [playerDict setObject:[NSNumber numberWithDouble:achievement.percentComplete] forKey:achievement.identifier];
                            }
                            
                            [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                            
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                        [[GameCenterManager sharedManager] syncGameCenter];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                [[self delegate] gameCenterManager:self error:error];
                        });
                    }
                }];
            }
        } else {
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter unavailable."] code:GCMErrorNotAvailable userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                    [[self delegate] gameCenterManager:self error:error];
            });
        }
    });
    
    // End the Background Process
    [[UIApplication sharedApplication] endBackgroundTask:backgroundProcess];
    backgroundProcess = UIBackgroundTaskInvalid;
}

// Report data when the internet is available again
- (void)reportSavedScoresAndAchievements {
    if ([[GameCenterManager sharedManager] isInternetAvailable]) {
        GKScore *gkScore = nil;
        
        NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
        NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
        NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
        
        if (savedScores != nil) {
            if (savedScores.count > 0) {
                gkScore = [NSKeyedUnarchiver unarchiveObjectWithData:[savedScores objectAtIndex:0]];
                
                [savedScores removeObjectAtIndex:0];
                [plistDict setObject:savedScores forKey:@"SavedScores"];
                
                NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
            }
        }
        
        if (gkScore != nil) {
            [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
                if (error == nil) {
                    [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                } else {
                    [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
                }
            }];
        } else {
            if ([GKLocalPlayer localPlayer].authenticated) {
                NSString *identifier = nil;
                double percentComplete = 0;
                
                NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                
                if (playerDict != nil) {
                    NSMutableDictionary *savedAchievements = [playerDict objectForKey:@"SavedAchievements"];
                    if (savedAchievements != nil) {
                        if (savedAchievements.count > 0) {
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
                
                if (identifier != nil) {
                    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
                    achievement.percentComplete = percentComplete;
                    [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
                        if (error == nil) {
                            [[GameCenterManager sharedManager] reportSavedScoresAndAchievements];
                        } else {
                            [[GameCenterManager sharedManager] saveAchievementToReportLater:achievement.identifier percentComplete:achievement.percentComplete];
                        }
                    }];
                    
                }
            }
        }
    }
}


//------------------------------------------------------------------------------------------------------------//
//------- Score and Achievement Reporting --------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Score and Achievement Reporting

// Save score and report it to GameCenter
- (void)saveAndReportScore:(int)score leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order  {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    
    if (playerDict == nil) {
        playerDict = [NSMutableDictionary dictionary];
    }
    
    NSNumber *savedHighScore = [playerDict objectForKey:identifier];
    if (savedHighScore == nil) {
        savedHighScore = [NSNumber numberWithInt:0];
    }
    
    int savedHighScoreValue = [savedHighScore intValue];
    
    // Determine if the new score is better than the old score
    BOOL isScoreBetter = NO;
    switch (order) {
        case GameCenterSortOrderLowToHigh: // A lower score is better
            if (score < savedHighScoreValue) {
                isScoreBetter = YES;
            }
            break;
        default:
            if (score > savedHighScoreValue) { // A higher score is better
                isScoreBetter = YES;
            }
            break;
    }
    
    if (isScoreBetter) {
        [playerDict setObject:[NSNumber numberWithInt:score] forKey:identifier];
        [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    }
    
    if ([[GameCenterManager sharedManager] checkGameCenterAvailability] == YES) {
        GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
        gkScore.value = score;
        
        [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            
            if (error == nil) {
                dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:gkScore, nil] forKeys:[NSArray arrayWithObjects:@"score", nil]];
            } else {
                dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:error.localizedDescription, gkScore, nil] forKeys:[NSArray arrayWithObjects:@"error", @"score", nil]];
                [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:reportedScore:)])
                    [[self delegate] gameCenterManager:self reportedScore:dict];
            });
        }];
        
    } else {
        GKScore *gkScore = [[GKScore alloc] initWithCategory:identifier];
        [[GameCenterManager sharedManager] saveScoreToReportLater:gkScore];
    }
}

// Save achievement and report it to GameCenter
- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete shouldDisplayNotification:(BOOL)displayNotification {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    
    if (playerDict == nil)
        playerDict = [NSMutableDictionary dictionary];
    
    NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
    if (savedPercentComplete == nil)
        savedPercentComplete = [NSNumber numberWithDouble:0];
    
    double savedPercentCompleteValue = [savedPercentComplete doubleValue];
    if (percentComplete > savedPercentCompleteValue) {
        [playerDict setObject:[NSNumber numberWithDouble:percentComplete] forKey:identifier];
        [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
        NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    }
    
    if ([[GameCenterManager sharedManager] checkGameCenterAvailability] == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
        achievement.percentComplete = percentComplete;
        if (displayNotification == YES) {
            achievement.showsCompletionBanner = YES;
        } else {
            achievement.showsCompletionBanner = NO;
        }
        
        [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            
            if (error == nil) {
                dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:achievement, nil] forKeys:[NSArray arrayWithObjects:@"achievement", nil]];
            } else {
                if (achievement) {
                    dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:error.localizedDescription, achievement, nil] forKeys:[NSArray arrayWithObjects:@"error", @"achievement", nil]];
                }
                
                [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:reportedAchievement:)])
                    [[self delegate] gameCenterManager:self reportedAchievement:dict];
            });
            
        }];
        
    } else {
        [[GameCenterManager sharedManager] saveAchievementToReportLater:identifier percentComplete:percentComplete];
    }
}

// Save score to report later
- (void)saveScoreToReportLater:(GKScore *)score {
    NSData *scoreData = [NSKeyedArchiver archivedDataWithRootObject:score];
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableArray *savedScores = [plistDict objectForKey:@"SavedScores"];
    
    if (savedScores != nil) {
        [savedScores addObject:scoreData];
    } else {
        savedScores = [NSMutableArray arrayWithObject:scoreData];
    }
    
    [plistDict setObject:savedScores forKey:@"SavedScores"];
    NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:savedScore:)])
            [[self delegate] gameCenterManager:self savedScore:score];
    });
}

- (void)saveAchievementToReportLater:(NSString *)identifier percentComplete:(double)percentComplete {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    
    if (playerDict != nil) {
        NSMutableDictionary *savedAchievements = [playerDict objectForKey:@"SavedAchievements"];
        if (savedAchievements != nil) {
            double savedPercentCompleteValue = 0;
            NSNumber *savedPercentComplete = [savedAchievements objectForKey:identifier];
            
            if (savedPercentComplete != nil) {
                savedPercentCompleteValue = [savedPercentComplete doubleValue];
            }
            
            // Compare the saved percent and the percent that was just submitted, if the submitted percent is greater save it
            if (percentComplete > savedPercentCompleteValue) {
                savedPercentComplete = [NSNumber numberWithDouble:percentComplete];
                [savedAchievements setObject:savedPercentComplete forKey:identifier];
            }
        } else {
            savedAchievements = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
            [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
        }
    } else {
        NSMutableDictionary *savedAchievements = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:percentComplete], identifier, nil];
        playerDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:savedAchievements, @"SavedAchievements", nil];
    }
    
    [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    NSNumber *percentNumber = [NSNumber numberWithDouble:percentComplete];
    
    if (percentNumber && achievement) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:savedAchievement:)])
                [[self delegate] gameCenterManager:self savedAchievement:[NSDictionary dictionaryWithObjects:@[achievement, percentNumber] forKeys:@[@"achievement", @"percent complete"]]];
        });
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"Could not save achievement because necessary data is missing. GameCenter needs an Achievement ID and Percent Completed to save the achievement. You provided the following data:\nAchievement: %@\nPercent Completed:%@", achievement, percentNumber]
                                             code:GCMErrorAchievementDataMissing userInfo:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                [[self delegate] gameCenterManager:self error:error];
        });
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- Score, Achievement, and Challenge Retrieval --------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Score, Achievement, and Challenge Retrieval

- (int)highScoreForLeaderboard:(NSString *)identifier {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    
    if (playerDict != nil) {
        NSNumber *savedHighScore = [playerDict objectForKey:identifier];
        if (savedHighScore != nil) {
            return [savedHighScore intValue];
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

// Get leaderboard high scores
- (NSDictionary *)highScoreForLeaderboards:(NSArray *)identifiers {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSMutableDictionary *highScores = [[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
    
    for (NSString *identifier in identifiers) {
        if (playerDict != nil) {
            NSNumber *savedHighScore = [playerDict objectForKey:identifier];
            
            if (savedHighScore != nil) {
                [highScores setObject:[NSNumber numberWithInt:[savedHighScore intValue]] forKey:identifier];
                continue;
            }
        }
        
        [highScores setObject:[NSNumber numberWithInt:0] forKey:identifier];
    }
    
    NSDictionary *highScoreDict = [NSDictionary dictionaryWithDictionary:highScores];
    
    return highScoreDict;
}

// Get achievement progress
- (double)progressForAchievement:(NSString *)identifier {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    
    if (playerDict != nil) {
        NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
        
        if (savedPercentComplete != nil) {
            return [savedPercentComplete doubleValue];
        }
    }
    return 0;
}

// Returns local player's percent completed for multiple achievements.
- (NSDictionary *)progressForAchievements:(NSArray *)identifiers {
    NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
    NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
    NSMutableDictionary *percent = [[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
    
    for (NSString *identifier in identifiers) {
        if (playerDict != nil) {
            NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
            
            if (savedPercentComplete != nil) {
                [percent setObject:[NSNumber numberWithDouble:[savedPercentComplete doubleValue]] forKey:identifier];
                continue;
            }
        }
        
        [percent setObject:[NSNumber numberWithDouble:0] forKey:identifier];
    }
    
    NSDictionary *percentDict = [NSDictionary dictionaryWithDictionary:percent];
    
    return percentDict;
}

// Returns local player's challenges for this game
- (void)getChallengesWithCompletion:(void (^)(NSArray *challenges, NSError *error))handler {
    if ([[GameCenterManager sharedManager] checkGameCenterAvailability] == YES) {
        BOOL isGameCenterChallengeAPIAvailable = (NSClassFromString(@"GKChallenge")) != nil;
        
        if (isGameCenterChallengeAPIAvailable == YES) {
            [GKChallenge loadReceivedChallengesWithCompletionHandler:^(NSArray *challenges, NSError *error) {
                if (error == nil) {
                    handler(challenges, nil);
                } else {
                    handler(nil, error);
                }
            }];
        } else {
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GKChallenge Class is not available. GKChallenge is only available on iOS 6.0 and higher. Current iOS version: %@", [[UIDevice currentDevice] systemVersion]] code:GCMErrorFeatureNotAvailable userInfo:nil];
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                [[self delegate] gameCenterManager:self error:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[self delegate] gameCenterManager:self error:error];
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- Resetting Data -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Resetting Data

// Reset all achievements and progress
- (void)resetAchievementsWithCompletion:(void (^)(NSError *))handler {
    if ([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
            if (error == nil) {
                NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:kGameCenterManagerKey];
                NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchiveObjectWithData:gameCenterManagerData];
                NSMutableDictionary *playerDict = [plistDict objectForKey:[[GameCenterManager sharedManager] localPlayerId]];
                
                if (playerDict == nil) {
                    playerDict = [NSMutableDictionary dictionary];
                }
                
                for (GKAchievement *achievement in achievements) {
                    [playerDict removeObjectForKey:achievement.identifier];
                }
                
                [plistDict setObject:playerDict forKey:[[GameCenterManager sharedManager] localPlayerId]];
                NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:kGameCenterManagerKey];
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                
                [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
                    if (error == nil) {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[[GameCenterManager sharedManager] localPlayerId]]];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        [self syncGameCenter];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            handler(nil);
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            handler(error);
                        });
                    }
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(error);
                });
            }
        }];
    }
}

//------------------------------------------------------------------------------------------------------------//
//------- Player Data ----------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Player Data

// Checks if player is authenticated and gets his / her ID
- (NSString *)localPlayerId {
    if ([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if ([GKLocalPlayer localPlayer].authenticated) {
            return [GKLocalPlayer localPlayer].playerID;
        }
    }
    return @"unknownPlayer";
}

// Returns the local player's display name
- (NSString *)localPlayerDisplayName {
    if ([[GameCenterManager sharedManager] isGameCenterAvailable] && [GKLocalPlayer localPlayer].authenticated) {
        if ([[GKLocalPlayer localPlayer] respondsToSelector:@selector(displayName)]) {
                return [GKLocalPlayer localPlayer].displayName;
        } else {
                return [GKLocalPlayer localPlayer].alias;
        }
    }
    
    return @"unknownPlayer";
}

// Checks if player is authenticated and gets his / her ID
- (GKLocalPlayer *)localPlayerData {
    if ([[GameCenterManager sharedManager] isGameCenterAvailable] && [GKLocalPlayer localPlayer].authenticated) {
            return [GKLocalPlayer localPlayer];
    } else {
        return nil;
    }
}

- (void)localPlayerPhoto:(void (^)(UIImage *playerPhoto))handler {
    if ([[GameCenterManager sharedManager] isGameCenterAvailable]) {
        if ([GKPlayer respondsToSelector:@selector(loadPhotoForSize:withCompletionHandler:)]) {
            [[self localPlayerData] loadPhotoForSize:GKPhotoSizeNormal withCompletionHandler:^(UIImage *photo, NSError *error) {
                handler(photo);
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                            [[self delegate] gameCenterManager:self error:error];
                    });
                }
            }];
        } else {
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"loadPhotoForSize:withCompletionHandler: method is not available. loadPhotoForSize:withCompletionHandler: is only available on iOS 5.0 and higher. Current iOS version: %@", [[UIDevice currentDevice] systemVersion]] code:GCMErrorFeatureNotAvailable userInfo:nil];
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                [[self delegate] gameCenterManager:self error:error];
        }
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[self delegate] gameCenterManager:self error:error];
    }
}

@end