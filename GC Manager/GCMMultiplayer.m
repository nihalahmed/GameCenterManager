//
//  GCMMultiplayer.m
//  GameCenterManager
//
//  Created by Sam Spencer on 11/23/15.
//  Copyright © 2015 NABZ Software. All rights reserved.
//

#import "GCMMultiplayer.h"
#import "GameCenterManager.h"

@interface GCMMultiplayer ()
@property (nonatomic, strong, readwrite) GKMatch *multiplayerMatch;
@property (nonatomic, assign, readwrite) BOOL multiplayerMatchStarted;
@property (nonatomic, strong, readwrite) UIViewController *matchPresentingController;
@end

@implementation GCMMultiplayer

#pragma mark - Object Lifecycle

+ (GCMMultiplayer *)defaultMultiplayerManager {
    static GCMMultiplayer *singleton;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    
    return singleton;
}

- (void)beginListeningForMatches {
    // Register for GKInvites
    [[GKLocalPlayer localPlayer] registerListener:self];
}

- (void)dealloc {
    [[GKLocalPlayer localPlayer] unregisterAllListeners];
}

#pragma mark - Match Handling

- (void)findMatchWithMinimumPlayers:(int)minPlayers maximumPlayers:(int)maxPlayers onViewController:(UIViewController *)viewController {
    if (![[GameCenterManager sharedManager] isGameCenterAvailable]) {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[[GameCenterManager sharedManager] delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[[GameCenterManager sharedManager] delegate] gameCenterManager:[GameCenterManager sharedManager] error:error];
        
        return;
    }
    
    self.multiplayerMatchStarted = NO;
    self.multiplayerMatch = nil;
    self.matchPresentingController = viewController;
    
    // [matchPresentingController dismissViewControllerAnimated:YES completion:nil];
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKMatchmakerViewController *matchViewController = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    matchViewController.matchmakerDelegate = self;
    
    [self.matchPresentingController presentViewController:matchViewController animated:YES completion:nil];
}

- (void)findMatchWithGKMatchRequest:(GKMatchRequest *)matchRequest onViewController:(UIViewController *)viewController {
    if (![[GameCenterManager sharedManager] isGameCenterAvailable]) {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"GameCenter Unavailable"] code:GCMErrorNotAvailable userInfo:nil];
        if ([[[GameCenterManager sharedManager] delegate] respondsToSelector:@selector(gameCenterManager:error:)])
            [[[GameCenterManager sharedManager] delegate] gameCenterManager:[GameCenterManager sharedManager] error:error];
        
        return;
    }
    
    self.multiplayerMatchStarted = NO;
    self.multiplayerMatch = nil;
    self.matchPresentingController = viewController;
    
    GKMatchmakerViewController *matchViewController = [[GKMatchmakerViewController alloc] initWithMatchRequest:matchRequest];
    matchViewController.matchmakerDelegate = self;
    
    [self.matchPresentingController presentViewController:matchViewController animated:YES completion:nil];
}

