//
//  DMViewController.m
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import "DMViewController.h"
#import "DMOAuthTwitter.h"
#import "DMTwitterCore.h"

@interface DMViewController () {
    IBOutlet    UIButton*       btn_loginLogout;
    IBOutlet    UILabel*        lbl_welcome;
    IBOutlet    UITextView*     tw_userData;
}

- (IBAction)btn_twitterLogin:(id)sender;
+ (NSString *) readableCurrentLoginStatus:(DMOTwitterLoginStatus) cstatus;

@end

@implementation DMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Twitter OAuth";
    if ([DMTwitter shared].oauth_token_authorized) {
        [btn_loginLogout setTitle:@"Already Logged, Press to Logout" forState:UIControlStateNormal];
        [lbl_welcome setText:[NSString stringWithFormat:@"You're %@!",[DMTwitter shared].screen_name]];
        tw_userData.text = @"";
    }
}

- (IBAction)btn_twitterLogin:(id)sender {
    if ([DMTwitter shared].oauth_token_authorized) {
        // already logged, execute logout
        [[DMTwitter shared] logout];
        [btn_loginLogout setTitle:@"Twitter Login" forState:UIControlStateNormal];
        [lbl_welcome setText:@"Press \"Twitter Login!\" to start!"];
        tw_userData.text = @"";
    } else {
        // prompt login
        [[DMTwitter shared] newLoginSessionFrom:self.navigationController
                                   progress:^(DMOTwitterLoginStatus currentStatus) {
                                       NSLog(@"current status = %@",[DMViewController readableCurrentLoginStatus:currentStatus]);
                                   } completition:^(NSString *screenName, NSString *user_id, NSError *error) {
                                       
                                       if (error != nil) {
                                           NSLog(@"Twitter login failed: %@",error);
                                       } else {
                                           NSLog(@"Welcome %@!",screenName);
                                           
                                           
                                           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: TRUE];
                                           [self.activityIndi setHidden:NO];
                                           // Request access to the Twitter accounts
                                           
                                           ACAccountStore *accountStore = [[ACAccountStore alloc] init];
                                           ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
                                           
                                           [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
                                               if (granted) {
                                                   
                                                   NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                                   
                                                   // Check if the users has setup at least one Twitter account
                                                   
                                                   if (accounts.count > 0)
                                                   {
                                                       ACAccount *twitterAccount = [accounts objectAtIndex:0];
                                                       
                                                       // Creating a request to get the info about a user on Twitter
                                                       
                                                       SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json"] parameters:[NSDictionary dictionaryWithObject:screenName forKey:@"screen_name"]];
                                                       [twitterInfoRequest setAccount:twitterAccount];
                                                       
                                                       // Making the request
                                                       
                                                       [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               
                                                               // Check if we reached the reate limit
                                                               
                                                               if ([urlResponse statusCode] == 429) {
                                                                   NSLog(@"Rate limit reached");
                                                                   return;
                                                               }
                                                               
                                                               // Check if there was an error
                                                               
                                                               if (error) {
                                                                   NSLog(@"Error: %@", error.localizedDescription);
                                                                   return;
                                                               }
                                                               
                                                               // Check if there is some response data
                                                               
                                                               if (responseData) {
                                                                   
                                                                   NSError *error = nil;
                                                                   NSArray *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                                                                   
                                                                   
                                                                   // Filter the preferred data
                                                                   
                                                                   NSString *screen_name = [(NSDictionary *)TWData objectForKey:@"screen_name"];
                                                                   NSString *name = [(NSDictionary *)TWData objectForKey:@"name"];
                                                                   
                                                                   int followers = [[(NSDictionary *)TWData objectForKey:@"followers_count"] integerValue];
                                                                   int following = [[(NSDictionary *)TWData objectForKey:@"friends_count"] integerValue];
                                                                   int tweets = [[(NSDictionary *)TWData objectForKey:@"statuses_count"] integerValue];
                                                                   
                                                                   NSString *profileImageStringURL = [(NSDictionary *)TWData objectForKey:@"profile_image_url_https"];
                                                                   NSString *bannerImageStringURL =[(NSDictionary *)TWData objectForKey:@"profile_banner_url"];
                                                                   
                                                                   
                                                                   // Update the interface with the loaded data
                                                                   NSLog(@"name%@",name);
                                                                    NSLog(@"screen_name%@",screen_name);
                                                                    NSLog(@"tweets%d",tweets);
                                                                   NSLog(@"following%d",following);
                                                                   NSLog(@"followers%d",followers);
                                                                   nameLabel.text = name;
                                                                 usernameLabel.text= [NSString stringWithFormat:@"@%@",screen_name];
                                                                   
                                                                   tweetsLabel.text = [NSString stringWithFormat:@"%i", tweets];
                                                                   followingLabel.text= [NSString stringWithFormat:@"%i", following];
                                                                   followersLabel.text = [NSString stringWithFormat:@"%i", followers];
                                                                   
                                                                   
                                                                   NSString *lastTweet = [[(NSDictionary *)TWData objectForKey:@"status"] objectForKey:@"text"];
                                                                   lastTweetTextView.text= lastTweet;
                                                                   
                                                                   
                                                                   
                                                                   // Get the profile image in the original resolution
                                                                   
                                                                   profileImageStringURL = [profileImageStringURL stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
                                                                   [self getProfileImageForURLString:profileImageStringURL];
                                                                   
                                                                   
                                                                   // Get the banner image, if the user has one
                                                                   
                                                                   if (bannerImageStringURL) {
                                                                       NSString *bannerURLString = [NSString stringWithFormat:@"%@/mobile_retina", bannerImageStringURL];
                                                                       [self getBannerImageForURLString:bannerURLString];
                                                                   } else {
                                                                       //bannerImageView.backgroundColor = [UIColor underPageBackgroundColor];
                                                                   }
                                                               }
                                                           });
                                                       }];
                                                   }
                                               } else {
                                                   NSLog(@"No access granted");
                                               }
                                           }];

                                           
                                           [btn_loginLogout setTitle:@"Twitter Logout" forState:UIControlStateNormal];
                                           [lbl_welcome setText:[NSString stringWithFormat:@"Welcome %@!",screenName]];
                                           [tw_userData setText:@"Loading your user info..."];
                                           
                                           // store our auth data so we can use later in other sessions
                                           [[DMTwitter shared] saveCredentials];
                                       
                                           NSLog(@"Now getting more data...");
                                           // you can use this call in order to validate your credentials
                                           // or get more user's info data
                                           [[DMTwitter shared] validateTwitterCredentialsWithCompletition:^(BOOL credentialsAreValid, NSDictionary *userData) {
                                               if (credentialsAreValid)
                                                   tw_userData.text = [NSString stringWithFormat:@"Data for %@ (userid=%@):\n%@",screenName,user_id,userData];
                                               else
                                                   tw_userData.text = @"Cannot get more data. Token is not authorized to get this info.";
                                           }];
                                       }
                                   }]; 
    }
}
- (void) getProfileImageForURLString:(NSString *)urlString;
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
   profileImageView.image = [UIImage imageWithData:data];
    
    
    [self.activityIndi setHidden:YES];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: FALSE];
}

- (void) getBannerImageForURLString:(NSString *)urlString;
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    bannerImageView.image = [UIImage imageWithData:data];
}

+ (NSString *) readableCurrentLoginStatus:(DMOTwitterLoginStatus) cstatus {
    switch (cstatus) {
        case DMOTwitterLoginStatus_PromptUserData:
            return @"Prompt for user data and request token to server";
        case DMOTwitterLoginStatus_RequestingToken:
            return @"Requesting token for current user's auth data...";
        case DMOTwitterLoginStatus_TokenReceived:
            return @"Token received from server";
        case DMOTwitterLoginStatus_VerifyingToken:
            return @"Verifying token...";
        case DMOTwitterLoginStatus_TokenVerified:
            return @"Token verified";
        default:
            return @"[unknown]";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
