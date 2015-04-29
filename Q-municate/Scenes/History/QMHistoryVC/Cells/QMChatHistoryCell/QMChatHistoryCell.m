//
//  QMChatHistoryCell.m
//  Q-municate
//
//  Created by Andrey Ivanov on 11.03.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMChatHistoryCell.h"
#import "QMImageView.h"
#import "QMBadgeView.h"

@interface QMChatHistoryCell()

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet QMBadgeView *badgeView;

@property (strong, nonatomic) NSString *time;
@property (strong, nonatomic) NSString *badgeText;

@end

@implementation QMChatHistoryCell

+ (NSString *)cellIdentifier {
    
    return @"QMChatHistoryCell";
}

- (void)awakeFromNib {

    [super awakeFromNib];

    self.timeLabel.text = nil;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark - Setters

- (void)setTime:(NSString *)time {

    if (![_time isEqualToString:time]) {
        
        _time = time;
        self.timeLabel.text = _time;
    }
}

- (void)setBadgeText:(NSString *)badgeText {
    
    if (![_badgeText isEqualToString:badgeText]) {
        
        _badgeText = badgeText;
        
        if (badgeText.length == 0) {
            
        }
    }
}

@end
