//
//  MacViewController.h
//  GameCenterManager
//
//  Created by Sam Spencer on 1/17/15.
//  Copyright (c) 2015 NABZ Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GameCenterManager.h"

@interface MacViewController : NSViewController <NSApplicationDelegate, GameCenterManagerDelegate, GKGameCenterControllerDelegate>

@property (weak) IBOutlet NSTextField *gameCenterStatus;
@property (weak) IBOutlet NSTextField *detailedStatus;
@property (weak) IBOutlet NSTextField *actionStatus;
@property (weak) IBOutlet NSTextField *playerName;
@property (weak) IBOutlet NSTextField *playerStatus;
@property (weak) IBOutlet NSImageView *playerProfilePicture;

- (IBAction)submitHighscore:(id)sender;
- (IBAction)submitAchievement:(id)sender;
- (IBAction)resetAchievements:(id)sender;
- (IBAction)openLeaderboards:(id)sender;
- (IBAction)openAchievements:(id)sender;
- (IBAction)fetchChallenges:(id)sender;

@end
