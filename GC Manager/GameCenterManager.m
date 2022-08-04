//
//  GameCenterManager.m
//
//  Created by Nihal Ahmed on 12-03-16. Updated by iRare Media on 5-27-13.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//  Updated by Daniel Rosser 19/7/22 <https://danoli3.com>

// GameCenterManager uses ARC, check for compatibility before building
#if !__has_feature(objc_arc)
#error GameCenterManager uses Objective-C ARC. Compile these files with ARC enabled. Add the -fobjc-arc compiler flag to enable ARC for only these files.
#endif

#import "GameCenterManager.h"

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Singleton -----------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark GameCenter Manager


@interface GameCenterManager () {
    NSMutableArray *GCMLeaderboards;
    int leaderboardIndex;
    
#if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier backgroundProcess;
    
#endif
}

@property (nonatomic, strong, readwrite) NSArray<NSString *>*gameleaderboardIDs;
@property (nonatomic, assign, readwrite) BOOL hasLeaderboards;
@property (nonatomic, assign, readwrite) BOOL shouldCryptData;
@property (nonatomic, strong, readwrite) NSString *cryptKey;
@property (nonatomic, strong, readwrite) NSData *cryptKeyData;
@property (nonatomic, assign, readwrite) GameCenterAvailability previousGameCenterAvailability;

@end

@implementation GameCenterManager

#pragma mark - Object Lifecycle

+ (GameCenterManager *)sharedManager {
    static GameCenterManager *singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (instancetype)init {
    self = [super init];
    
    return self;
}

//------------------------------------------------------------------------------------------------------------//
//------- GameCenter Manager Setup ---------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - GameCenter Manager Setup

- (void)logout {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
    [userDefaults setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
    [userDefaults synchronize];
    
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    NSLog(@"Game Center Manager - Logout - Values Reset");
    
    
}

- (void)setupManagerWithLeaderboardIDs:(NSArray<NSString *>*)leaderboardIDs {
    _gameleaderboardIDs = leaderboardIDs;
    if(_gameleaderboardIDs != NULL && _gameleaderboardIDs.count > 0) {
        _hasLeaderboards = YES;
    } else {
        _hasLeaderboards = NO;
    }
    
    leaderboardIndex = 0;
    
}

- (void)setupManager {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:NO forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
    [userDefaults setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
    [userDefaults synchronize];
    
    // This code should only be called once, to avoid unhandled exceptions when parsing the PLIST data
#if !TARGET_OS_TV
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setShouldCryptData:YES];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kApplicationAppSupportDirectory]) {
            NSError *error = nil;
            BOOL isDirectoryCreated = [fileManager createDirectoryAtPath:kApplicationAppSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error];
            if(!isDirectoryCreated) NSLog(@"Failed to created Application Support Folder: %@", error);
        }
        
        if (![fileManager fileExistsAtPath:kGameCenterManagerDataPath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSError *error = nil;
            NSData *saveData = nil;
            if(self.shouldCryptData)
                saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error]
                            encryptedWithKey:self.cryptKeyData];
            else
                saveData = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error];
            
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
        
        NSData *gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
        if (gameCenterManagerData == nil) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSError *error = nil;
            
            NSData *saveData = nil;
            if(self.shouldCryptData)
                saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error]
                            encryptedWithKey:self.cryptKeyData];
            else
                saveData = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error];
            
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
    });
#else
    // tvOS doesn't need to initialize any plist file as it must use NSUserDefaults
#endif
    if (self) {
        BOOL gameCenterAvailable = [self checkGameCenterAvailability:YES];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs synchronize];
        
        if ([prefs objectForKey:@"scoresSynced"] == nil) {
            NSLog(@"scoresSynced not setup");
            [prefs setBool:NO forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
        } else {
            NSLog(@"scoresSynced WAS setup");
        }
        
        if ([prefs objectForKey:@"achievementsSynced"] == nil) {
            NSLog(@"achievementsSynced not setup");
            [prefs setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
        } else {
            NSLog(@"achievementsSynced WAS setup");
        }
        
        [prefs synchronize];
        
        if (gameCenterAvailable) {
            // Set GameCenter as available
            [self setIsGameCenterAvailable:YES];
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]]
                || ![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]])
                [self syncGameCenter];
            else
                if (@available(iOS 14.0, *))
                    [self reportSavedLeaderboardScoresAndAchievements];
                else
                    [self reportSavedScoresAndAchievements];
        } else {
            [self setIsGameCenterAvailable:NO];
        }
    }
    
}

- (void)setupManagerAndSetShouldCryptWithKey:(NSString *)cryptionKey {
#if !TARGET_OS_TV
    // This code should only be called once, to avoid unhandled exceptions when parsing the PLIST data
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.shouldCryptData = YES;
        self.cryptKey = cryptionKey;
        self.cryptKeyData = [cryptionKey dataUsingEncoding:NSUTF8StringEncoding];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:kApplicationAppSupportDirectory]) {
            NSError *error = nil;
            BOOL isDirectoryCreated = [fileManager createDirectoryAtPath:kApplicationAppSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error];
            if(!isDirectoryCreated) NSLog(@"Failed to created Application Support Folder: %@", error);
        }
        
        if (![fileManager fileExistsAtPath:kGameCenterManagerDataPath]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            //            NSData *saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict] encryptedWithKey:self.cryptKeyData];
            
            NSError *error = nil;
            NSData *saveData = nil;
            if(self.shouldCryptData)
                saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error]
                            encryptedWithKey:self.cryptKeyData];
            else
                saveData = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error];
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
        
        NSData *gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
        if (gameCenterManagerData == nil) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSError *error = nil;
            NSData *saveData = nil;
            if(self.shouldCryptData)
                saveData = [[NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error]
                            encryptedWithKey:self.cryptKeyData];
            else
                saveData = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:self.shouldCryptData error:&error];
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        }
    });
#else
    // tvOS doesn't need to initialize any plist file as it must use NSUserDefaults
#endif
}

