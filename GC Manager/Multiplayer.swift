//
//  Multiplayer.swift
//  GameCenterManager
//
//  Created by Sam Spencer on 12/13/15.
//  Copyright © 2015 NABZ Software. All rights reserved.
//

import Foundation
import GameKit

protocol MultiplerManagerDelegate {
    func matchStarted(manager:Multiplayer, match:GKMatch)
    func matchEnded(manager:Multiplayer, match:GKMatch)
    func matchRecievedData(manager:Multiplayer, match:GKMatch, data:NSData, sendingPlayerID:NSString)
}

protocol MultiplayerPlayerManagerDelegate {
    func allPlayersConnectedToMatch(manager:Multiplayer, match:GKMatch, players:[String])
    func allPlayersDisconnectedFromMatch(manager:Multiplayer, match:GKMatch, players:[String])
    func recievedMatchInvitation(manager:Multiplayer, invitedPlayer:GKPlayer, players:[GKPlayer])
    func acceptedMatchInvitation(manager:Multiplayer, invite:GKInvite, player:GKPlayer)
}

class Multiplayer: NSObject, GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLocalPlayerListener {

    var matchPresentingController: UIViewController?
    var multiplayerMatchStarted: Bool
    var multiplayerMatch: GKMatch?
    
    override init() {
        // Initialize the class
        matchPresentingController = nil
        multiplayerMatchStarted = false
        multiplayerMatch = nil
        
        super.init()
    }
    
    deinit {
        GKLocalPlayer.localPlayer().unregisterAllListeners()
    }
    
    class MultiplayerManager  {
        static let sharedInstance = Multiplayer()
    }
    
    func beginListeningForMatches() {
        GKLocalPlayer.localPlayer().registerListener(self)
    }
    
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController) {
        // Matchmaking was cancelled by the user
        matchPresentingController!.dismissViewControllerAnimated(true) { () -> Void in
            NSLog("Matchmaking View Controller was dissmissed.")
        }
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFailWithError error: NSError) {
        // Matchmaking failed due to an error
        matchPresentingController!.dismissViewControllerAnimated(true) { () -> Void in
            NSLog("Error finding match: %@", error)
        }
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController, didFindMatch match: GKMatch) {
        
    }
}
