#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Security/Security.h>

// Spoof app version so Meta servers allow feed & video queries
%hook NSBundle
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([self.bundleIdentifier isEqualToString:@"com.facebook.Facebook"]) {
        if ([key isEqualToString:@"CFBundleShortVersionString"]) {
            return @"380.0.0";
        }
        if ([key isEqualToString:@"CFBundleVersion"]) {
            return @"380000000";
        }
    }
    return %orig;
}
%end

// Rewrite User-Agent and redirect deprecated legacy video endpoints
%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if ([field caseInsensitiveCompare:@"User-Agent"] == NSOrderedSame && value != nil) {
        NSString *spoofedUA = [value stringByReplacingOccurrencesOfString:@"FBAV/4.5.6" withString:@"FBAV/380.0.0.0.0"];
        spoofedUA = [spoofedUA stringByReplacingOccurrencesOfString:@"FBForIPhone/4.5.6" withString:@"FBForIPhone/380.0.0"];
        %orig(spoofedUA, field);
        return;
    }
    %orig;
}

- (void)setURL:(NSURL *)url {
    if (url) {
        NSString *urlString = url.absoluteString;
        // Redirect legacy ://facebook.com calls to ://facebook.com
        if ([urlString containsString:@"://facebook.com"]) {
            urlString = [urlString stringByReplacingOccurrencesOfString:@"://facebook.com" withString:@"://facebook.com"];
            NSURL *updatedURL = [NSURL URLWithString:urlString];
            if (updatedURL) {
                %orig(updatedURL);
                return;
            }
        }
    }
    %orig;
}
%end

// Bypass expired SSL pinning in legacy NSURLConnection
%hook NSURLConnection
+ (BOOL)canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return YES;
    }
    return %orig;
}
%end

// Ensure AVPlayer allows modern HTTPS streams on legacy playback calls
%hook AVURLAsset
+ (instancetype)URLAssetWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    NSMutableDictionary *newOptions = options ? [options mutableCopy] : [NSMutableDictionary dictionary];
    newOptions[AVURLAssetPreferPreciseDurationAndTimingKey] = @YES;
    return %orig(URL, newOptions);
}
%end