- (BOOL)checkGameCenterAvailability:(BOOL)ignorePreviousStatus {
#if TARGET_OS_IPHONE
    // First, check if the the GameKit Framework exists on the device. Return NO if it does not.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    BOOL isGameCenterAPIAvailable = (localPlayerClassAvailable && osVersionSupported);
#else
    BOOL isGameCenterAPIAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
#endif
    
    if (!isGameCenterAPIAvailable) {
        if ([self previousGameCenterAvailability] != GameCenterAvailabilityNotAvailable) {
            [self setPreviousGameCenterAvailability:GameCenterAvailabilityNotAvailable];
            NSDictionary *errorDictionary = @{@"message": @"GameKit Framework not available on this device. GameKit is only available on devices with iOS 4.1 or     higher. Some devices running iOS 4.1 may not have GameCenter enabled.", @"title": @"GameCenter Unavailable"};
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                    [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
            });
        }
        
        return NO;
        
    } else {
        // The GameKit Framework is available. Now check if an internet connection can be established
        BOOL internetAvailable = [self isInternetAvailable];
        if (!internetAvailable) {
            if ([self previousGameCenterAvailability] != GameCenterAvailabilityNoInternet) {
                [self setPreviousGameCenterAvailability:GameCenterAvailabilityNoInternet];
                NSDictionary *errorDictionary = @{@"message": @"Cannot connect to the internet. Connect to the internet to establish a connection with GameCenter. Achievements and scores will still be saved locally and then uploaded later.", @"title": @"Internet Unavailable"};
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                        [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                });
            }
            
            return NO;
            
        } else {
            // The internet is available and the current device is connected. Now check if the player is authenticated
            GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
#if TARGET_OS_IPHONE
            if(!localPlayer.isAuthenticated) {
                localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
                    if (viewController != nil) {
                        if ([self previousGameCenterAvailability] != GameCenterAvailabilityNoPlayer) {
                            [self setPreviousGameCenterAvailability:GameCenterAvailabilityNoPlayer];
                            NSDictionary *errorDictionary = @{@"message": @"Player is not yet signed into GameCenter. Please prompt the player using the authenticateUser delegate method.", @"title": @"No Player"};
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                                    [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                                
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:authenticateUser:)]) {
                                    [[self delegate] gameCenterManager:self authenticateUser:viewController];
                                } else {
                                    NSLog(@"[ERROR] %@ Fails to Respond to the required delegate method gameCenterManager:authenticateUser:. This delegate method must be properly implemented to use GC Manager", [self delegate]);
                                }
                            });
                        }
                    } else if (!error) {
                        // Authentication handler completed successfully. Re-check availability
                        [self checkGameCenterAvailability:ignorePreviousStatus];
                    }
                };
            }
#else
            if(!localPlayer.isAuthenticated) {
                localPlayer.authenticateHandler = ^(NSViewController *viewController, NSError *error) {
                    if (viewController != nil) {
                        if ([self previousGameCenterAvailability] != GameCenterAvailabilityNoPlayer) {
                            [self setPreviousGameCenterAvailability:GameCenterAvailabilityNoPlayer];
                            NSDictionary *errorDictionary = @{@"message": @"Player is not yet signed into GameCenter. Please prompt the player using the authenticateUser delegate method.", @"title": @"No Player"};
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                                    [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                                
                                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:authenticateUser:)]) {
                                    [[self delegate] gameCenterManager:self authenticateUser:viewController];
                                } else {
                                    NSLog(@"[ERROR] %@ Fails to Respond to the required delegate method gameCenterManager:authenticateUser:. This delegate method must be properly implemented to use GC Manager", [self delegate]);
                                }
                            });
                        }
                    } else if (!error) {
                        // Authentication handler completed successfully. Re-check availability
                        [self checkGameCenterAvailability:ignorePreviousStatus];
                    }
                };
            }
