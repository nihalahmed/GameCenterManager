GameCenterManager
=========================

GameCenterManager helps you manage the Game Center aspect of your game. It makes it easy to report and keep track of high scores and achievements for different players.

Features
--------

- Separate profile for each player
- Local profile if Game Center is unsupported or nobody is logged on to Game Center
- Scores and achievements saved if no internet connection available or error occurred while reporting to Game Center
- Synchronization of Game Center data on first run
- Encryption of data

Installation
------------

1. Add the `GameKit` and `SystemConfiguration` frameworks to your Xcode project

2. Add the following files to your Xcode project (make sure to select Copy Items in the dialog):
 - GameCenterManager.h  
 - GameCenterManager.m
 - Reachability.h
 - Reachability.m
 - NSDataAES256.h
 - NSDataAES256.m

3. Open the `GameCenterManager.h` file and change the `kGameCenterManagerKey` constant to the secret key you want to use for encryption/decryption

4. Import the `GameCenterManager.h` file

Usage
-----

###Initialize GameCenterManager
You should initialize GameCenterManager when your app is launched, preferably in the `application didFinishLaunchingWithOptions` method by calling

    [[GameCenterManager sharedManager] initGameCenter];  

This checks if Game Center is supported in the current device, authenticates the player and synchronizes scores and achievements from Game Center if its being run for the first time.

###Check Game Center Support
To check for Game Center support you can call

    [[GameCenterManager sharedManager] isGameCenterAvailable];  


###Report Score
To report a score to Game Center, call

    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"HighScores"];  

This method saves the score locally as well.

###Report Achievement
To report an achievement to Game Center, call

    [[GameCenterManager sharedManager] saveAndReportAchievement:@"1000Points" percentComplete:50];  

This method saves the achievement progress locally as well.

###Get High Scores
To get the high scores for the current player, you can call

    //Array of leaderboard ID's to get high scores for
    NSArray *leaderboardIDs = [NSArray arrayWithObjects:@"Leaderboard1", @"Leaderboard2", nil];

    //Returns a dictionary with leaderboard ID's as keys and high scores as values
    [[GameCenterManager defaultManager] highScoreForLeaderboards:leaderboardIDs];  

###Get Achievement Progress
To get achievement progress for the current player, you can call

    //Array of achievement ID's to get progress for
    NSArray *achievementIDs = [NSArray arrayWithObjects:@"Achievement1", @"Achievement2", nil];

    //Returns a dictionary with achievement ID's as keys and progress as values
    [[GameCenterManager defaultManager] progressForAchievements:achievementIDs];  

###Notifications
Notifications are posted at certain events mentioned below. The `userInfo` dictionary contains an error string for the key `error` if an error occured.

1. kGameCenterManagerAvailabilityNotification - When unsupported devices attempt to authenticate the player, the `isGameCenterAvailable` property is set to `NO`
2. kGameCenterManagerReportScoreNotification - When a score is reported to Game Center
3. kGameCenterManagerReportAchievementNotification - When an achievement is reported to Game Center
4. kGameCenterManagerResetAchievementNotification - When achievements are reset

Attribution
-----

Reachability Class from https://github.com/tonymillion/Reachability  
The GameCenter Icon is a registered Apple Trademark

Changelog
-----

###Version 3.0
Added ARC compatibility. All files are now ready to be used with ARC. Many methods have been updated that were depreciated in iOS 6.0. The demo app has undergone massive improvements, including many interface improvements, iPhone 5 support, a new icon, and better GC status reporting. 

###Version 2.3
Fixed leaderboard synchronization bug where it would crash if user didn't submit a score previously  
###Version 2.2
Fixed leaderboard synchronization bug where it would only sync the default leaderboard  
###Version 2.1
Fixed NSNotification Bug  
###Version 2.0
Added encryption, fixed synchronization bug and added comments and readme

###Version 1.0
Initial Commit