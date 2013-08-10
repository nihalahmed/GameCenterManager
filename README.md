Game Center Manager
=========================

Game Center Manager helps you manage Game Center in your iOS or Mac app. It makes it easy to report and keep track of high scores achievements, and challenges for different players. Game Center Manager also takes care of the heavy lifting - checking internet availability, saving data when offline and uploading it when online, etc. In future updates, Game Center Manager will make it easy to setup and run live Game Center Multiplayer matches.

<img width=750 src="https://github.com/iRareMedia/GameCenterManager/blob/master/Interface.png?raw=true"/>

Setup
------------

1. Add the `GameKit` and `SystemConfiguration` frameworks to your Xcode project  
2. Add the following classes (can be found in the *GC Manager* folder) to your Xcode project (make sure to select Copy Items in the dialog):  
     -  GameCenterManager (GameCenterManager-Mac on OS X)  
     -  Reachability 
     -  NSDataAES256  
3. Open the `GameCenterManager.h` (`GameCenterManager-Mac.h` on OS X) file and change the `kGameCenterManagerKey` constant to the secret key you want to use for encryption/decryption  
4. Import the `GameCenterManager.h` file (`GameCenterManager-Mac.h` on OS X)  
5. Initialize GameCenter Manager and begin Syncing by using the following method call  (preferrably in your `appDidFinishLaunching` method of your AppDelegate):

        [[GameCenterManager sharedManager] initGameCenter];

6. Add the delegate `GameCenterManagerDelegate` to your header file, then set the delegate in your implementation and add any delegate methods you'd like to use (see **Delegates**):

        [[GameCenterManager sharedManager] setDelegate:self];

Using the Demo App
------------

Game Center Manager's demo app makes it easier to test Game Center integration with Game Center Manager on both Mac and iOS. It also lays out how to use the `GameCenterManager` class. We recommend that you leave the Bundle ID provided with the Demo App as-is. This Bundle ID is already linked to a Game Center game in iTunes Connect with scores and achievements. You may, however, substitute your own Bundle ID and entitlements file.

Documentation
-----
All methods, properties, types, and delegate methods available on the GameCenterManager class are documented below. If you're using [Xcode 5](https://developer.apple.com/technologies/tools/whats-new.html) with GameCenterManager, documentation is available directly within Xcode (just Option-Click any method for Quick Help).

###Initialize GameCenterManager
You should initialize GameCenterManager when your app is launched, preferably in the `application didFinishLaunchingWithOptions` method.

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

This method may return **NO** in many cases. Use the `gameCenterManager: availabilityChanged:` delegate method to get an `NSDictionary` containing information about why Game Center is or isn't available. Refer to the section on delegate methods below.

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
Erase and reset all achievement progress from Game Center. This method is still under development, and is **NOT ready for use**. Currently, achievements are properly removed from Game Center, however a caching issue causes them to remain locally. Please submit a pull request if you can fix this issue.

    [[GameCenterManager sharedManager] resetAchievements];

###Get Challenges
Get challenges for the current game and player on iOS 6 and higher (GameCenterManager will check if challenges are supported on the current device). This method uses a completion handler to pass data (either an `NSError` or `NSArray` with the challenges. If the `GKChallenge` class or GameCenter is not available, the `gameCenterManager: error:` delegate method is called.

    // Gets an array with challenges and passes the value to a completion handler.
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        NSLog(@"Challenges: %@ \n Error: %@", challenges, error);
    }];

 If there is an error retrieving the challenges, the `NSArray` will be `nil` and the `NSError` will contain an error. The `NSError` passed here is an error generated by Game Center, not GameCenterMananger
 
##Player Data
GameCenterManager provides four different methods to retrieve various bits of data about the current local player. Retrieve a player ID using the following method, but **never** display a player ID in your interface or expose the ID in any way at all - it should only be used to identify a player.

    NSString *playerID = [[GameCenterManager sharedManager] localPlayerId];  

To get the player's display name (alias on iOS lower than iOS 6.0) use this method:

    NSString *playerName = [[GameCenterManager sharedManager] localPlayerDisplayName];  

