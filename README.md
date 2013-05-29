Game Center Manager
=========================

Game Center Manager helps you manage Game Center. It makes it easy to report and keep track of high scores achievements, and challenges for different players. Game Center Manager also takes care of the heavy lifting - checking internet availability, saving data when offline and uploading it when online, etc.

<img width=750 src="https://github.com/iRareMedia/GameCenterManager/blob/master/Interface.png?raw=true"/>

Features
--------

- Scores and achievements saved if no internet connection is available or an error occurred while reporting to Game Center. Scores and achievements are uploaded again when Game Center is available.
- Synchronization of Game Center data on first run
- Encryption of Game Center data
- Simple methods for uploading and retrieveing data
- Delegate methods
- Easy to use and setup

Setup
------------

1. Add the `GameKit` and `SystemConfiguration` frameworks to your Xcode project  
2. Add the following classes (can be found in the *GC Manager* folder) to your Xcode project (make sure to select Copy Items in the dialog):  
   -  GameCenterManager  
   -  Reachability 
   -  NSDataAES256  
3. Open the `GameCenterManager.h` file and change the `kGameCenterManagerKey` constant to the secret key you want to use for encryption/decryption  
4. Import the `GameCenterManager.h` file  
5. Add the delegate `GameCenterManagerDelegate` to your header file, then set the delegate in your implementation and add any delegates you'd like to use (see **Delegates**):

        [[GameCenterManager sharedManager] setDelegate:self];

Using the Demo App
------------

Game Center Manager's demo app makes it easier to test Game Center integration and how it works with Game Center Manager. It also lays out how to use the `GameCenterManager` class. To get the most out of the Game Center Manager demo app you'll need to connect it to your an app which you have setup in iTunes Connect. You can read about setting up and developing with Game Center from <a href="https://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/GameKit_Guide/GameCenterOverview/GameCenterOverview.html#//apple_ref/doc/uid/TP40008304-CH5-SW7">Apple's Developer Documentation</a> and you can also follow these steps to connect the GC Manager demo with your current app.

  1. First, check and make sure your app is setup in **iTunes Connect** and that Game Center is enabled  
  2. In the GC Manager Demo app, change the **Bundle ID** to the same ID of the app which is setup in iTunes Connect  
  3. Go to the GC Manager Project Build Settings and change the **Code Signing Identity** to match the provisioning profile of your app  
  4. Customize the achievement and scoreboard submission IDs in the ViewController.m to actual values from your app  
  5. Run the GC Manager Demo in the Game Center Sandbox - if everything is properly setup and you're signed into the GC Sandbox then it should run properly and submit achievements and leaderboards.

If you find any issues with this process, please file an <a href="https://github.com/iRareMedia/GameCenterManager/issues/new">issue</a> so we can fix it or update the instructions.

Methods
-----

###Initialize GameCenterManager
You should initialize GameCenterManager when your app is launched, preferably in the `application didFinishLaunchingWithOptions` method by calling

    [[GameCenterManager sharedManager] initGameCenter];  

This checks if Game Center is supported in the current device, authenticates the player and synchronizes scores and achievements from Game Center if its being run for the first time.

###Check Game Center Support
Check for Game Center availability:

    [[GameCenterManager sharedManager] checkGameCenterAvailability];  


###Report Score
Report a score to Game Center:

    [[GameCenterManager sharedManager] saveAndReportScore:1000 leaderboard:@"Leaderboard Name"];  

This method saves the score locally as well. If GameCenter is not available, the scores will be saved locally and uploaded to Game Center the next time your app or game can connect to Game Center.

###Report Achievement
Report an achievement to Game Center:

    [[GameCenterManager sharedManager] saveAndReportAchievement:@"1000Points" percentComplete:50];  

This method saves the achievement progress locally as well. If GameCenter is not available, the achievement will be saved locally and uploaded to Game Center the next time your app or game can connect to Game Center.

###Get High Scores
Get the high scores for the current player:

    //Array of leaderboard ID's to get high scores for
    NSArray *leaderboardIDs = [NSArray arrayWithObjects:@"Leaderboard1", @"Leaderboard2", nil];

    //Returns a dictionary with leaderboard ID's as keys and high scores as values
    [[GameCenterManager sharedManager] highScoreForLeaderboards:leaderboardIDs];  

###Get Achievement Progress
To get achievement progress for the current player, you can call

    //Array of achievement ID's to get progress for
    NSArray *achievementIDs = [NSArray arrayWithObjects:@"Achievement1", @"Achievement2", nil];

    //Returns a dictionary with achievement ID's as keys and progress as values
    [[GameCenterManager sharedManager] progressForAchievements:achievementIDs];  

###Get Challenges
To get challenges for the current game and player, you can call

    //Returns an array with challenges. If there is an error retrieving the challenges, an array containing the error is returned. Returns `nil` if it was unable to connect to GameCenter.
    NSArray *challenges = [[GameCenterManager sharedManager] getChallenges]; 

Delegates
-----

