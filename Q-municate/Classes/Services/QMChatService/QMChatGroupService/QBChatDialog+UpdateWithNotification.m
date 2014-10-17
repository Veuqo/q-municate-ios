//
//  QBChatDialog+UpdateWithNotification.m
//  Q-municate
//
//  Created by Igor Alefirenko on 17.10.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QBChatDialog+UpdateWithNotification.h"

@implementation QBChatDialog (UpdateWithNotification)

- (void)updateLastMessageInfoWithMessage:(QBChatMessage *)message
{
    self.lastMessageText = message.text;
    self.lastMessageDate = message.datetime;
    self.lastMessageUserID = message.senderID;
    self.unreadMessagesCount++;
}

@end