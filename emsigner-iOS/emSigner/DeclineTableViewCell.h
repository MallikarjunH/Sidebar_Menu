//
//  DeclineTableViewCell.h
//  emSigner
//
//  Created by Administrator on 1/24/17.
//  Copyright © 2017 Emudhra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeclineTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *customView;
@property (weak, nonatomic) IBOutlet UIImageView *declineImage;
@property (weak, nonatomic) IBOutlet UILabel *documentName;
@property (weak, nonatomic) IBOutlet UILabel *profileName;
@property (weak, nonatomic) IBOutlet UILabel *dateLable;
@property (weak, nonatomic) IBOutlet UIButton *docInfoBtn;
@property (weak, nonatomic) IBOutlet UILabel *numberOfAttachmentsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *attachmentsImage;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (IBAction)docInfoBtn:(id)sender;

@end