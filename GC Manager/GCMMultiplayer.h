//
//  GCMMultiplayer.h
//  GameCenterManager
//
//  Created by Sam Spencer on 11/23/15.
//  Copyright © 2015 NABZ Software. All rights reserved.
//

@import Foundation;
@import GameKit;

#import "GCMConstants.h"

@protocol GameCenterMultiplayerManagerDelegate;

@interface GCMMultiplayer : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLocalPlayerListener>

/// Returns the default instance of the multiplayer manager
+ (GCMMultiplayer *)defaultMultiplayerManager;

/// GameCenterManager multiplayerDelegate property that should be used to set the delegate for multiplayer matches
@property (nonatomic, weak) id <GameCenterMultiplayerManagerDelegate> multiplayerDelegate;

/// Begin listening and responding to Game Center match requests / invites. This should be one of the first calls made to the GCMMultiplayer object.
- (void)beginListeningForMatches;

/// Finds and sets up a multiplayer match using the specified parameters and the default MatchmakerViewController
- (void)findMatchWithMinimumPlayers:(int)minPlayers maximumPlayers:(int)maxPlayers onViewController:(UIViewController *)viewController;

/// Finds and sets up a multiplayer match using a custom GKMatchRequest object - this allows for ultimate match flexibility (eg. player groups, invited players, player attributes, etc.)
- (void)findMatchWithGKMatchRequest:(GKMatchRequest *)matchRequest onViewController:(UIViewController *)viewController;

/** Sends data to \b all players in the current multiplayer match using the specified parameters
 
 @discussion Use this method to send data to all players in a match. If you do not need to send data to all players, instead use the alternate method which lets you specify players.
 
 Send messages at the lowest frequency that allows your game to function well. Your game’s graphics engine may be running at 30 to 60 frames per second, but your networking code can send updates much less frequently.
 
 Use the smallest message format that gets the job done. Messages that are sent frequently or messages that must be received quickly by other participants should be carefully scrutinized to ensure that no unnecessary data is being sent.
 
 Pack your data into the smallest representation you can without losing valuable information. For example, an integer in your program may use 32 or 64 bits to store its data. If the value stored in the integer is always in the range 1 through 10, you can store it in your network message in only 4 bits.
 
 Send messages only to the participants that need the information contained in the message. For example, if your game has two different teams, team-related messages should be sent only to the members of the same team. Sending data to all participants in the match uses up networking bandwidth for little gain.
 
 @param data The data to be sent to all of the players. This should not exceed 1000 bytes for quick sending, and should not exceed 87 kilobytes when sending reliably.
 @param sendQuickly Specify YES if the data should be sent without ensuring delivery (faster). NO if the data's delivery should be guaranteed (slower).
 @param handler Implement the completion handler to recieve information about the status of the data send. The error parameter may be nil if there was no error. */
- (BOOL)sendAllPlayersMatchData:(NSData *)data shouldSendQuickly:(BOOL)sendQuickly completion:(void (^)(BOOL success, NSError *error))handler;

/** Sends data to the specified players in the current multiplayer match using the specified parameters
 
 @discussion Use this method to send data to all players in a match. If you do not need to send data to all players, instead use the alternate method which lets you specify players.
 
 Send messages at the lowest frequency that allows your game to function well. Your game’s graphics engine may be running at 30 to 60 frames per second, but your networking code can send updates much less frequently.
 
 Use the smallest message format that gets the job done. Messages that are sent frequently or messages that must be received quickly by other participants should be carefully scrutinized to ensure that no unnecessary data is being sent.
 
 Pack your data into the smallest representation you can without losing valuable information. For example, an integer in your program may use 32 or 64 bits to store its data. If the value stored in the integer is always in the range 1 through 10, you can store it in your network message in only 4 bits.
 
 Send messages only to the participants that need the information contained in the message. For example, if your game has two different teams, team-related messages should be sent only to the members of the same team. Sending data to all participants in the match uses up networking bandwidth for little gain.
 
 @param data The data to be sent to all of the players. This should not exceed 1000 bytes for quick sending, and should not exceed 87 kilobytes when sending reliably.
 @param players An array of GKPlayer objects to which the data should be sent (can be more efficient if you are not implementing a peer-to-peer connection, or don't need to send to all players).
 @param sendQuickly Specify YES if the data should be sent without ensuring delivery (faster). NO if the data's delivery should be guaranteed (slower).
 @param handler Implement the completion handler to recieve information about the status of the data send. The error parameter may be nil if there was no error. */
- (BOOL)sendMatchData:(NSData *)data toPlayers:(NSArray *)players shouldSendQuickly:(BOOL)sendQuickly completion:(void (^)(BOOL success, NSError *error))handler;

/// Disconnects the current (local) player from the multiplayer match. The matchEnded: delegate method will be called after disconnecting, regardless of the number of players.
- (void)disconnectLocalPlayerFromMatch;

/// @b Readonly. Retrieve the current GKMatch object. May be nil if no match has been setup.
@property (nonatomic, strong, readonly) GKMatch *multiplayerMatch;

/// @b Readonly. Indicates whether or not the multiplayer match has started (if one has been created).
@property (nonatomic, assign, readonly) BOOL multiplayerMatchStarted;

@property (nonatomic, strong, readonly) UIViewController *matchPresentingController;

@end

/// GameCenterManager Multiplayer Delegate. Handles multiplayer connections, match data, and other aspects of live multiplayer matchs.
@protocol GameCenterMultiplayerManagerDelegate <NSObject>


@required

/// Sent to the delegate when a live multiplayer match begins
- (void)gameCenterManager:(GCMMultiplayer *)manager matchStarted:(GKMatch *)match;

/// Sent to the delegate when a live multiplayer match ends
- (void)gameCenterManager:(GCMMultiplayer *)manager matchEnded:(GKMatch *)match;

/// Sent to the delegate when data is recieved on the current device (sent from another player in the match)
- (void)gameCenterManager:(GCMMultiplayer *)manager match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;


@optional

/// Sent to the delegate when all players are connected. Passes an array of players in the match to the delegate.
- (void)gameCenterManager:(GCMMultiplayer *)manager match:(GKMatch *)match didConnectAllPlayers:(NSArray *)gkPlayerArray;

/// Sent to the delegate when a player is disconnected. Passes the disconnected player to the delegate.
- (void)gameCenterManager:(GCMMultiplayer *)manager match:(GKMatch *)match playerDidDisconnect:(GKPlayer *)player __OSX_AVAILABLE_STARTING(__OSX_10_9,__IPHONE_7_0);

/// Sent to the delegate when a player recieves a match invitation. Use this opportunity to begin a match or setup the match request.
- (void)gameCenterManager:(GCMMultiplayer *)manager match:(GKMatch *)match didRecieveMatchInvitationForPlayer:(GKPlayer *)invitedPlayer playersToInvite:(NSArray *)players;

/// Sent to the delegate when a player accepts a match invitation. Use this opportunity to handle your match.
- (void)gameCenterManager:(GCMMultiplayer *)manager match:(GKMatch *)match didAcceptMatchInvitation:(GKInvite *)invite player:(GKPlayer *)player;

@end
