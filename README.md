GameCenter Manager
=========================

GameCenter Manager helps to manage Game Center in iOS and Mac apps. Report and keep track of high scores, achievements, and challenges for different players. GameCenter Manager also takes care of the heavy lifting - checking internet availability, saving data when offline and uploading it when online, etc. In future updates, GameCenter Manager will make it easy to setup and run live Game Center Multiplayer matches.

<img width=750 src="https://github.com/iRareMedia/GameCenterManager/blob/master/Interface.png?raw=true"/>

Setup
------------

1. Add the `GameKit` and `SystemConfiguration` frameworks to your Xcode project  
2. Add the following classes (can be found in the *GC Manager* folder) to your Xcode project (make sure to select Copy Items in the dialog):  
     -  GameCenterManager
     -  Reachability 
     -  NSDataAES256  
3. Open the `GameCenterManager.h` file and change the `kGameCenterManagerKey` constant to the secret key you want to use for encryption / decryption
4. Import the `GameCenterManager.h` file
5. Initialize GameCenter Manager and begin Syncing by using the following method call:

        [[GameCenterManager sharedManager] initGameCenter];

6. Add the delegate `GameCenterManagerDelegate` to your header file, then set the delegate in your implementation and add any delegate methods you'd like to use (see **Delegates**):

        [[GameCenterManager sharedManager] setDelegate:self];

Using the Demo App
------------

GameCenter Manager's demo app makes it easier to test Game Center integration with GameCenter Manager on both Mac and iOS. It also lays out how to use the `GameCenterManager` class. We recommend that you leave the Bundle ID provided with the Demo App as-is. This Bundle ID is already linked to a Game Center game in iTunes Connect with scores and achievements. You may, however, substitute your own Bundle ID and entitlements file.

Documentation
-----
All methods, properties, types, and delegate methods available on the GameCenterManager class are documented below. If you're using [Xcode 5](https://developer.apple.com/technologies/tools/whats-new.html) with GameCenterManager, documentation is available directly within Xcode (just Option-Click any method for Quick Help).

###Initialize GameCenterManager
You should initialize GameCenterManager when your app is launched

    [[GameCenterManager sharedManager] initGameCenter];

This checks if Game Center is supported in the current device, authenticates the player and synchronizes scores and achievements from Game Center if its being run for the first time.

###Check Game Center Support
GameCenter Manager automatically checks if Game Center is available before performing any Game Center-related operations. You can also check for Game Center availability by using the following method, which returns a `BOOL` value (YES / NO).

    BOOL isAvailable = [[GameCenterManager sharedManager] checkGameCenterAvailability];

This method will perform the following checks in the following order:
 1. Current OS version new enough to run Game Center. iOS 4.1 or OS X 10.8. Some Game Center methods require newer OS versions which will be checked (ex. challenges and some multiplayer features).
 2. GameKit API availability. The `GKLocalPlayer` class must be available at a minimum.
 3. Internet Connection. The `Reachability` class is used to determine if there is an active internet connection. GameCenterManager will still work without internet, however all saved data can only be uploaded with an internet connection.
 4. Local Player. Check to make sure a local player is logged in and authenticated.  

This method may return **NO** in many cases. Use the `gameCenterManager:availabilityChanged:` delegate method to get an `NSDictionary` containing information about why Game Center is or isn't available. Refer to the section on delegate methods below.

###Report Score
Report a score to Game Center using a Game Center Leaderboard ID. The score is saved locally then uploaded to Game Center (if Game Center is available). 

    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"Leaderboard ID"  sortOrder:GameCenterSortOrder];

Set the Game Center Sort Order (either `GameCenterSortOrderHighToLow` or `GameCenterSortOrderLowToHigh`)  to report a score to Game Center only if the new score is better than the best one (depending on the sort order). There is no need for you to find out if a user has beat their highscore before submitting it - GameCenterManager will determine if the score should be submitted based on the parameters provided.

###Report Achievement
Report an achievement to Game Center using a Game Center Achievement ID. The achievement and its percent complete are saved locally then uploaded to Game Center (if Game Center is available). 

    [[GameCenterManager sharedManager] saveAndReportAchievement:@"Achievement ID" percentComplete:50];

The `percentComplete` parameter specifies how much progress the user has made on an achievement. Specifiying a value of 100 will mark the achievement as completed. Values submitted between 1-99 will display in Game Center and show the user that they need to make more progress to earn an achievement. if you specify an achievement percent complete lower than the current percent complete, it will be ignored by Game Center.