#endif
            
            if (![[GKLocalPlayer localPlayer] isAuthenticated]) {
                if ([self previousGameCenterAvailability] != GameCenterAvailabilityPlayerNotAuthenticated) {
                    [self setPreviousGameCenterAvailability:GameCenterAvailabilityPlayerNotAuthenticated];
                    NSDictionary *errorDictionary = @{@"message": @"Player is not signed into GameCenter, has declined to sign into GameCenter, or GameKit had an issue validating this game / app.", @"title": @"Player not Authenticated"};
                    
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                        [[self delegate] gameCenterManager:self availabilityChanged:errorDictionary];
                }
                
                return NO;
                
            } else {
                if ([self previousGameCenterAvailability] != GameCenterAvailabilityPlayerAuthenticated) {
                    [self setPreviousGameCenterAvailability:GameCenterAvailabilityPlayerAuthenticated];
                    // The current player is logged into GameCenter
                    NSDictionary *successDictionary = [NSDictionary dictionaryWithObject:@"GameCenter Available" forKey:@"status"];
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setBool:NO forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
                    [userDefaults setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
                    [userDefaults synchronize];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:availabilityChanged:)])
                            [[self delegate] gameCenterManager:self availabilityChanged:successDictionary];
                    });
                    
                    self.isGameCenterAvailable = YES;
                }
                
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
        NSLog(@"Internet unavailable");
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
#if TARGET_OS_IPHONE || TARGET_OS_TV
    NSLog(@"SyncGameCenter");
    // Begin Syncing with GameCenter
    // Move the process to the background thread to avoid clogging up the UI
    dispatch_queue_t syncGameCenterOnBackgroundThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(syncGameCenterOnBackgroundThread, ^{
        
        // Check if GameCenter is available
        if ([self checkGameCenterAvailability:NO] == YES) {
            // Check if Leaderboard Scores are synced
            if (self->_hasLeaderboards == YES) {
                if (self->GCMLeaderboards == nil) {
                    if(self->_hasLeaderboards == YES) {
                        if (@available(iOS 14.0, *)) {
                            [GKLeaderboard loadLeaderboardsWithIDs:self->_gameleaderboardIDs completionHandler:^(NSArray<GKLeaderboard *> * _Nullable leaderboards, NSError * _Nullable error) {
                                if (error == nil) {
                                    self->GCMLeaderboards = [[NSMutableArray alloc] initWithArray:leaderboards];
                                    if(leaderboards.count > 0){
                                        self->leaderboardIndex = leaderboards.count -1;
                                        
                                    }
                                    [self syncGameCenter];
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                            [[self delegate] gameCenterManager:self error:error];
                                    });
                                }
                            }];
                        } else {
                            // Fallback on earlier versions
                            [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                                if (error == nil) {
                                    self->GCMLeaderboards = [[NSMutableArray alloc] initWithArray:leaderboards];
                                    [self syncGameCenter];
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                            [[self delegate] gameCenterManager:self error:error];
                                    });
                                }
                            }];
                        }
                        
                        return;
                    }
                }
                
            } else if(![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]] && self->_hasLeaderboards == YES) {
                if (self->GCMLeaderboards.count > 0 && self->leaderboardIndex >= 0) {
                    
                    GKLeaderboard * leaderboardRequest;
                
                    
                    if (@available(iOS 14.0, *)) {
                        
                        leaderboardRequest = (GKLeaderboard *)self->GCMLeaderboards[self->leaderboardIndex];
                        [leaderboardRequest setIdentifier:[(GKLeaderboard *)[self->GCMLeaderboards objectAtIndex:self->leaderboardIndex] baseLeaderboardID]];
                        
                        
                        [leaderboardRequest loadEntriesForPlayerScope:GKLeaderboardPlayerScopeGlobal
                                                            timeScope:GKLeaderboardTimeScopeAllTime range:NSMakeRange(1, 10) completionHandler:^(GKLeaderboardEntry * _Nullable_result localPlayerEntry, NSArray<GKLeaderboardEntry *> * _Nullable entries, NSInteger totalPlayerCount, NSError * _Nullable error) {
                            if (error == nil) {
                                if (entries.count > 0) {
                                    NSMutableDictionary *playerDict;
#if !TARGET_OS_TV
                                    NSMutableDictionary *plistDict;
                                    NSData *gameCenterManagerData;
                                    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                                    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                                    
                                    plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                                    playerDict = [plistDict objectForKey:[self localPlayerId]];
#else
                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
#endif
                                    
                                    if (playerDict == nil) {
                                        playerDict = [NSMutableDictionary dictionary];
                                    }
                                    
                                    float savedHighScoreValue = 0;
                                    
                                    
                                    
                                    NSNumber *savedHighScore = [playerDict objectForKey:leaderboardRequest.baseLeaderboardID];
                                    
                                    if (savedHighScore != nil) {
                                        savedHighScoreValue = [savedHighScore longLongValue];
                                    }
                                    
                                    
                                    
                                    [playerDict setObject:[NSNumber numberWithLongLong:MAX(localPlayerEntry.score, savedHighScoreValue)] forKey:leaderboardRequest.baseLeaderboardID];
#if !TARGET_OS_TV
                                    [plistDict setObject:playerDict forKey:[self localPlayerId]];
                                    NSData *saveData;
                                    saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                                    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
#else
                                    [defaults setObject:playerDict forKey:[self localPlayerId]];
                                    [defaults synchronize];
#endif
                                }
                                
                                // Seeing an NSRangeException for an empty array when trying to remove the object
                                // Despite the check above in this scope that leaderboards count is > 0
                                if (self->GCMLeaderboards.count > 0 && self->leaderboardIndex >= 0) {
                                    //[self->GCMLeaderboards removeObjectAtIndex:0];
                                    self->leaderboardIndex--;
                                }
                                
                                [self syncGameCenter];
                            }
                            
                        }];
                    } else {
                        leaderboardRequest = [[GKLeaderboard alloc] initWithPlayers:[NSArray arrayWithObject:[GKLocalPlayer localPlayer]]];
                        
                        [leaderboardRequest setIdentifier:[(GKLeaderboard *)[self->GCMLeaderboards objectAtIndex:0] identifier]];
                        // Fallback on earlier versions
                        [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                            if (error == nil) {
                                if (scores.count > 0) {
                                    NSMutableDictionary *playerDict;
#if !TARGET_OS_TV
                                    NSMutableDictionary *plistDict;
                                    NSData *gameCenterManagerData;
                                    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                                    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                                    
                                    plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                                    playerDict = [plistDict objectForKey:[self localPlayerId]];
#else
                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
#endif
                                    
                                    if (playerDict == nil) {
                                        playerDict = [NSMutableDictionary dictionary];
                                    }
                                    
                                    float savedHighScoreValue = 0;
                                    NSNumber *savedHighScore = [playerDict objectForKey:leaderboardRequest.localPlayerScore.leaderboardIdentifier];
                                    
                                    if (savedHighScore != nil) {
                                        savedHighScoreValue = [savedHighScore longLongValue];
                                    }
                                    
                                    [playerDict setObject:[NSNumber numberWithLongLong:MAX(leaderboardRequest.localPlayerScore.value, savedHighScoreValue)] forKey:leaderboardRequest.localPlayerScore.leaderboardIdentifier];
#if !TARGET_OS_TV
                                    [plistDict setObject:playerDict forKey:[self localPlayerId]];
                                    NSData *saveData;
                                    saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                                    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
#else
                                    [defaults setObject:playerDict forKey:[self localPlayerId]];
                                    [defaults synchronize];
#endif
                                }
 
                                [self syncGameCenter];
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                        [[self delegate] gameCenterManager:self error:error];
                                });
                            }
                        }];
                    }
                    
                } else {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
                    [self syncGameCenter];
                }
                
                // Check if Achievements are synced
            } else if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]]) {
                [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                    if (error == nil) {
                        NSLog(@"Number of Achievements: %@", achievements);
                        if (achievements.count > 0) {
                            NSMutableDictionary *playerDict;
#if !TARGET_OS_TV
                            NSData *gameCenterManagerData;
                            if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                            else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                            playerDict = [plistDict objectForKey:[self localPlayerId]];
#else
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
#endif
                            
                            if (playerDict == nil) {
                                playerDict = [NSMutableDictionary dictionary];
                            }
                            
                            for (GKAchievement *achievement in achievements) {
                                [playerDict setObject:[NSNumber numberWithDouble:achievement.percentComplete] forKey:achievement.identifier];
                            }
#if !TARGET_OS_TV
                            [plistDict setObject:playerDict forKey:[self localPlayerId]];
                            NSData *saveData;
                            saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                            
                            
                            
                            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
#else
                            [defaults setObject:playerDict forKey:[self localPlayerId]];
                            [defaults synchronize];
#endif
                            
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
                        [self syncGameCenter];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                [[self delegate] gameCenterManager:self error:error];
                        });
                    }
                }];
            } else if( [[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]] == YES &&
                      [[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]] == YES ) {
                // Game Center Synced
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterSynced:)]) {
                        [[self delegate] gameCenterManager:self gameCenterSynced:YES];
                    }
                });
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
#else
    // Check if GameCenter is available
    if ([self checkGameCenterAvailability:NO] == YES) {
        // Check if Leaderboard Scores are synced
        if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]]) {
            if (GCMLeaderboards == nil) {
                [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                    if (error == nil) {
                        GCMLeaderboards = [[NSMutableArray alloc] initWithArray:leaderboards];
                        [self syncGameCenter];
                    } else {
                        NSLog(@"%@",[error localizedDescription]);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                [[self delegate] gameCenterManager:self error:error];
                        });
                    }
                }];
                return;
            }
            
            if (GCMLeaderboards.count > 0) {
                GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayers:[NSArray arrayWithObject:[GKLocalPlayer localPlayer]]];
                [leaderboardRequest setIdentifier:[(GKLeaderboard *)[GCMLeaderboards objectAtIndex:0] identifier]];
                
                [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                    if (error == nil) {
                        if (scores.count > 0) {
                            NSData *gameCenterManagerData;
                            if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                            else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                            NSMutableDictionary *playerDict = [plistDict objectForKey:[self localPlayerId]];
                            
                            if (playerDict == nil) {
                                playerDict = [NSMutableDictionary dictionary];
                            }
                            
                            float savedHighScoreValue = 0;
                            NSNumber *savedHighScore = [playerDict objectForKey:leaderboardRequest.localPlayerScore.leaderboardIdentifier];
                            
                            
                            if (savedHighScore != nil) {
                                savedHighScoreValue = [savedHighScore longLongValue];
                            }
                            
                            
                            [playerDict setObject:[NSNumber numberWithLongLong:MAX(leaderboardRequest.localPlayerScore.value, savedHighScoreValue)] forKey:leaderboardRequest.localPlayerScore.leaderboardIdentifier];
                            
                            [plistDict setObject:playerDict forKey:[self localPlayerId]];
                            
                            NSData *saveData;
                            saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                            
                            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                        }
                        
                        // Seeing an NSRangeException for an empty array when trying to remove the object
                        // Despite the check above in this scope that leaderboards count is > 0
                        if (GCMLeaderboards.count > 0) {
                            [GCMLeaderboards removeObjectAtIndex:0];
                        }
                        
                        [self syncGameCenter];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"%@",[error localizedDescription]);
                            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                                [[self delegate] gameCenterManager:self error:error];
                        });
                    }
                }];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]];
                [self syncGameCenter];
            }
            
            // Check if Achievements are synced
        } else if (![[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]]) {
            [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                if (error == nil) {
                    if (achievements.count > 0) {
                        NSData *gameCenterManagerData;
                        if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                        else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                        NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                        NSMutableDictionary *playerDict = [plistDict objectForKey:[self localPlayerId]];
                        
                        if (playerDict == nil) {
                            playerDict = [NSMutableDictionary dictionary];
                        }
                        
                        for (GKAchievement *achievement in achievements) {
                            [playerDict setObject:[NSNumber numberWithDouble:achievement.percentComplete] forKey:achievement.identifier];
                        }
                        
                        [plistDict setObject:playerDict forKey:[self localPlayerId]];
                        NSData *saveData;
                        saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                        
                        
                        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
                    [self syncGameCenter];
                } else {
                    NSLog(@"%@",[error localizedDescription]);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                            [[self delegate] gameCenterManager:self error:error];
                    });
                }
            }];
        } else if( [[NSUserDefaults standardUserDefaults] boolForKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]] == YES &&
                  [[NSUserDefaults standardUserDefaults] boolForKey:[@"scoresSynced" stringByAppendingString:[self localPlayerId]]] == YES ) {
            // Game Center Synced
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterSynced:)]) {
                    [[self delegate] gameCenterManager:self gameCenterSynced:YES];
                }
            });
        } else {
        }
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter unavailable."] code:GCMErrorNotAvailable userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                [[self delegate] gameCenterManager:self error:error];
        });
    }
