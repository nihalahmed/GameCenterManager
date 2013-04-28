//
//  ViewController.h
//  GameCenterManager
//
//  Created by Nihal Ahmed on March 17, 2012. Edited and updated by iRare Media on April 28, 2013.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UILabel *statusLabel;

@end
