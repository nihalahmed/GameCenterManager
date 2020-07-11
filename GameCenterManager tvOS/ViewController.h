//
//  ViewController.h
//  GameCenterManager
//
//  Created by iRare Media on Sepetmber 21, 2013.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//  Copyright (c) 2015 Daniel Rosser. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GameCenterManagerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *statusDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionBarLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *playerPicture;
@property (weak, nonatomic) IBOutlet UILabel *playerName;
@property (weak, nonatomic) IBOutlet UILabel *playerStatus;
@property (weak, nonatomic) IBOutlet UILabel *tvOSInfo;

@property (weak, nonatomic) IBOutlet UIButton *buttonReportScore;
@property (weak, nonatomic) IBOutlet UIButton *buttonReportAchievement;
@property (weak, nonatomic) IBOutlet UIButton *buttonFetchChallenges;
@property (weak, nonatomic) IBOutlet UIButton *buttonOpenLeaderboards;
@property (weak, nonatomic) IBOutlet UIButton *buttonOpenAchievements;
@property (weak, nonatomic) IBOutlet UIButton *buttonResetAchievements;

@end
