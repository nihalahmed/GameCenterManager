//
//  GCMConstants.h
//  GameCenterManager
//
//  Created by Sam Spencer on 11/23/15.
//  Copyright © 2015 NABZ Software. All rights reserved.
//

#ifndef GCMConstants_h
#define GCMConstants_h

/// Leaderboard sort order. Use this value when submitting new leaderboard scores. This value should match the value set in iTunes Connect for the speicifed leaderboard.
typedef enum GameCenterSortOrder {
    /// Scores are sorted highest to lowest. Higher scores are on the top of the leaderboard
    GameCenterSortOrderHighToLow,
    /// Scores are sorted lowest to highest. Lower scores are on the top of the leaderboard
    GameCenterSortOrderLowToHigh
} GameCenterSortOrder;

enum {
    /// An unknown error occurred
    GCMErrorUnknown = 1,
    /// GameCenterManager is unavailable, possibly for a variety of reasons
    GCMErrorNotAvailable = 2,
    /// The requested feature is unavailable on the current device or iOS version
    GCMErrorFeatureNotAvailable = 3,
    /// There is no active internet connection for the requested operation
    GCMErrorInternetNotAvailable = 4,
    /// The achievement data submitted was not valid because there were missing parameters
    GCMErrorAchievementDataMissing = 5,
    /// The multiplayer data could not be sent with the specified connection type because it was too large
    GCMErrorMultiplayerDataPacketTooLarge = 6
};
/// GameCenterManager error codes that may be passed in a completion handler's error parameter
typedef NSInteger GCMErrorCode;

/// GameCenter availability status. Use these statuss to identify the state of GameCenter's availability.
typedef enum GameCenterAvailability {
    /// GameKit Framework not available on this device
    GameCenterAvailabilityNotAvailable,
    /// Cannot connect to the internet
    GameCenterAvailabilityNoInternet,
    /// Player is not yet signed into GameCenter
    GameCenterAvailabilityNoPlayer,
    /// Player is not signed into GameCenter, has declined to sign into GameCenter, or GameKit had an issue validating this game / app
    GameCenterAvailabilityPlayerNotAuthenticated,
    /// Player is signed into GameCenter
    GameCenterAvailabilityPlayerAuthenticated
} GameCenterAvailability;

#endif /* GCMConstants_h */