#endif
}


- (void)reportSavedLeaderboardScoresAndAchievements {
    if ([self isInternetAvailable] == NO) return;
   
    
    GKLeaderboardScore *gkScore = nil;
    NSMutableArray *savedScores;
    NSError * error;
#if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    savedScores = [plistDict objectForKey:@"SavedScores"];
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    savedScores = [[defaults objectForKey:@"SavedScores"] mutableCopy];
#endif
    
    if (savedScores != nil) {
        if (savedScores.count > 0) {
            gkScore = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:[savedScores objectAtIndex:0] error:&error];
            [savedScores removeObjectAtIndex:0];
            
#if !TARGET_OS_TV
            [plistDict setObject:savedScores forKey:@"SavedScores"];
            
            NSData *saveData;
            saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
            if ([GKLocalPlayer localPlayer].authenticated)
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
            else {
                NSLog(@"GameCenterManager::reportSavedLeaderboardScoresAndAchievements not logged in - wont destroy the score");
            }
#else
            [defaults setObject:savedScores forKey:@"SavedScores"];
            [defaults synchronize];
#endif
        }
    }
    
    if (gkScore != nil && gkScore.value != 0) {
        
            GKLeaderboard * leaderboard = nil;
            for(int i= 0; i<self->GCMLeaderboards.count; i++)
            {
                GKLeaderboard * leaderboardRequest = (GKLeaderboard *)self->GCMLeaderboards[self->leaderboardIndex];
                if(leaderboardRequest != nil && ([leaderboardRequest.baseLeaderboardID isEqualToString:gkScore.leaderboardID] == YES || leaderboardRequest.baseLeaderboardID == gkScore.leaderboardID)) {
                    leaderboard = leaderboardRequest;
                    break;
                }
            }
            
            if(leaderboard == nil) {
                NSLog(@"saveAndReportScore:could not find leaderboard");
                return;
            }
            
            [leaderboard submitScore:gkScore.value
                             context:gkScore.context
                              player:gkScore.player
                   completionHandler:^(NSError * _Nullable error) {
                    if (error == nil) {
                        [self reportSavedLeaderboardScoresAndAchievements];
                    } else {
                        [self saveLeaderboardScoreToReportLater:gkScore];
                    }
                }];
    } else {
        if ([GKLocalPlayer localPlayer].authenticated) {
            NSString *identifier = nil;
            double percentComplete = 0;
            
            NSMutableDictionary *playerDict;
            
#if !TARGET_OS_TV
            NSData *gameCenterManagerData;
            if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
            else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
            playerDict = [plistDict objectForKey:[self localPlayerId]];
#else
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
#endif
            
            if (playerDict != nil) {
                NSMutableDictionary *savedAchievements = [[playerDict objectForKey:@"SavedAchievements"] mutableCopy];
                if (savedAchievements != nil) {
                    if (savedAchievements.count > 0) {
                        identifier = [[savedAchievements allKeys] objectAtIndex:0];
                        percentComplete = [[savedAchievements objectForKey:identifier] doubleValue];
                        
                        [savedAchievements removeObjectForKey:identifier];
                        [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
                        
#if !TARGET_OS_TV
                        [plistDict setObject:playerDict forKey:[self localPlayerId]];
                        NSData *saveData;
                        saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
#else
                        [defaults setObject:playerDict forKey:[self localPlayerId]];
                        [defaults synchronize];
#endif
                    }
                }
            }
            
            if (identifier != nil) {
                GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
                achievement.percentComplete = percentComplete;
                [GKAchievement reportAchievements:@[achievement] withCompletionHandler:^(NSError *error) {
                    if (error == nil) {
                        if (@available(iOS 14.0, *))
                            [self reportSavedLeaderboardScoresAndAchievements];
                        else
                            [self reportSavedScoresAndAchievements];
                    } else {
                        [self saveAchievementToReportLater:achievement.identifier percentComplete:achievement.percentComplete];
                    }
                }];
            }
        }
    }
}

