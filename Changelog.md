#Changelog

<table>
<tr><th colspan="2" style="text-align:center;"><b>Version 5.1</b></th></tr>
  <tr>
    <td>This update adds support for iOS 7, makes improvements to the iOS & Mac OS X demo apps, fixes bugs with error reporting, improves player data methods, and makes some breaking changes to resetting achievements.</br> 
    <ul>
   <li>Major improvements to the demo apps including new UI and Icons</li>
    <li>Limited iOS 7 support. The project runs on iOS 7, but the classes are not fully optimized for iOS 7. A new branch will be created soon which has specific iOS 7 changes.</li>
   <li>Fixed a bug where checking for GameCenter availability would return NO, but wouldn't deliver an error message.</li>
    <li>Deprecated <tt>gameCenterManager:resetAchievements:</tt> delegate method in favor of a completion handler now available on the <tt>resetAchievements:</tt> method. The <tt>gameCenterManager:resetAchievements:</tt> delegate method is no longer called</li>
    <li>Fixed a bug where resetting achievements may not work</li>
    <li>Cleaned code, minor improvements to code</li>
    </ul>
    </td>
  </tr>
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
    <td>Fixed issue where GameCenter Manager would fail to handle authentication after calling the <tt>authenticateHandler</tt>. Pull Request by Jonathan Swafford</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;">Version 4.1</th></tr>
  <tr>
    <td>Fixed issue where GameCenter Manager would fail to report achievements and scores even if Game Center was available.</td>
  </tr>
  <tr><th colspan="2" style="text-align:center;"><b>Version 4.0</b></th></tr>
  <tr>
    <td>This update makes massive improvements to the flow and performance of code, updates Objective-C compiler and build settings, redesigns the demo app, and adds three new methods and eight new delegate methods.  </br> 
    <ul>
   <li>Removed <tt>NSNotifications</tt> and replaced with delegate methods. This makes integration with current projects easier and faster; it is also more reliable. See the <em>Delegates</em> section of this document for more.</li>
    <li>Improved Game Center Availability Checking and Error Reporting. Now check for the availablity of Game Center with the <tt>checkGameCenterAvailability</tt> method. </li>
   <li>Makes improvements to thread switching - now UI tasks are performed on the main thread. Previously they were performed on a background thread for Game Center. </li>
    <li>In depth error reporting for Game Center errors and availability issues.</li>
    <li>The demo app has undergone massive improvements, including many interface improvements. To eliminate redundancy, the iPad part of the Demo App has been removed - GameCenter Manager still works with iPad though. </li>
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