To get the player's profile picture the following method. On iOS, the completion handler passes a `UIImage`, on OS X the completion handler passes an `NSImage`. The image passed to you is at full resolution.

    [self localPlayerPhoto:^(UIImage *playerPhoto) {
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
    The NSDictionary, <tt>scoreInformation</tt>, contains one NSError object, <tt>error</tt>, which may be nil if there is no error. It also contains a GKScore object, <tt>score</tt>, which contains information about the submitted score.
       <br /><br />
            <tt>- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation</tt></td>
  </tr>
  <tr>
    <td>Saved Score</td>
    <td>Called after the submitted score is successfully saved, but not posted or uploaded to Game Center. The saved score will be uploaded the next time GC Manager can successfully connect to Game Center. 
  <br />
    The GKScore object, <tt>score</tt> contains information about the submitted score.
       <br /><br />
          <tt> - (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score</tt></td>
  </tr>
    <tr>
    <td>Reported Achievement</td>
    <td>Called after the submitted achievement and its percent complete is successfully saved, uploaded, and posted to Game Center. 
  <br />
    The NSDictionary, <tt>achievementInformation</tt>, contains one NSError object, <tt>error</tt>, which may be nil if there is no error. It also contains a GKAchievement object, <tt>achievement</tt>, which contains information about the submitted achievement.
       <br /><br />
            <tt>- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation</tt></td>
  </tr>
  <tr>
    <td>Saved Achievement</td>
    <td>Called after the submitted achievement is successfully saved, but not posted or uploaded to Game Center. The saved achievement and its percent completed will be uploaded the next time GC Manager can successfully connect to Game Center. 
  <br />
    The NSDictionary object, <tt>achievementInformation</tt> contains a double, <tt>percent complete</tt>, which is the percent completed on the specified and saved achievement. It also contains a GKAchievement object, <tt>achievement</tt>, which contains information about the submitted achievement.
       <br /><br />
          <tt>- (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation</tt></td>
  </tr>
    <tr>
    <td>Reset All Achievements</td>
    <td>When the <tt>resetAchievements</tt> method is called and resets all achievements successfully, this delegate method is fired. This method may be useful for updating user interface elements (ex. updating a table view listing completed achievements). Be warned though, the <tt>resetAchievements</tt> method does not prompt the user before resetting - you must do this on your own. 
       <br /><br />
        <tt> - (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error</tt></td>
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
    -   `GCMErrorInternetNotAvailable` (3) no internet connection  
    -   `GCMErrorAchievementDataMissing` (3) could not save achievement because the data was formatted improperly or is missing

Changelog
-----

<table>
  <tr><th colspan="2" style="text-align:center;"><b>Version 5.0</b></th></tr>
  <tr>
    <td>This update adds support for Game Center on Mac OS X and makes improvements to the iOS demo app. Improvements have also been made to error reporting, challenges, and player data.</br> 
    <ul>
   <li>Adds support for Mac OS X. Use the <i>GameCenterManager Mac</i> folder to access resources for the OS X compatible version of GameCenterManager. This also includes an OS X demo app that works with the iOS demo app.</li>
    <li>Improved Game Center Error Reporting. The <tt>gameCenterManager: error:</tt> delegate method now passes an <tt>NSError</tt> as the error parameter instead of an <tt>NSDictionary</tt>. New <tt>GCMError</tt> constants are provided as error codes in each error.</li>
   <li>Makes improvements to thread management and background tasks - heavy background tasks like syncing to GameCenter (which involve networking, encryption, and file system management) are performed on the background thread and will continue to finish the process even after the user exits the app. </li>
    <li>Fixed bug where the <tt>getChallenges</tt> method would always return <tt>nil</tt>. The <tt>getChallenges:</tt> method no longer returns a value - instead it uses a completion handler and delegate methods.</li>
    <li>Added a new method to retrieve a player's profile picture, <tt>localPlayerPhoto:(void (^)(UIImage *playerPhoto))handler</tt></li>
    <li>Fixed bug where achievements may not sync, esp. after resetting achievements.</li>
    <li>Reorganized code</li>
    </ul>
    <strong>Known Issues</strong> <br /> Resetting achievements causes them to reset on Game Center, but the cache remains locally. This cahce eventually causes all achievement data to be uploaded to Game Center.
    </td>
  </tr>
</table>

<table>
<tr><th colspan="2" style="text-align:center;">Version 4.4</th></tr>
  <tr>
    <td>Fixed issue where new GKLeaderboard object's category property was being set to the saved GKLeaderboard object. Pull Request from <a href="https://github.com/iRareMedia/GameCenterManager/commit/de340432189d093df852f864cb6d1f10efd7223b">michaelpatzer</a></td>
  </tr>
<tr><th colspan="2" style="text-align:center;">Version 4.3</th></tr>
  <tr>
    <td>Added support for Game Center Leaderboard score orders. When submitting scores you can now set the score order from High to Low or Low to High using new Game Center types: <tt>GameCenterSortOrderHighToLow</tt>, <tt>GameCenterSortOrderLowToHigh</tt>. Pull Request from <a href="https://github.com/iRareMedia/GameCenterManager/commit/667b64cc248573e01f3f14b84914fffcc02d3480">michaelpatzer</a></td>
  </tr>
<tr><th colspan="2" style="text-align:center;">Version 4.2</th></tr>
  <tr>
    <td>Fixed issue where Game Center Manager would fail to handle authentication after calling the <tt>authenticateHandler</tt>. Pull Request by Jonathan Swafford</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Version 4.1</th></tr>
  <tr>
    <td>Fixed issue where Game Center Manager would fail to report achievements and scores even if Game Center was available.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><b>Version 4.0</b></th></tr>
  <tr>
    <td>This update makes massive improvements to the flow and performance of code, updates Objective-C compiler and build settings, redesigns the demo app, and adds three new methods and eight new delegate methods.  </br> 
    <ul>
   <li>Removed <tt>NSNotifications</tt> and replaced with delegate methods. This makes integration with current projects easier and faster; it is also more reliable. See the <em>Delegates</em> section of this document for more.</li>
    <li>Improved Game Center Availability Checking and Error Reporting. Now check for the availablity of Game Center with the <tt>checkGameCenterAvailability</tt> method. </li>
   <li>Makes improvements to thread switching - now UI tasks are performed on the main thread. Previously they were performed on a background thread for Game Center. </li>
    <li>In depth error reporting for Game Center errors and availability issues.</li>
    <li>The demo app has undergone massive improvements, including many interface improvements. To eliminate redundancy, the iPad part of the Demo App has been removed - Game Center Manager still works with iPad though. </li>
    <li>Code cleanup and reorganization to make it easier on the eyes.</li>
    <li>Upgrades ARMV6 assembler codegen from THUMB to ARM</li>
    <ul>
    </td>
  </tr>
</table>


<table>
  <tr><th colspan="2" style="text-align:center;">Version 3.1</th></tr>
  <tr>
    <td>Improved error reporting and reorganized files to remove duplicates. Added a way to retrieve challenges. Converted old demo app files to support iOS 5+ - now using storyboards intead of XIB.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><b>Version 3.0</b></th></tr>
  <tr>
    <td>Added ARC compatibility. All files are now ready to be used with ARC. Many methods have been updated that were depreciated in iOS 6.0. The demo app has undergone massive improvements, including many interface improvements, iPhone 5 support, a new icon, and better GC status reporting. </td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Version 2.3</th></tr>
  <tr>
    <td>Fixed leaderboard synchronization bug where it would crash if user didn't submit a score previously.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Version 2.2</th></tr>
  <tr>
    <td>Fixed leaderboard synchronization bug where it would only sync the default leaderboard.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Version 2.1</th></tr>
  <tr>
    <td>Fixed NSNotification Bug</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><b>Version 2.0</b></th></tr>
  <tr>
    <td>Added encryption, fixed synchronization bug and added comments and readme</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><b>Version 1.0</b></th></tr>
  <tr>
    <td>Initial Commit</td>
  </tr>
</table>

Attribution
-----

Reachability Class from https://github.com/tonymillion/Reachability