- (void)reportSavedScoresAndAchievements {
    if ([self isInternetAvailable] == NO) return;
    
    GKScore *gkScore = nil;
    NSMutableArray *savedScores;
    NSError * error;
#if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    savedScores = [plistDict objectForKey:@"SavedScores"];
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    savedScores = [[defaults objectForKey:@"SavedScores"] mutableCopy];
#endif
    
    if (savedScores != nil) {
        if (savedScores.count > 0) {
            gkScore = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:[savedScores objectAtIndex:0] error:&error];
            [savedScores removeObjectAtIndex:0];
            
#if !TARGET_OS_TV
            [plistDict setObject:savedScores forKey:@"SavedScores"];
            
            NSData *saveData;
            saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
            if ([GKLocalPlayer localPlayer].authenticated)
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
            else {
                NSLog(@"GameCenterManager::reportSavedScoresAndAchievements not logged in - wont destroy the score");
            }
#else
            [defaults setObject:savedScores forKey:@"SavedScores"];
            [defaults synchronize];
#endif
        }
    }
    
    if (gkScore != nil && gkScore.value != 0) {
        
        [GKScore reportScores:@[gkScore] withCompletionHandler:^(NSError *error) {
            if (error == nil) {
                [self reportSavedScoresAndAchievements];
            } else {
                [self saveScoreToReportLater:gkScore];
            }
        }];
    } else {
        if ([GKLocalPlayer localPlayer].authenticated) {
            NSString *identifier = nil;
            double percentComplete = 0;
            
            NSMutableDictionary *playerDict;
            
#if !TARGET_OS_TV
            NSData *gameCenterManagerData;
            if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
            else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
            NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
            playerDict = [plistDict objectForKey:[self localPlayerId]];
#else
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
#endif
            
            if (playerDict != nil) {
                NSMutableDictionary *savedAchievements = [[playerDict objectForKey:@"SavedAchievements"] mutableCopy];
                if (savedAchievements != nil) {
                    if (savedAchievements.count > 0) {
                        identifier = [[savedAchievements allKeys] objectAtIndex:0];
                        percentComplete = [[savedAchievements objectForKey:identifier] doubleValue];
                        
                        [savedAchievements removeObjectForKey:identifier];
                        [playerDict setObject:savedAchievements forKey:@"SavedAchievements"];
                        
#if !TARGET_OS_TV
                        [plistDict setObject:playerDict forKey:[self localPlayerId]];
                        NSData *saveData;
                        saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
                        [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
#else
                        [defaults setObject:playerDict forKey:[self localPlayerId]];
                        [defaults synchronize];
#endif
                    }
                }
            }
            
            if (identifier != nil) {
                GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
                achievement.percentComplete = percentComplete;
                [GKAchievement reportAchievements:@[achievement] withCompletionHandler:^(NSError *error) {
                    if (error == nil) {
                        if (@available(iOS 14.0, *))
                            [self reportSavedLeaderboardScoresAndAchievements];
                        else
                            [self reportSavedScoresAndAchievements];
                    } else {
                        [self saveAchievementToReportLater:achievement.identifier percentComplete:achievement.percentComplete];
                    }
                }];
            }
        }
    }
}


//------------------------------------------------------------------------------------------------------------//
//------- Score and Achievement Reporting --------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Score and Achievement Reporting

- (void)saveAndReportScore:(long long)score  leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order  {
    [self saveAndReportScore:score context:0 leaderboard:identifier sortOrder:order];
}

