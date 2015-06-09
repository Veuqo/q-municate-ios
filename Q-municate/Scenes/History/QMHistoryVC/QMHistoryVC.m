//
//  QMHistoryVC.m
//  Q-municate
//
//  Created by Andrey Ivanov on 11.03.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMHistoryVC.h"
#import "QMServicesManager.h"

#import "QMHistoryDataSource.h"
#import "QMGlobalSearchDataSource.h"
#import "QMLocalSearchDataSource.h"

#import "QMNotificationView.h"
#import "QMProfileTitleView.h"
#import "QMAddContactCell.h"
#import "QMChatHistoryCell.h"
#import "QMSearchStatusCell.h"

#import "QMSearchController.h"
#import "QMTasks.h"
#import "QMChatVC.h"

const NSTimeInterval kQMKeyboardTapTimeInterval = 1.f;

typedef NS_ENUM(NSUInteger, QMSearchScopeButtonIndex) {
    
    QMSearchScopeButtonIndexLocal,
    QMSearchScopeButtonIndexGlobal
};

@interface QMHistoryVC ()

<QMContactListServiceDelegate,  QMAddContactProtocol, QMChatServiceDelegate, QMHistoryDataSourceHandler, QMProfileTitleViewDelegate>
/**
 *  Datasources
 */
@property (strong, nonatomic) QMHistoryDataSource *historyDataSource;
@property (strong, nonatomic) QMGlobalSearchDataSource *globalSearchDatasource;
@property (strong, nonatomic) QMLocalSearchDataSource *localSearchDatasource;
/**
 *  Notification view
 */
@property (strong, nonatomic) QMNotificationView *notificationView;

@property (weak, nonatomic) QBRequest *searchRequest;

@property (assign, nonatomic) BOOL globalSearchIsCancelled;
@property (strong, nonatomic) QMProfileTitleView *titleView;

@end

@implementation QMHistoryVC

#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerNibs];
    //Init datasources
    self.historyDataSource = [[QMHistoryDataSource alloc] init];
    self.historyDataSource.handler = self;
    self.tableView.dataSource = self.historyDataSource;
    self.globalSearchDatasource = [[QMGlobalSearchDataSource alloc] init];
    self.localSearchDatasource = [[QMLocalSearchDataSource alloc] init];
    self.localSearchDatasource.handler = self;
    //Configure search controller
    self.searchController.searchResultsTableView.rowHeight = 75;
    self.searchController.searchBar.scopeButtonTitles = @[@"Local", @"Global"];
    self.searchController.searchBar.backgroundColor = [UIColor colorWithWhite:0.965 alpha:1.000];
    //Subscirbe to notification
    [QM.contactListService addDelegate:self];
    [QM.chatService addDelegate:self];
    //Set profile title view
    QBUUser *user = QM.profile.userData;
    self.titleView = [[QMProfileTitleView alloc] init];
    [self.titleView setUserName:user.fullName imageUrl:user.avatarUrl];
    self.navigationItem.titleView = self.titleView;
    self.titleView.delegate = self;
    
    CGSize size = [self.titleView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    self.titleView.frame = CGRectMake(0.f, 0.f, size.width, size.height);
    //Fetch data from server

    self.notificationView = [QMNotificationView showInViewController:self];
    self.notificationView.text = @"Login...";
    self.notificationView.tintColor = [UIColor colorWithRed:0.000 green:0.800 blue:0.090 alpha:1.000];
    
    
    [self.notificationView setVisible:YES animated:NO completion:nil];
    
    [QMTasks taskLogin:^(BOOL successLogin) {
        
        self.notificationView.text = @"Fetch data...";
        self.notificationView.tintColor = [UIColor colorWithRed:1.000 green:0.639 blue:0.000 alpha:1.000];
        
        [QMTasks taskFetchDialogsAndUsers:^(BOOL successFetch) {
            
            __weak __typeof(self)weakSelf = self;
            [weakSelf.notificationView setVisible:NO animated:NO completion:^{
            }];
        }];
    }];;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   

}