- (BOOL)sendAllPlayersMatchData:(NSData *)data shouldSendQuickly:(BOOL)sendQuickly completion:(void (^)(BOOL success, NSError *error))handler {
    // Create the error object
    NSError *error;
    
    // Check if data should be sent reliably or unreliably
    // Reliable: ensures that the data is sent and arrives, can take a long time. Best used for critical game updates.
    // Unreliable: data is sent quickly, data can be lost or fragmented. Best used for frequent game updates.
    
    if (sendQuickly == YES) {
        // The data should be sent unreliably
        if (data.length > 1000) {
            // Limit the size of unreliable messages to 1000 bytes or smaller - as per Apple documentation guidelines
            if (handler != nil) handler(NO, [NSError errorWithDomain:@"The specified data exceeded the unreliable sending limit of 1000 bytes. Either send the data reliably (max. 87 kB) or decrease data packet size." code:GCMErrorMultiplayerDataPacketTooLarge userInfo:@{@"data": data, @"method": @"unreliable"}]);
            return NO;
        }
        
        // Send the data unreliably to all players
        BOOL success = [self.multiplayerMatch sendDataToAllPlayers:data withDataMode:GKMatchSendDataUnreliable error:&error];
        if (!success) {
            // There was an error while sending the data
            if (handler != nil) handler(NO, error);
            return NO;
        } else {
            // There was no error while sending the data
            // No gauruntee is made as to whether or not it is recieved.
            if (handler != nil) handler(YES, nil);
            return YES;
        }
    } else {
        // Limit the size of reliable messages to 87 kilobytes (89,088 bytes) or smaller - as per Apple documentation guidelines
        if (data.length > 89088) {
            if (handler != nil) handler(NO, [NSError errorWithDomain:@"The specified data exceeded the reliable sending limit of 87 kilobytes. You must decrease the data packet size." code:GCMErrorMultiplayerDataPacketTooLarge userInfo:@{@"data": data, @"method": @"reliable"}]);
            return NO;
        }
        
        // Send the data reliably to all players
        BOOL success = [self.multiplayerMatch sendDataToAllPlayers:data withDataMode:GKMatchSendDataReliable error:&error];
        if (!success) {
            // There was an error while sending the data
            if (handler != nil) handler(NO, error);
            return NO;
        } else {
            // There was no error while sending the data
            // No gauruntee is made as to when it will be recieved.
            if (handler != nil) handler(YES, nil);
            return YES;
        }
    }
}

- (BOOL)sendMatchData:(NSData *)data toPlayers:(NSArray *)players shouldSendQuickly:(BOOL)sendQuickly completion:(void (^)(BOOL success, NSError *error))handler {
    // Create the error object
    NSError *error;
    
    // Check if data should be sent reliably or unreliably
    // Reliable: ensures that the data is sent and arrives, can take a long time. Best used for critical game updates.
    // Unreliable: data is sent quickly, data can be lost or fragmented. Best used for frequent game updates.
    
    if (sendQuickly == YES) {
        // The data should be sent unreliably
        if (data.length > 1000) {
            // Limit the size of unreliable messages to 1000 bytes or smaller - as per Apple documentation guidelines
            if (handler != nil) handler(NO, [NSError errorWithDomain:@"The specified data exceeded the unreliable sending limit of 1000 bytes. Either send the data reliably (max. 87 kB) or decrease data packet size." code:GCMErrorMultiplayerDataPacketTooLarge userInfo:@{@"data": data, @"method": @"unreliable", @"players": players}]);
            return NO;
        }
        
        // Send the data unreliably to the specified players
        BOOL success = [self.multiplayerMatch sendData:data toPlayers:players withDataMode:GKMatchSendDataUnreliable error:&error];
        if (!success) {
            // There was an error while sending the data
            if (handler != nil) handler(NO, error);
            return NO;
        } else {
            // There was no error while sending the data
            // No gauruntee is made as to whether or not it is recieved.
            if (handler != nil) handler(YES, nil);
            return YES;
        }
    } else {
        // Limit the size of reliable messages to 87 kilobytes (89,088 bytes) or smaller - as per Apple documentation guidelines
        if (data.length > 89088) {
            if (handler != nil) handler(NO, [NSError errorWithDomain:@"The specified data exceeded the reliable sending limit of 87 kilobytes. You must decrease the data packet size." code:GCMErrorMultiplayerDataPacketTooLarge userInfo:@{@"data": data, @"method": @"reliable", @"players": players}]);
            return NO;
        }
        
        // Send the data reliably to the specified players
        BOOL success = [self.multiplayerMatch sendData:data toPlayers:players withDataMode:GKMatchSendDataReliable error:&error];
        if (!success) {
            // There was an error while sending the data
            if (handler != nil) handler(NO, error);
            return NO;
        } else {
            // There was no error while sending the data
            // No gauruntee is made as to when it will be recieved.
            if (handler != nil) handler(YES, nil);
            return YES;
        }
    }
}

- (void)disconnectLocalPlayerFromMatch {
    NSLog(@"[GameCenterManager] Attempting to disconnect local player");
    
    if (!self.multiplayerMatch) return;
    
    [self.multiplayerMatch disconnect];
    
    NSLog(@"[GameCenterManager] Disconnected local player");
    
    self.multiplayerMatchStarted = NO;
    self.multiplayerMatch.delegate = nil;
    self.multiplayerMatch = nil;
    
    [self.multiplayerDelegate gameCenterManager:self matchEnded:self.multiplayerMatch];
}