- (void)saveAndReportScore:(long long)score context:(long long)context leaderboard:(NSString *)identifier sortOrder:(GameCenterSortOrder)order  {
    
    NSMutableDictionary *playerDict;
    NSError * error;
    #if !TARGET_OS_TV
        NSData *gameCenterManagerData;
        if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
        else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
        playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    if (playerDict == nil) playerDict = [NSMutableDictionary dictionary];
    
    NSNumber *savedHighScore = [playerDict objectForKey:identifier];
    if (savedHighScore == nil)
        savedHighScore = [NSNumber numberWithLongLong:0];
    
    long long savedHighScoreValue = [savedHighScore longLongValue];
    
    // Determine if the new score is better than the old score
    BOOL isScoreBetter = NO;
    switch (order) {
        case GameCenterSortOrderLowToHigh: // A lower score is better
            if (score < savedHighScoreValue) isScoreBetter = YES;
            break;
        default:
            if (score > savedHighScoreValue) // A higher score is better
                isScoreBetter = YES;
            break;
    }
    
    if (isScoreBetter) {
        [playerDict setObject:[NSNumber numberWithLongLong:score] forKey:identifier];
        #if !TARGET_OS_TV
            [plistDict setObject:playerDict forKey:[self localPlayerId]];
        NSData *saveData;
        NSError *error;
        saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        #else
            [defaults setObject:playerDict forKey:[self localPlayerId]];
            [defaults synchronize];
        #endif
    }
    
    if ([self checkGameCenterAvailability:NO] == YES) {

        if (@available(iOS 14.0, *)) {
            
            GKLeaderboard * leaderboard = nil;
            for(int i= 0; i<self->GCMLeaderboards.count; i++)
            {
                GKLeaderboard * leaderboardRequest = (GKLeaderboard *)self->GCMLeaderboards[self->leaderboardIndex];
                if(leaderboardRequest != nil && ([leaderboardRequest.baseLeaderboardID isEqualToString:identifier] == YES || leaderboardRequest.baseLeaderboardID == identifier)) {
                    leaderboard = leaderboardRequest;
                    break;
                }
            }
            
            
            if(leaderboard == nil) {
                NSLog(@"saveAndReportScore:could not find leaderboard");
                return;
            }
            
            GKLeaderboardScore * gkScore = [GKLeaderboardScore alloc];
               gkScore.leaderboardID = identifier;
               gkScore.player = [GKLocalPlayer localPlayer];
               gkScore.value = score;
               gkScore.context = context;
            
            [leaderboard submitScore:score
                             context:context
                              player:[GKLocalPlayer localPlayer] completionHandler:^(NSError * _Nullable error) {
                NSDictionary *dict = nil;
    
                    if (error == nil) {
                        dict = [NSDictionary dictionaryWithObjects:@[gkScore] forKeys:@[@"leaderboardscore"]];
                    } else {
                        dict = [NSDictionary dictionaryWithObjects:@[error.localizedDescription, gkScore] forKeys:@[@"error", @"leaderboardscore"]];
                        [self saveLeaderboardScoreToReportLater:gkScore];
                    }
    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:reportedLeaderboardScore:withError:)])
                            [[self delegate] gameCenterManager:self reportedLeaderboardScore:gkScore withError:error];
                    });
                }];
    

        } else {
            GKScore *gkScore = [[GKScore alloc] initWithLeaderboardIdentifier:identifier];
            
            [gkScore setValue:score];
            
            [GKScore reportScores:@[gkScore] withCompletionHandler:^(NSError *error) {
                NSDictionary *dict = nil;
                
                if (error == nil) {
                    dict = [NSDictionary dictionaryWithObjects:@[gkScore] forKeys:@[@"score"]];
                } else {
                    dict = [NSDictionary dictionaryWithObjects:@[error.localizedDescription, gkScore] forKeys:@[@"error", @"score"]];
                    [self saveScoreToReportLater:gkScore];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:reportedScore:withError:)])
                        [[self delegate] gameCenterManager:self reportedScore:gkScore withError:error];
                });
            }];
        }
        
    } else {
        if (@available(iOS 14.0, *)) {
            GKLeaderboardScore * gkScore = [GKLeaderboardScore alloc];
               gkScore.leaderboardID = identifier;
               gkScore.player = [GKLocalPlayer localPlayer];
               gkScore.value = score;
               gkScore.context = 0;
            [self saveLeaderboardScoreToReportLater:gkScore];
        }
        else {
#if TARGET_OS_IPHONE
            GKScore *gkScore = [[GKScore alloc] initWithLeaderboardIdentifier:identifier];
#else
            GKScore *gkScore = [[GKScore alloc] initWithLeaderboardIdentifier:identifier];
#endif
            [gkScore setValue:score];
            [self saveScoreToReportLater:gkScore];
        }
    }
}

- (void)saveAndReportAchievement:(NSString *)identifier percentComplete:(double)percentComplete shouldDisplayNotification:(BOOL)displayNotification {
    NSMutableDictionary *playerDict;
    NSError * error;
    #if !TARGET_OS_TV
        NSData *gameCenterManagerData;
        if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
        else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
        playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    if (playerDict == nil)
        playerDict = [NSMutableDictionary dictionary];
    
    NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
    if (savedPercentComplete == nil)
        savedPercentComplete = [NSNumber numberWithDouble:0];
    
    double savedPercentCompleteValue = [savedPercentComplete doubleValue];
    if (percentComplete > savedPercentCompleteValue) {
        [playerDict setObject:[NSNumber numberWithDouble:percentComplete] forKey:identifier];
        #if !TARGET_OS_TV
            [plistDict setObject:playerDict forKey:[self localPlayerId]];
        NSData *saveData;
        saveData = [NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.cryptKeyData error:&error];
           
            [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
        #else
            [defaults setObject:playerDict forKey:[self localPlayerId]];
            [defaults synchronize];
        #endif
    }
    
    if ([self checkGameCenterAvailability:NO] == YES) {
        GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
        achievement.percentComplete = percentComplete;
        if (displayNotification == YES) achievement.showsCompletionBanner = YES;
        else achievement.showsCompletionBanner = NO;
        
        [GKAchievement reportAchievements:@[achievement] withCompletionHandler:^(NSError *error) {
            NSDictionary *dict = nil;
            
            if (error == nil) {
                dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:achievement, nil] forKeys:[NSArray arrayWithObjects:@"achievement", nil]];
            } else {
                if (achievement) {
                    dict = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:error.localizedDescription, achievement, nil] forKeys:[NSArray arrayWithObjects:@"error", @"achievement", nil]];
                }
                
                [self saveAchievementToReportLater:identifier percentComplete:percentComplete];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([[self delegate]  respondsToSelector:@selector(gameCenterManager:reportedAchievement:withError:)]) {
                        [[self delegate] gameCenterManager:self reportedAchievement:achievement withError:error];
                }
            });
            
        }];
    } else {
        [self saveAchievementToReportLater:identifier percentComplete:percentComplete];
    }
}

- (void)saveLeaderboardScoreToReportLater:(GKLeaderboardScore *)score  API_AVAILABLE(ios(14.0)){
    if(score.value == 0) {
        return;
    }
    NSError * error;
    NSData *saveData;
    saveData = [NSKeyedArchiver archivedDataWithRootObject:score requiringSecureCoding:self.cryptKeyData error:&error];
    
    NSMutableArray *savedScores;
    #if !TARGET_OS_TV
        NSData *gameCenterManagerData;
        if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
        else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
        
        NSMutableDictionary *plistDict;
        
        plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    
    
    
    
    
        savedScores = [plistDict objectForKey:@"SavedScores"];
    #else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        savedScores = [[defaults objectForKey:@"SavedScores"] mutableCopy];
    #endif
    
//    if (savedScores != nil) {
//        [savedScores addObject:scoreData];
//    } else {
//        savedScores = [NSMutableArray arrayWithObject:scoreData];
//    }
    
    #if !TARGET_OS_TV
//        [plistDict setObject:savedScores forKey:@"SavedScores"];
//        NSData *saveData;
//    saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:self.cryptKeyData];
//
    #else
        [defaults setObject:savedScores forKey:@"SavedScores"];
        [defaults synchronize];
    #endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:didSaveLeaderboardScore:)]) {
            [[self delegate] gameCenterManager:self didSaveLeaderboardScore:score];
            
        }
    });
}

