//
//  ViewController.h
//  GameCenterManager
//
//  Created by Nihal Ahmed on March 17, 2012. Edited and updated by iRare Media on April 28, 2013.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate, UIActionSheetDelegate, GameCenterManagerDelegate>

@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIImageView *header;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *playerPicture;
@property (weak, nonatomic) IBOutlet UILabel *playerName;
@property (weak, nonatomic) IBOutlet UILabel *playerStatus;

@end