- (void)contactListServiceDidLoadCache {
    
    [self.tableView reloadData];
}

- (void)contactListService:(QMContactListService *)contactListService didAddUsers:(NSArray *)users {
    
    [self.tableView reloadData];
}

#pragma mark - QMChatServiceDelegate


- (void)chatService:(QMChatService *)chatService didUpdateChatDialogsInMemoryStorage:(QBChatDialog *)chatDialog {
    
    NSUInteger idx = [self.historyDataSource.items indexOfObject:chatDialog];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)chatDialog {
    
    [self.historyDataSource addItems:@[chatDialog]];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogsToMemoryStorage:(NSArray *)chatDialogs {
    
    [self.historyDataSource replaceItems:chatDialogs];
    [self.tableView reloadData];
}

#pragma mark - Register nib's

- (void)registerNibs {
    
    [QMChatHistoryCell registerForReuseInTableView:self.tableView];
    [QMChatHistoryCell registerForReuseInTableView:self.searchController.searchResultsTableView];
    [QMAddContactCell registerForReuseInTableView:self.searchController.searchResultsTableView];
    [QMSearchStatusCell registerForReuseInTableView:self.searchController.searchResultsTableView];
}

#pragma mark - Search
#pragma mark Local

- (void)localSearch:(NSString *)searchText {
    
    [self.localSearchDatasource replaceItems:self.historyDataSource.items];
    self.localSearchDatasource.searchText = searchText;
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark Gloabal

- (void)globalSearch:(NSString *)searchText {
    
    self.globalSearchIsCancelled = NO;
    
    if (searchText.length == 0) {
        //Clear datasource
        [self.searchController.searchResultsTableView reloadData];
    }
    else {
        //Keyboard typing timeout
        int64_t keyboadTapTimeInterval = (int64_t)(kQMKeyboardTapTimeInterval * NSEC_PER_SEC);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, keyboadTapTimeInterval), dispatch_get_main_queue(), ^{
            
            if ([self.searchController.searchBar.text isEqualToString:searchText]) {
                
                if (self.globalSearchIsCancelled) {
                    
                    self.globalSearchIsCancelled = NO;
                    return;
                }
                
                [self beginGlobalSearchWithSearchText:searchText nextPage:NO];
                [self.searchController.searchResultsTableView reloadData];
            }
        });
    }
}

- (void)beginGlobalSearchWithSearchText:(NSString *)searchText nextPage:(BOOL)nextPage {
    
    if (!nextPage) {
        
        [self.globalSearchDatasource.pageManager resetPage];
    }
    
    QBGeneralResponsePage *currentPage = [self.globalSearchDatasource.pageManager nextPage];
    
    if (!currentPage) {
        return;
    }
    __weak __typeof(self)weakSelf = self;
    
    self.searchRequest =
    [QBRequest usersWithFullName:searchText page:currentPage successBlock:^(QBResponse *response, QBGeneralResponsePage *page, NSArray *users) {
        
        [weakSelf.globalSearchDatasource replaceItems:users];
        [weakSelf.globalSearchDatasource setSearchText:searchText];
        [weakSelf.globalSearchDatasource.pageManager updateCurrentPageWithResponcePage:page];
        [weakSelf.searchController.searchResultsTableView reloadData];
        weakSelf.searchRequest = nil;
        
    } errorBlock:^(QBResponse *response) {
        
        if (response.status == QBResponseStatusCodeCancelled) {
            
            NSLog(@"Global search is cancelled");
            
        } else if (response.status == QBResponseStatusCodeNotFound) {
            
            NSLog(@"Not found");
        }
    }];
}

- (void)beginSearch:(NSString *)searchString selectedScope:(NSInteger)selectedScope {
    
    if (selectedScope == QMSearchScopeButtonIndexLocal) {
        
            [self localSearch:searchString];
    }
    else if (selectedScope == QMSearchScopeButtonIndexGlobal ) {
        
            [self globalSearch:searchString];
    }
    else {
        
        NSAssert(nil, @"Unknown selectedScope");
    }
}

