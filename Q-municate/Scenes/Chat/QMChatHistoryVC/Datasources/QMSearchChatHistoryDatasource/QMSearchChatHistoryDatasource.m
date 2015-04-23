//
//  QMSearchChatHistoryDatasource.m
//  Q-municate
//
//  Created by Andrey Ivanov on 11.03.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMSearchChatHistoryDatasource.h"

#import "QMChatHistoryCell.h"
#import "QMAddContactCell.h"
#import "QMSearchStatusCell.h"

@implementation QMSearchChatHistoryDatasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Loading Cell
    if (indexPath.row == (signed)self.collection.count) {

        QMSearchStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:QMSearchStatusCell.cellIdentifier
                                                                   forIndexPath:indexPath];

        NSString *title = self.totalEntries == self.loadedEntries ? @"No more results": @"Loading...";
        [cell setTitle:title];
        
        cell.showActivityIndicator = (self.totalEntries != self.loadedEntries);

        return cell;
    }
    
    else {
        //Contact cell
        QMAddContactCell *cell = [tableView dequeueReusableCellWithIdentifier:QMAddContactCell.cellIdentifier
                                                              forIndexPath:indexPath];
        QBUUser *user = self.collection[indexPath.row];
        cell.contact = user;
        cell.delegate = self.addContactHandler;
        
        [cell setTitle:user.fullName];
        [cell highlightTitle:self.searchText];
        
        return cell;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.collection.count + 1;
}

@end
