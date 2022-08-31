//
//  GKLeaderboardScore+NSCoder.h
//  Super Hexagon
//
//  Created by Daniel Rosser for Super Hexagon on 24/8/2022 <https://danoli3.com>
//  Allows for NSData conversion of GKLeaderboardScore (Basically Serialisation / Copy Ctor)

#import <GameKit/GameKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GKLeaderboardScore (NSCoder)

@property(class, readonly) BOOL supportsSecureCoding;

//@property (strong, nonatomic) GKPlayer *player;
//@property (assign, nonatomic) NSInteger value;
//@property (assign, nonatomic) NSUInteger context;
//@property (strong, nonatomic) NSString *leaderboardID;

- (void) encodeWithCoder: (NSCoder *)coder;

- (id) initWithCoder: (NSCoder *)coder;

@end

NS_ASSUME_NONNULL_END
