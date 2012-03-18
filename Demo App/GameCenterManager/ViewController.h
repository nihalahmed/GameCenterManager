//
//  ViewController.h
//  GameCenterManager
//
//  Created by Nihal Ahmed on 12-03-17.
//  Copyright (c) 2012 NABZ Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate> {
    UILabel *_lbl;
}

@end
