//
//  ViewController.h
//  GameCenterManager
//
//  Created by iRare Media on Sepetmber 21, 2013.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GameCenterManager.h"

@interface ViewController : UIViewController <GKGameCenterControllerDelegate, UIActionSheetDelegate, GameCenterManagerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *statusDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionBarLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *playerPicture;
@property (weak, nonatomic) IBOutlet UILabel *playerName;
@property (weak, nonatomic) IBOutlet UILabel *playerStatus;

@end
