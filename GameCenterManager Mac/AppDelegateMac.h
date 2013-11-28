//
//  AppDelegate.h
//  GameCenterManager Mac
//
//  Created by iRare Media on 7/2/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GameCenterManager.h"

@interface AppDelegateMac : NSObject <NSApplicationDelegate, GameCenterManagerDelegate, GKGameCenterControllerDelegate, GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTextField *gcStatusTitle;
@property (strong) IBOutlet NSTextField *gcStatusMessage;
@property (strong) IBOutlet NSTextField *gcActionInfo;
@property (weak) IBOutlet NSImageView *playerPicture;
@property (weak) IBOutlet NSTextField *playerName;
@property (weak) IBOutlet NSTextField *playerStatus;

- (IBAction)reportScore:(id)sender;
- (IBAction)showLeaderboard:(id)sender;
- (IBAction)reportAchievement:(id)sender;
- (IBAction)showAchievements:(id)sender;
- (IBAction)resetAchievements:(id)sender;
- (IBAction)loadChallenges:(id)sender;

@end