- (void)saveScoreToReportLater:(GKScore *)score {
    if(score.value == 0) {
        return;
    }
    NSError * error;
    NSData *saveData;
    saveData = [NSKeyedArchiver archivedDataWithRootObject:score requiringSecureCoding:self.cryptKeyData error:&error];
    
    NSMutableArray *savedScores;
    #if !TARGET_OS_TV
        NSData *gameCenterManagerData;
        if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
        else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
        
    NSMutableDictionary *plistDict;
    
    plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
  
        savedScores = [plistDict objectForKey:@"SavedScores"];
    #else
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        savedScores = [[defaults objectForKey:@"SavedScores"] mutableCopy];
    #endif
    
//    if (savedScores != nil) {
//        [savedScores addObject:scoreData];
//    } else {
//        savedScores = [NSMutableArray arrayWithObject:scoreData];
//    }
    
    #if !TARGET_OS_TV
//        [plistDict setObject:savedScores forKey:@"SavedScores"];
//        NSData *saveData;
//    saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict] encryptedWithKey:self.cryptKeyData];
//
    #else
        [defaults setObject:savedScores forKey:@"SavedScores"];
        [defaults synchronize];
    #endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:didSaveScore:)]) {
            [[self delegate] gameCenterManager:self didSaveScore:score];
            
        }
    });
}

- (void)saveAchievementToReportLater:(NSString *)identifier percentComplete:(double)percentComplete {
    NSMutableDictionary *playerDict;
    NSError * error;
    #if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    if (playerDict != nil) {
        NSMutableDictionary *savedAchievements = [[playerDict objectForKey:@"SavedAchievements"] mutableCopy];
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
    
    #if !TARGET_OS_TV
    [plistDict setObject:playerDict forKey:[self localPlayerId]];
    NSData *saveData;
    saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.shouldCryptData error:&error] encryptedWithKey:self.cryptKeyData];
    [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
    #else
    [defaults setObject:playerDict forKey:[self localPlayerId]];
    [defaults synchronize];
    #endif
    
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
    NSNumber *percentNumber = [NSNumber numberWithDouble:percentComplete];
    
    if (percentNumber && achievement) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:savedAchievement:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [[self delegate] gameCenterManager:self savedAchievement:[NSDictionary dictionaryWithObjects:@[achievement, percentNumber] forKeys:@[@"achievement", @"percent complete"]]];
#pragma clang diagnostic pop
            } else if ([[self delegate] respondsToSelector:@selector(gameCenterManager:didSaveAchievement:)])
                [[self delegate] gameCenterManager:self didSaveAchievement:achievement];
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

- (long long)highScoreForLeaderboard:(NSString *)identifier {
    
    NSError * error;
    NSMutableDictionary *playerDict;
    #if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];

    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    
    
    playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    if (playerDict != nil) {
        NSNumber *savedHighScore = [playerDict objectForKey:identifier];
        if (savedHighScore != nil) {
            return [savedHighScore longLongValue];
        } else {
            return 0;
        }
    } else {
        return 0;
    }
}

- (NSDictionary *)highScoreForLeaderboards:(NSArray *)identifiers {
    NSError * error;
    NSMutableDictionary *playerDict;
    #if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else
        gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    NSMutableDictionary *highScores = [[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
    
    for (NSString *identifier in identifiers) {
        if (playerDict != nil) {
            NSNumber *savedHighScore = [playerDict objectForKey:identifier];
            
            if (savedHighScore != nil) {
                [highScores setObject:[NSNumber numberWithLongLong:[savedHighScore longLongValue]] forKey:identifier];
                continue;
            }
        }
        
        [highScores setObject:[NSNumber numberWithLongLong:0] forKey:identifier];
    }
    
    NSDictionary *highScoreDict = [NSDictionary dictionaryWithDictionary:highScores];
    
    return highScoreDict;
}

- (double)progressForAchievement:(NSString *)identifier {
    
    NSMutableDictionary *playerDict;
    NSError * error;
    #if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
    if (playerDict != nil) {
        NSNumber *savedPercentComplete = [playerDict objectForKey:identifier];
        
        if (savedPercentComplete != nil) {
            return [savedPercentComplete doubleValue];
        }
    }
    return 0;
}

- (NSDictionary *)progressForAchievements:(NSArray *)identifiers {
    NSMutableDictionary *playerDict;
    NSError * error;
    #if !TARGET_OS_TV
    NSData *gameCenterManagerData;
    if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
    else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
    NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
    playerDict = [plistDict objectForKey:[self localPlayerId]];
    #else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
    #endif
    
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

- (void)getChallengesWithCompletion:(void (^)(NSArray *challenges, NSError *error))handler {
    if ([self checkGameCenterAvailability:NO] == YES) {
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
#if TARGET_OS_IPHONE
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GKChallenge Class is not available. GKChallenge is only available on iOS 6.0 and higher. Current iOS version: %@", [[UIDevice currentDevice] systemVersion]] code:GCMErrorFeatureNotAvailable userInfo:nil];
#else
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GKChallenge Class is not available. GKChallenge is only available on OS X 10.8.2 and higher."] code:GCMErrorFeatureNotAvailable userInfo:nil];
#endif
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
//------- Presenting GameKit Controllers ---------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Presenting GameKit Controllers
#if TARGET_OS_IPHONE

- (void)presentAchievementsOnViewController:(UIViewController *)viewController {
    GKGameCenterViewController *achievementsViewController = [[GKGameCenterViewController alloc] init];
    #if TARGET_OS_IOS || (TARGET_OS_IPHONE && !TARGET_OS_TV)
    achievementsViewController.viewState = GKGameCenterViewControllerStateAchievements;
    #endif
    achievementsViewController.gameCenterDelegate = self;
    [viewController presentViewController:achievementsViewController animated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterViewControllerPresented:)])
                [[self delegate] gameCenterManager:self gameCenterViewControllerPresented:YES];
        });
    }];
}