<table>
  <tr><th colspan="2" style="text-align:center;">Required Delegate Methods</th></tr>
  <tr>
    <td>Authenticate User</td>
    <td> If the user is not logged into GameCenter, you'll need to present the GameCenter login view controller. This method is required because the user must be logged in for Game Center to work. If the user does not login, an error will be returned.  
     
            - (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController</td>
  </tr>
    <tr><th colspan="2" style="text-align:center;">Optional Delegate Methods</th></tr>
  <tr>
    <td>Availability Changed</td>
    <td>When the availability status of Game Center changes, this delegate method is called. The availability of GameCenter depends on multiple factors including:
    - Internet Connection
    - iOS Version (4.1+ required)
    - Player Authentication
    - Game Authentication
  
    The NSDictionary object, `availabilityInformation`, contains two objects, a `message` and a `title`. The `message` object is an NSString describing the availability issue. The `title` is a shorter description of the error; it is also an NSString.
       
            - (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation</td>
  </tr>
  <tr>
    <td>Game Center Error</td>
    <td>When there is an error performing a Game Center task this delegate method is executed.
  
    The `error` NSDictionary contains one NSError object, `error`.
       
            - (void)gameCenterManager:(GameCenterManager *)manager error:(NSDictionary *)error</td>
  </tr>
  <tr>
    <td>Reported Score</td>
    <td>Called after the submitted score is successfully saved, uploaded, and posted to Game Center. 
  
    The NSDictionary, `scoreInformation`, contains one NSError object, `error`, which may be `nil` if there is no error. It also contains a GKScore object, `score`, which contains information about the submitted score.
       
            - (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(NSDictionary *)scoreInformation</td>
  </tr>
  <tr>
    <td>Saved Score</td>
    <td>Called after the submitted score is successfully saved, but not posted or uploaded to Game Center. The saved score will be uploaded the next time GC Manager can successfully connect to Game Center. 
  
    The GKScore object, `score` contains information about the submitted score.
       
           - (void)gameCenterManager:(GameCenterManager *)manager savedScore:(GKScore *)score</td>
  </tr>
    <tr>
    <td>Reported Achievement</td>
    <td>Called after the submitted achievement and its percent complete is successfully saved, uploaded, and posted to Game Center. 
  
    The NSDictionary, `achievementInformation`, contains one NSError object, `error`, which may be `nil` if there is no error. It also contains a GKAchievement object, `achievement`, which contains information about the submitted achievement.
       
            - (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(NSDictionary *)achievementInformation</td>
  </tr>
  <tr>
    <td>Saved Achievement</td>
    <td>Called after the submitted achievement is successfully saved, but not posted or uploaded to Game Center. The saved achievement and its percent completed will be uploaded the next time GC Manager can successfully connect to Game Center. 
  
    The NSDictionary object, `achievementInformation` contains a double, `percent complete`, which is the percent completed on the specified and saved achievement. It also contains a GKAchievement object, `achievement`, which contains information about the submitted achievement.
       
          - (void)gameCenterManager:(GameCenterManager *)manager savedAchievement:(NSDictionary *)achievementInformation</td>
  </tr>
    <tr>
    <td>Reset All Achievements</td>
    <td>When the `resetAchievements` method is called and resets all achievements successfully, this delegate method is fired. This method may be useful for updating user interface elements (ex. updating a table view listing completed achievements). Be warned though, the `resetAchievements` method does not prompt the user before resetting - you must do this on your own. 
       
         - (void)gameCenterManager:(GameCenterManager *)manager resetAchievements:(NSError *)error</td>
  </tr>
</table>

Attribution
-----

Reachability Class from https://github.com/tonymillion/Reachability


Changelog
-----

<table>
  <tr><th colspan="2" style="text-align:center;">**Version 4.0**</th></tr>
  <tr>
    <td>This update makes massive improvements to the flow and performance of code, updates Objective-C compiler and build settings, redesigns the demo app, and adds three new methods and eight new delegate methods.   
    -  Removed `NSNotifications` and replaced with delegate methods. This makes integration with current projects easier and faster; it is also more reliable. See the *Delegates* section of this document for more.   
    - Improved Game Center Availability Checking and Error Reporting. Now check for the availablity of Game Center with the `checkGameCenterAvailability` method.   
    - Makes improvements to thread switching - now UI tasks are performed on the main thread. Previously they were performed on a background thread for GameCenter.   
    - In depth error reporting for Game Center errors and availability issues.   
    - The demo app has undergone massive improvements, including many interface improvements. To eliminate redundancy, the iPad part of the Demo App has been removed - Game Center Manager still works with iPad though.  
    - Code cleanup and reorganization to make it easier on the eyes.   
    - Upgrades ARMV6 assembler codegen from THUMB to ARM</td>
  </tr>
</table>


<table>
  <tr><th colspan="2" style="text-align:center;">Version 3.1</th></tr>
  <tr>
    <td>Improved error reporting and reorganized files to remove duplicates. Added a way to retrieve challenges. Converted old demo app files to support iOS 5+ - now using storyboards intead of XIB.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">**Version 3.0**</th></tr>
  <tr>
    <td>Added ARC compatibility. All files are now ready to be used with ARC. Many methods have been updated that were depreciated in iOS 6.0. The demo app has undergone massive improvements, including many interface improvements, iPhone 5 support, a new icon, and better GC status reporting. </td>
  </tr>
</table>


<table>
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
  <tr><th colspan="2" style="text-align:center;">**Version 2.0**</th></tr>
  <tr>
    <td>Added encryption, fixed synchronization bug and added comments and readme</td>
  </tr>
</table>


<table>
  <tr><th colspan="2" style="text-align:center;">**Version 1.0**</th></tr>
  <tr>
    <td>Initial Commit</td>
  </tr>
</table>