#pragma mark - GKLocalPlayerListener

- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite {
    if ([self.multiplayerDelegate respondsToSelector:@selector(gameCenterManager:match:didAcceptMatchInvitation:player:)])
        [self.multiplayerDelegate gameCenterManager:self match:self.multiplayerMatch didAcceptMatchInvitation:invite player:player];
}

- (void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite {
    if ([self.multiplayerDelegate respondsToSelector:@selector(gameCenterManager:match:didRecieveMatchInvitationForPlayer:playersToInvite:)])
        [self.multiplayerDelegate gameCenterManager:self match:self.multiplayerMatch didRecieveMatchInvitationForPlayer:player playersToInvite:playerIDsToInvite];
}

#pragma mark - GKMatchmakerViewControllerDelegate

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    // Matchmaking was cancelled by the user
    [self.matchPresentingController dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    // Matchmaking failed due to an error
    [self.matchPresentingController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Error finding match: %@", error);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    // A peer-to-peer match has been found, the game should start
    [self.matchPresentingController dismissViewControllerAnimated:YES completion:nil];
    self.multiplayerMatch = theMatch;
    self.multiplayerMatch.delegate = self;
    
    if (!self.multiplayerMatchStarted && self.multiplayerMatch.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
        NSLog(@"The didFindMatch: connection is being called. You need to determine if this should be handled.");
        
        // Match was found and all players are connected
        
        self.multiplayerMatchStarted = YES;
        [self.multiplayerDelegate gameCenterManager:self matchStarted:theMatch];
    }
}

#pragma mark - GKMatchDelegate

- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    // The match received data sent from the player
    
    if (self.multiplayerMatch != theMatch) return;
    
    [self.multiplayerDelegate gameCenterManager:self match:theMatch didReceiveData:data fromPlayer:playerID];
}

- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    // The player state changed (eg. connected or disconnected)
    
    if (self.multiplayerMatch != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected:
            // Handle a new player connection
            NSLog(@"Player connected!");
            
            if (!self.multiplayerMatchStarted && theMatch.expectedPlayerCount == 0) {
                NSLog(@"Ready to start match!");
                
                // TODO: Match was found and all players are connected
                NSLog(@"The didChangeState: connection is being called. You need to determine if this should be handled. For now it will not be handled.");
                
                if ([self.multiplayerDelegate respondsToSelector:@selector(gameCenterManager:match:didConnectAllPlayers:)]) {
                    [GKPlayer loadPlayersForIdentifiers:theMatch.playerIDs withCompletionHandler:^(NSArray *players, NSError *error) {
                        [self.multiplayerDelegate gameCenterManager:self match:theMatch didConnectAllPlayers:players];
                    }];
                }
            }
            
            break;
        case GKPlayerStateDisconnected:
            // A player just disconnected
            NSLog(@"Player disconnected");
            
            if ([self.multiplayerDelegate respondsToSelector:@selector(gameCenterManager:match:playerDidDisconnect:)]) {
                [GKPlayer loadPlayersForIdentifiers:@[playerID] withCompletionHandler:^(NSArray *players, NSError *error) {
                    [self.multiplayerDelegate gameCenterManager:self match:theMatch playerDidDisconnect:[players firstObject]];
                }];
            }
            
            self.multiplayerMatchStarted = NO;
            [self.multiplayerDelegate gameCenterManager:self matchEnded:theMatch];
            
            break;
            
        case GKPlayerStateUnknown:
            // Player state is unknown
            NSLog(@"Player state unknown");
            break;
    }
    
}

- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    // The match was unable to connect with the player due to an error
    
    if (self.multiplayerMatch != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error);
    
    self.multiplayerMatchStarted = NO;
    [self.multiplayerDelegate gameCenterManager:self matchEnded:theMatch];
}

- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    // The match was unable to be established with any players due to an error
    
    if (self.multiplayerMatch != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error);
    
    self.multiplayerMatchStarted = NO;
    [self.multiplayerDelegate gameCenterManager:self matchEnded:theMatch];
}

@end
