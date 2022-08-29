//
//  GKLeaderboardScore+NSCoder.h
//  Super Hexagon
//
//  Created by Daniel Rosser for Super Hexagon on 24/8/2022 <https://danoli3.com>


#import <GameKit/GameKit.h>
#import "GKLeaderboardScore+NSCoder.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GKLeaderboardScore (NSCoder)

- (void) encodeWithCoder: (NSCoder *)coder
{
  [coder encodeInt64:self.value forKey:@"value"];
  [coder encodeInt64:self.context     forKey:@"context"];
  [coder encodeObject:self.leaderboardID     forKey:@"leaderboardID"];
  [coder encodeObject:self.player     forKey:@"player"];
}

- (id) initWithCoder: (NSCoder *)coder
{
  if (self = [super init])
  {
    self.value = [coder decodeInt64ForKey:@"value"];
    self.context = [coder decodeInt64ForKey:@"context"];
    self.leaderboardID = [coder decodeObjectForKey:@"leaderboardID"];
    self.player = [coder decodeObjectForKey:@"player"];
  }
  return self;
}

+ (BOOL)supportsSecureCoding {
   return YES;
}

@end

NS_ASSUME_NONNULL_END