###Get High Scores
You can get high scores from multiple leaderboards or just one leaderboard. In both cases you'll need to provide Leaderboard IDs. GameCenterManager will return either an NSDictionary with integer scores, or one integer score. To get the high scores for the current player from multiple leaderboards:

    // Array of leaderboard ID's to get high scores for
    NSArray *leaderboardIDs = [NSArray arrayWithObjects:@"Leaderboard1", @"Leaderboard2", nil];

    // Returns a dictionary with leaderboard ID's as keys and high scores as values
    NSDictionary *highScores = [[GameCenterManager sharedManager] highScoreForLeaderboards:leaderboardIDs];  

To get the high score for the current player for a single leaderboard:

    // Returns an integer value as a high scores
    int highScore = [[GameCenterManager sharedManager] highScoreForLeaderboard:@"LeaderboardID"];  

###Get Achievement Progress
You can get achievement progress for multiple achievements or just one achievement. In both cases you'll need to provide Achievement IDs. GameCenterManager will return either an NSDictionary with double values, or one double value. To get the achievement progress for the current player from multiple achievements:

    // Array of achievement ID's to get progress for
    NSArray *achievementIDs = [NSArray arrayWithObjects:@"Achievement1", @"Achievement2", nil];

    // Returns a dictionary with achievement ID's as keys and progresses as values
    NSDictionary *achievementsProgress = [[GameCenterManager sharedManager] progressForAchievements:achievementIDs];  

To get the achievement progress for the current player for a single achievement:

    // Returns a double value as achievement progress
    double progress = [[GameCenterManager sharedManager] highScoreForLeaderboard:@"LeaderboardID"];  

###Reset Achievements
Erase and reset all achievement progress from Game Center. Be warned though, the `resetAchievements:` method does not prompt the user before resetting - you must do this on your own.  Currently, achievements are properly removed from Game Center, however a caching issue causes them to remain locally. Please submit a pull request if you can fix this issue.

    [[GameCenterManager sharedManager] resetAchievementsWithCompletionHandler:^(NSError *error) {
        if (error) NSLog(@"Error: %@", error);
    }];

When the `resetAchievements:` method is called and resets all achievements, the completion handler is fired. Use the completion handler for retrieving errors or updating user interface elements (ex. updating a table view listing completed achievements). 

###Get Challenges
Get challenges for the current game and player on iOS 6 and higher (GameCenterManager will check if challenges are supported on the current device). This method uses a completion handler to pass data (either an `NSError` or `NSArray` with the challenges. If the `GKChallenge` class or GameCenter is not available, the `gameCenterManager: error:` delegate method is called.

    // Gets an array with challenges and passes the value to a completion handler.
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        NSLog(@"Challenges: %@ \n Error: %@", challenges, error);
    }];

 If there is an error retrieving the challenges, the `NSArray` will be `nil` and the `NSError` will contain an error. The `NSError` passed here is an error generated by Game Center, not GameCenterMananger
 
##Player Data
GameCenterManager provides four different methods to retrieve various bits of data about the current local player. Retrieve a player ID using the following method, but **never** display a player ID in your interface or expose the ID in any way at all - it should only be used to identify a player. If you display a player ID in your app, it will be rejected from the AppStore.

    NSString *playerID = [[GameCenterManager sharedManager] localPlayerId];  

To get the player's display name (alias on iOS lower than iOS 6.0) use this method:

    NSString *playerName = [[GameCenterManager sharedManager] localPlayerDisplayName];  

To get the player's profile picture the following method. On iOS, the completion handler passes a `UIImage`, on OS X the completion handler passes an `NSImage`. The image passed to you is at full resolution.

    [self localPlayerPhoto:^(UIImage *playerPhoto) { // On OS X, the completion handler pases an NSImage instead of a UIImage
        UIImageView *imageView = [[UIImageView alloc] initWithImage:playerPhoto];
    }];    

To get any other data about a player use this method:

    GKLocalPlayer *player = [[GameCenterManager sharedManager] localPlayerData]; 

Delegates
-----
GameCenterManager delegate methods notify you of the status of Game Center and various other tasks. There is only one required delegate method for iOS, none for OS X.

