//
//  NSUserDefaults+MPSecureUserDefaults.h
//  Secure-NSUserDefaults
//
//  Copyright (c) 2011 Matthias Plappert <matthiasplappert@me.com>
//  Modified by Daniel Rosser for Super Hexagon on 24/8/2022 <https://danoli3.com>

//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@interface NSUserDefaults (MPSecureUserDefaults)

/**
 * Sets the secret. Make sure that your secret is stored in a save place, it is recommanded to write it
 * directly into your code. Required property.
 */
+ (void)setSecret:(NSString *)secret;

/**
 * Sets the device identifier. You can use this to link user defaults to a specific machine.
 * This is particularly useful if users are likely to share plist files, e.g. if you use user defaults
 * to store product license information. Optional property.
 */
+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier;

/**
 * Read data from user defaults. If key doesn't exist, valid is YES and the function mimics
 * the return behavior of the respective non-secure method. Please note that the methods below
 * will always return the result, even if it is *NOT* secure. This is a change from previous versions
 * of Secure-NSUserDefaults. It is therefore necessary to check to figure out an appropriate consequence
 * for invalid defaults.
 */
- (NSArray *)secureArrayForKey:(NSString *)key valid:(BOOL *)valid;
- (BOOL)secureBoolForKey:(NSString *)key valid:(BOOL *)valid;
- (NSData *)secureDataForKey:(NSString *)key valid:(BOOL *)valid;
- (NSDictionary *)secureDictionaryForKey:(NSString *)key valid:(BOOL *)valid;
- (float)secureFloatForKey:(NSString *)key valid:(BOOL *)valid;
- (NSInteger)secureIntegerForKey:(NSString *)key valid:(BOOL *)valid;
- (id)secureObjectForKey:(NSString *)key valid:(BOOL *)valid;
- (NSArray *)secureStringArrayForKey:(NSString *)key valid:(BOOL *)valid;
- (NSString *)secureStringForKey:(NSString *)key valid:(BOOL *)valid;
- (double)secureDoubleForKey:(NSString *)key valid:(BOOL *)valid;

/**
 * Write data to user defaults. Only property list objects (NSData, NSString, NSNumber, NSDate, NSArray, NSDictionary)
 * are supported. Passing nil as either the value or key mimics the behavior of the non-secure method.
 */
- (void)setSecureBool:(BOOL)value forKey:(NSString *)key;
- (void)setSecureFloat:(float)value forKey:(NSString *)key;
- (void)setSecureInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setSecureObject:(id)value forKey:(NSString *)key;
- (void)setSecureDouble:(double)value forKey:(NSString *)key;

@end
