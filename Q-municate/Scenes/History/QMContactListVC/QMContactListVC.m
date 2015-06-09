//
//  QMContactListVC.m
//  Q-municate
//
//  Created by Andrey Ivanov on 24.04.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMContactListVC.h"
#import "QMContactListDataSource.h"
#import "QMContactCell.h"
#import "QMServicesManager.h"

@implementation QMContactListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /** Configure datasource */
    self.contactListDatasource = [[QMContactListDataSource alloc] init];
    self.contactListDatasource.selectable = self.selectable;
    
    /** Configure tableView */
    self.tableView.dataSource = self.contactListDatasource;
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexColor = [UIColor colorWithRed:0.071 green:0.357 blue:0.643 alpha:1.000];
    self.tableView.rowHeight = [QMContactCell height];
    /** Register nib's */
    [QMContactCell registerForReuseInTableView:self.tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.selectable) {

        if ([self.contactListDatasource isSelectedObjectAtIndedx:indexPath]) {
            
            [self.contactListDatasource deselectObjectAtIndexPath:indexPath];
        }
        else {
            
            [self.contactListDatasource selectObjectAtIndexPath:indexPath];
        }
        
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
}

@end