<table>
  <tr><th colspan="2" style="text-align:center;">Required Delegate Methods</th></tr>
  <tr>
    <td>Authenticate User (iOS only)</td>
    <td> If the user is not logged into Game Center, you'll need to present the Game Center login view controller. This method is required because the user must be logged in for Game Center to work. If the user does not login, an error will be returned.  
     <br /><br />
           <tt> - (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController</tt></td>
  </tr>
    <tr><th colspan="2" style="text-align:center;">Optional Delegate Methods</th></tr>
  <tr>
    <td>Availability Changed</td>
    <td>When the availability status of Game Center changes, this delegate method is called. The availability of Game Center depends on multiple factors including: <br />
    <ul>
    <li> Internet Connection</li>
    <li> iOS Version (4.1+ required)</li>
    <li> Player Authentication</li>
    <li> Game Authentication</li>
    </ul>
  <br />
    The NSDictionary object, <tt>availabilityInformation</tt>, contains two objects, a <tt>message</tt> and a <tt>title</tt>. The `message` object is an NSString describing the availability issue. The <tt>title</tt> is a shorter description of the error; it is also an NSString.
       <br /><br />
            <tt>- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation</tt></td>
  </tr>
  <tr>
    <td>Game Center Error</td>
    <td>When there is an error performing a Game Center task this delegate method is executed.
  <br />
    The <tt>error</tt> NSError object contains an error code (refer to the section on Constants below), a description (error domain) and sometimes user information.
       <br /><br />
           <tt> - (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error</tt></td>
  </tr>
  <tr>
    <td>Reported Score</td>
    <td>Called after the submitted score is successfully saved, uploaded, and posted to Game Center. 
  <br />
    The GKScore object, <tt>score</tt>, is the final score that was saved. The error object may contain an error if one occured, or it may be nil.
       <br /><br />
            <tt>- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(GKScore *)score withError:(NSError *)error;</tt></td>
  </tr>
  <tr>
    <td>Saved Score</td>
    <td>Called after the submitted score is successfully saved, but not posted or uploaded to Game Center. The saved score will be uploaded the next time GC Manager can successfully connect to Game Center. 
  <br />
    The GKScore object, <tt>score</tt> contains information about the submitted score.
       <br /><br />
          <tt> - (void)gameCenterManager:(GameCenterManager *)manager didSaveScore:(GKScore *)score</tt></td>
  </tr>
    <tr>
    <td>Reported Achievement</td>
    <td>Called after the submitted achievement and its percent complete is successfully saved, uploaded, and posted to Game Center. 
  <br />
    The GKAchievement object, <tt>achievement</tt>, is the final achievement that was saved. The error object may contain an error if one occured, or it may be nil.
       <br /><br />
            <tt>- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(GKAchievement *)achievement withError:(NSError *)error</tt></td>
  </tr>
  <tr>
    <td>Saved Achievement</td>
    <td>Called after the submitted achievement is successfully saved, but not posted or uploaded to Game Center. The saved achievement and its percent completed will be uploaded the next time GC Manager can successfully connect to Game Center. 
  <br />
    The GKAchievement object, <tt>achievement</tt>, is the final achievement that was saved.
       <br /><br />
          <tt>- (void)gameCenterManager:(GameCenterManager *)manager didSaveAchievement:(GKAchievement *)achievement</tt></td>
  </tr>
</table>

Constants
-----
Constants are used throughout GameCenterManager in error messages and method parameters.

###Score Sort Order
The order in which your leaderboard scores are sorted. This helps GameCenterManager decide how to submit a score to a leaderboard (and determine if it is a highscore).  
    - `GameCenterSortOrderHighToLow` sorts scores from highest to lowest  
    - `GameCenterSortOrderLowToHigh` sorts scores from lowest to highest  

###Error Codes
When the `gameCenterManager: error:` delegate is called, one of the following error codes are passed.  
    -  `GCMErrorUnknown` (0) an unknown error occured  
    -  `GCMErrorNotAvailable` (1) the feature is not available or GameCenter is not available  
    -  `GCMErrorFeatureNotAvailable` (2) the request feature is not available, check error message for info  
    -  `GCMErrorInternetNotAvailable` (3) no internet connection
    -  `GCMErrorAchievementDataMissing` (3) could not save achievement because the data was formatted improperly or is missing

Changelog
-----
See the `Changelog.md` file for details on updates. For the most updated information, take a look at the project releases.

License and Attribution
-----

See the `License.md` file for details on licensing this work / project, and attribution to other projects.
