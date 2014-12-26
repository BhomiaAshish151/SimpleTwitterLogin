//
//  DMViewController.h
//  DMTwitterOAuth
//
//  Created by Daniele Margutti (daniele.margutti@gmail.com) on 5/13/12.
//  From an original work by Jaanus Kase
//  Copyright (c) 2012 http://danielem.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>
@interface DMViewController : UIViewController
{
    IBOutlet UIImageView *profileImageView;
    IBOutlet UIImageView *bannerImageView;
    
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *usernameLabel;
    
    IBOutlet UILabel *tweetsLabel;
    IBOutlet UILabel *followingLabel;
    IBOutlet UILabel *followersLabel;
    
    IBOutlet UITextView *lastTweetTextView;
    NSString *username;
    IBOutlet UIActivityIndicatorView *activityIndi;
}
@property(nonatomic,retain) IBOutlet UIActivityIndicatorView *activityIndi;
@property (nonatomic, retain) NSString *username;
@end