#pragma mark - Prepare for Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: @"ChatViewController"]) {
        
        QMChatVC *chatVC = segue.destinationViewController;
        chatVC.chatDialog = sender;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (self.searchController.isActive) {
        return;
    }
    
    QBChatDialog *chatDialog = self.historyDataSource.items[indexPath.row];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        cell.contentView.transform = CGAffineTransformScale(cell.transform, 1, 1);
        
    } completion:^(BOOL finished) {
        
        [self performSegueWithIdentifier:@"ChatViewController" sender:chatDialog];
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.searchController.searchResultsTableView &&
        self.searchController.searchBar.selectedScopeButtonIndex == QMSearchScopeButtonIndexGlobal) {
        
        if (indexPath.row == (int) self.globalSearchDatasource.items.count && self.globalSearchDatasource.items.count != 0 ) {
            
            [self beginGlobalSearchWithSearchText:self.searchController.searchBar.text nextPage:YES];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.transform = CGAffineTransformScale(cell.transform, 0.95, 0.95);
    
    return indexPath;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 75;
}

#pragma mark - Search bar

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope  {
    
    if (self.searchRequest ) {
        //Cancel global search request
        [self.searchRequest cancel];
        self.searchRequest = nil;
    }
    
    [self beginSearch:searchBar.text selectedScope:selectedScope];
}

#pragma mark - QMSearchController
#pragma mark Present

- (void)willPresentSearchController:(QMSearchController *)searchController {
    [super willPresentSearchController:searchController];
    
    self.globalSearchDatasource.addContactHandler = self;
}

- (void)didPresentSearchController:(QMSearchController *)searchController {
    
}

#pragma mark Dissmiss

- (void)willDismissSearchController:(QMSearchController *)searchController {
    [super willDismissSearchController:searchController];
    
    self.globalSearchDatasource.addContactHandler = nil;
    [self.tableView reloadData];
}

- (void)didDismissSearchController:(QMSearchController *)searchController {
    
    [super didDismissSearchController:searchController];
}

#pragma mark - QMSearchResultsUpdating

- (void)updateSearchResultsForSearchController:(QMSearchController *)searchController {
    
    if (searchController.searchBar.selectedScopeButtonIndex == QMSearchScopeButtonIndexGlobal) {
        
        self.searchController.searchResultsDataSource = self.globalSearchDatasource;
    }
    else {
        
        self.searchController.searchResultsDataSource = self.localSearchDatasource;
    }
    
    [self beginSearch:searchController.searchBar.text selectedScope:searchController.searchBar.selectedScopeButtonIndex];
}

#pragma mark - QMAddContactProtocol

- (void)didAddContact:(QBUUser *)contact {
    //Send contact request and create p2p chat
    [QM.contactListService addUserToContactListRequest:contact completion:^(BOOL success) {
        
        if (success) {
            
            [QM.chatService createPrivateChatDialogWithOpponent:contact completion:^(QBResponse *response, QBChatDialog *createdDialog) {
                //Send system message
                QBChatMessage *message = [QBChatMessage message];
                message.text = @"Contact request";
                
                [QM.chatService sendMessage:message toDialog:createdDialog save:YES completion:^(NSError *error) {
                    NSLog(@"Send contact request");
                }];
            }];
        }
    }];
}

- (BOOL)userExist:(QBUUser *)user {
    
    QBUUser *extstUser = [QM.contactListService.usersMemoryStorage userWithID:user.ID];
    return extstUser ? YES : NO;
}

#pragma mark - QMHistoryDataSourceHandler

- (QBUUser *)historyDataSource:(QMHistoryDataSource *)historyDataSource recipientWithIDs:(NSArray *)userIDs {
    
    NSArray *users = [QM.contactListService.usersMemoryStorage usersWithIDs:userIDs withoutID:QM.profile.userData.ID];
    
    return users.firstObject;
}

#pragma mark - QMProfileTitleViewDelegate

- (void)profileTitleViewDidTap:(QMProfileTitleView *)titleView {
    
    [self performSegueWithIdentifier:@"SettingsViewController" sender:nil];
}

@end