- (void)presentLeaderboardsOnViewController:(UIViewController *)viewController withLeaderboard:(NSString *)leaderboard {
    GKGameCenterViewController *leaderboardViewController = [[GKGameCenterViewController alloc] init];
    #if TARGET_OS_IOS || (TARGET_OS_IPHONE && !TARGET_OS_TV)
    leaderboardViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
    /*
     Passing nil to leaderboardViewController.leaderboardIdentifier works fine,
     but to make sure futur updates will not brake, we'll check it first
     */
    if (leaderboard != nil) {
        leaderboardViewController.leaderboardIdentifier = leaderboard;
    }
    #elif TARGET_OS_TV
         #warning For tvOS you must set leaderboard ID's in the Assets catalogue - Click on this warning for more info.
        /**
         To get the Leaderboards to show up:
         1. Achievements and Leaderboards are merged into a single GameCenter view, with the Leaderboards shown above the achievements.
         2. For tvOS adding the Leaderboards to the GameViewController is all about the Image Assets.
         3. You must add a "+ -> GameCenter -> New Apple TV Leaderboard (or Set)." to your Image Asset.
         4. You must set the "Identifier" for this Leaderboard asset to exactly what your identifier is for each of your leaderboards. Example:
         grp.GameCenterManager.PlayerScores
         5. You must have the image sizes 659 × 371 for the Leaderboard Images.*/
    #endif
    leaderboardViewController.gameCenterDelegate = self;
    [viewController presentViewController:leaderboardViewController animated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterViewControllerPresented:)])
                [[self delegate] gameCenterManager:self gameCenterViewControllerPresented:YES];
        });
    }];
}

- (void)presentChallengesOnViewController:(UIViewController *)viewController {
    GKGameCenterViewController *challengeViewController = [[GKGameCenterViewController alloc] init];
    #if TARGET_OS_IOS || (TARGET_OS_IPHONE && !TARGET_OS_TV)
    challengeViewController.viewState = GKGameCenterViewControllerStateChallenges;
    #endif
    challengeViewController.gameCenterDelegate = self;
    [viewController presentViewController:challengeViewController animated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterViewControllerPresented:)])
                [[self delegate] gameCenterManager:self gameCenterViewControllerPresented:YES];
        });
    }];
}
#endif

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
#if TARGET_OS_IPHONE
    [gameCenterViewController dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterViewControllerDidFinish:)])
                [[self delegate] gameCenterManager:self gameCenterViewControllerDidFinish:YES];
        });
    }];
#else
    [gameCenterViewController dismissViewController:gameCenterViewController];
     dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:gameCenterViewControllerDidFinish:)])
            [[self delegate] gameCenterManager:self gameCenterViewControllerDidFinish:YES];
    });
#endif
}

//------------------------------------------------------------------------------------------------------------//
//------- Resetting Data -------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------------------//
#pragma mark - Resetting Data

- (void)resetAchievementsWithCompletion:(void (^)(NSError *))handler {
    if ([self isGameCenterAvailable]) {
        [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
            if (error == nil) {
                NSMutableDictionary *playerDict;
                
                #if !TARGET_OS_TV
                NSData *gameCenterManagerData;
                if (self.shouldCryptData == YES) gameCenterManagerData = [[NSData dataWithContentsOfFile:kGameCenterManagerDataPath] decryptedWithKey:self.cryptKeyData];
                else gameCenterManagerData = [NSData dataWithContentsOfFile:kGameCenterManagerDataPath];
                NSMutableDictionary *plistDict = [NSKeyedUnarchiver unarchivedObjectOfClass:NSData.class fromData:gameCenterManagerData error:&error];
                playerDict = [plistDict objectForKey:[self localPlayerId]];
                #else
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                playerDict = [[defaults objectForKey:[self localPlayerId]] mutableCopy];
                #endif
                
                if (playerDict == nil) {
                    playerDict = [NSMutableDictionary dictionary];
                }
                
                for (GKAchievement *achievement in achievements) {
                    [playerDict removeObjectForKey:achievement.identifier];
                }
                
                #if !TARGET_OS_TV
                [plistDict setObject:playerDict forKey:[self localPlayerId]];
                NSData *saveData;
                
                    saveData = [[NSKeyedArchiver archivedDataWithRootObject:plistDict requiringSecureCoding:self.shouldCryptData error:&error] encryptedWithKey:self.cryptKeyData];

                
                [saveData writeToFile:kGameCenterManagerDataPath atomically:YES];
                #else
                [defaults setObject:playerDict forKey:[self localPlayerId]];
                [defaults synchronize];
                #endif
                
                [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
                    if (error == nil) {
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:[@"achievementsSynced" stringByAppendingString:[self localPlayerId]]];
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

- (NSString *)localPlayerId {
    if ([self isGameCenterAvailable]) {
        if ([GKLocalPlayer localPlayer].authenticated) {
            if (@available(iOS 12.4, *)) {
                return [GKLocalPlayer localPlayer].teamPlayerID;
            } else {
                // Fallback on earlier versions
                return [GKLocalPlayer localPlayer].playerID;
            }
        }
    }
    return @"unknownPlayer";
}

- (NSString *)localPlayerDisplayName {
    if ([self isGameCenterAvailable] && [GKLocalPlayer localPlayer].authenticated) {
        if ([[GKLocalPlayer localPlayer] respondsToSelector:@selector(displayName)]) {
            return [GKLocalPlayer localPlayer].displayName;
        } else {
            return [GKLocalPlayer localPlayer].alias;
        }
    }
    
    return @"unknownPlayer";
}

- (GKLocalPlayer *)localPlayerData {
    if ([self isGameCenterAvailable] && [GKLocalPlayer localPlayer].authenticated) {
        return [GKLocalPlayer localPlayer];
    } else {
        return nil;
    }
}

#if TARGET_OS_IPHONE
- (void)localPlayerPhoto:(void (^)(UIImage *playerPhoto))handler {
    if ([self isGameCenterAvailable]) {
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
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[self delegate] gameCenterManager:self error:error];
    }
}
#else
- (void)localPlayerPhoto:(void (^)(NSImage *playerPhoto))handler {
    if ([self isGameCenterAvailable]) {
        [[self localPlayerData] loadPhotoForSize:GKPhotoSizeNormal withCompletionHandler:^(NSImage *photo, NSError *error) {
            handler(photo);
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
                        [[self delegate] gameCenterManager:self error:error];
                });
            }
        }];
    } else {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[self delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[self delegate] gameCenterManager:self error:error];
    }
}
#endif

@end
