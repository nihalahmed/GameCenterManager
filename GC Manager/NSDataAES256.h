//
//  NSDataAES256.h
//

#import <Foundation/Foundation.h>

@interface NSData (AES256)

- (NSData *)encryptedWithKey:(NSData *)key;
- (NSData *)decryptedWithKey:(NSData *)key;

@end
