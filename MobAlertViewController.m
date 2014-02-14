 //
//  MobAlertViewController.m
//  FoodMob
//
//  Created by FoodMob on 6/6/13.
//  Copyright (c) 2013 fwthanh. All rights reserved.
//
#import "MobAlertViewController.h"
#import "AlertCellDefault.h"
#import "GUIManager.h"
#import "UITableViewLoadingCell.h"
#import "AlertManager.h"
#import "ConnectionAcceptFriend.h"
#import "UIAlertViewBlock.h"
#import "ProfileView.h"
#import "TSPopoverController.h"
#import "UIAlertViewGroups.h"
#import "localized.h"
#import "DetailPost.h"
#import "CommentView.h"
#import "MobAlertManager.h"
#import <QuartzCore/QuartzCore.h>
#import "KGModal.h"
#import "ConnectionFollowResponse.h"
#import "ConnectionFollowResquestSession.h"
#import "DirectionsExample.h"
#import "DetailMobBook.h"
#import "SettingAlertTable.h"
#import "SSpot.h"
#import <sqlite3.h>
#import "MobFriendsViewController.h"
@interface MobAlertViewController ()
{
    IBOutlet UINavigationItem *naviBarItemSetting;
}

@end

@implementation MobAlertViewController
@synthesize alerts;
@synthesize idGroups;
-(UITableView *)tableView
{
    return tableAlert;
}

-(bool)tableTemplateCanLoadMore
{
    return true;
}

-(bool)tableTemplateCanLoadReload
{
    return true;
}
-(id)init
{
    if (IS_IPHONE_5) {
        self=[super initWithNibName:@"MobAlertViewController_320x568" bundle:nil];
    }
    else
    {
        self=[super initWithNibName:@"MobAlertViewController" bundle:nil];
        
    }
    return self;

}
-(void)showGroupWithObject:(MobAlertObject*)alertList
{
    self.idGroups = [NSArray array];
    arrayGroup = [[NSMutableArray alloc]init];
    
    sqlite3 *sql_database;
    const char *dbPath = [[Utility pathDatabase] UTF8String];
    if (sqlite3_open(dbPath, &sql_database) == SQLITE_OK)
    {
        sqlite3_stmt *stament;
        NSString *sql = [NSString stringWithFormat:@"Select zIDGROUP, zNAME From zGROUPS Where zIDUSER = %@ ORDER BY zNAME ASC",[CoreDataManager shareInstance].currentUser.idUser];
        const char *query_stmt = [sql UTF8String];
        if (sqlite3_prepare_v2(sql_database, query_stmt, -1, &stament, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(stament) == SQLITE_ROW)
            {
                ListGroup *listGroup = [[ListGroup alloc] init];
                
                listGroup.idGroup = sqlite3_column_int(stament, 0);
                listGroup.groupName = [[NSString alloc]initWithUTF8String:(const char *)sqlite3_column_text(stament, 1)];
                
                [arrayGroup addObject:listGroup];
            }
            ListGroup *listGroup = [[ListGroup alloc] init];
            
            listGroup.idGroup = 0;
            listGroup.groupName = @"All";
            [arrayGroup insertObject:listGroup atIndex:0];
        }
    }
    
    self.alertGroup = [MLTableAlert tableAlertWithTitle:@"Choose a Group..." cancelButtonTitle:@"Cancel" numberOfRows:^NSInteger (NSInteger section)
                       {
                           return arrayGroup.count;
                       }
                                               andCells:^UITableViewCell* (MLTableAlert *anAlert, NSIndexPath *indexPath)
                       {
                           ListGroup *getGroup = (ListGroup *)[arrayGroup objectAtIndex:indexPath.row];
                           static NSString *CellIdentifier = @"CellIdentifier";
                           UITableViewCell *cell = [anAlert.table dequeueReusableCellWithIdentifier:CellIdentifier];
                           if (cell == nil)
                               cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                           
                           cell.textLabel.text = getGroup.groupName;
                           return cell;
                       }];
   	self.alertGroup.height = 268;
    [self.alertGroup configureSelectionBlock:^(NSIndexPath *selectedIndex)
     {
         ListGroup *getGroup = (ListGroup *)[arrayGroup objectAtIndex:selectedIndex.row];
         self.idGroups=[NSArray arrayWithObject:[NSNumber numberWithInt:getGroup.idGroup]];
         [self AcceptFriendWithObject:alertList];
         //[tableFriend reloadData];
         
     } andCompletionBlock:^{
         NSLog(@"Cancel");
     }];
    [self.alertGroup show ];
}
-(void)AcceptFriendWithObject:(MobAlertObject*)alertList
{
    if(self.idGroups.count>0)
    {
        NSMutableArray *arrGroup=[[NSMutableArray alloc]init];
        for (NSNumber*number in idGroups) {
            NSDictionary *dicGroup=[[NSDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"%@",number],ID_GROUP, nil];
            [arrGroup addObject:dicGroup];
            
        }
          [self sendAcceptFriendWithidGroups:arrGroup idFriend:alertList.idUser];
    }
    else
    {
        [self sendAcceptFriendWithidGroups:[[NSArray alloc] init]  idFriend:alertList.idUser];
    }

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableTemplate=[[TableTemplate alloc] initWithTableView:tableAlert withDelegate:self];
    _currentPage=1;
    arrayJump = [[NSMutableArray alloc]init];
    
    ConnectionGetListAlert *conn=[[ConnectionGetListAlert alloc]initConnection:self];
    [conn sendPostGetListAlert:_currentPage];
    [self performSelector:@selector(displayActivityView) withObject:nil afterDelay:0.01];
    self.title=@"MobAlert";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobAlertReceiveAlert:) name:NOTIFICATION_MOBALERT_RECEIVE_ALERT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mobAlertTouchedAlert:) name:NOTIFICATION_MOBALERT_TOUCHED_ALERT object:nil];
    barLocation.enabled = NO;
    barGo.enabled = NO;
    naviItem.title = [localized languageSelected:@"NoticeDialog_Title"];
    barGo.title = [localized languageSelected:@"NewNotificationDialog_Event_Goto"];
    barLocation.title = [localized languageSelected:@"NewNotificationDialog_Button_Location"];
    [viewEvent.layer setBorderColor: [[UIColor orangeColor] CGColor]];
    [viewEvent.layer setBorderWidth: 4.0];
    viewEvent.layer.cornerRadius = 4.0;
    viewEvent.layer.masksToBounds = YES;
    UIBarButtonItem *btnBarbutton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_setting.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showOptions:)];
    self.navigationItem.rightBarButtonItem = btnBarbutton;
    [naviItemSetting setTitle:[localized languageSelected:@"menu_settings"]];
    [btnMarkAsRead setTitle:[localized languageSelected:@"Mark_As_Read"] forState:UIControlStateNormal];
    [btnAudioSetting setTitle:[localized languageSelected:@"Audio_Setting"] forState:UIControlStateNormal];
    
}
-(void)displayActivityView
{
    [[GUIManager shareInstance]showIndicatorLoadingView:self.view msg:[localized languageSelected:@"ProgressDialogText2"]];
}


- (IBAction)showAudioSetting:(id)sender
{
    [[KGModal sharedInstance] dissmissButton];
    SettingAlertTable *setting = [[SettingAlertTable alloc]init];
    setting.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:setting animated:YES];
}
- (IBAction)markAsRead:(id)sender
{
    //Action for mark as read
    [[KGModal sharedInstance] dissmissButton];
    [[GUIManager shareInstance]showIndicator:self.view msg:[localized languageSelected:@"ProgressDialogText2"]];
    _checkReadAll=YES;
    [[GlobalData shareInstance:self]sendPostFeedBackAlertWithIdAler:-1 withStatusRead:MSG_READ];
    
}
-(void) showOptions:(id) sender
{
    [naviBarSetting setTintColor:[UIColor orangeColor]];
    [naviBarItemSetting setTitle:[localized languageSelected:@"MobAlert_button_setting_title"]];
    
    [viewSetting.layer setCornerRadius:5.0];
    
    [btnAudioSetting setTitle:[localized languageSelected:@"MobAlert_button_setting_audio"] forState:UIControlStateNormal];
    [btnMarkAsRead setTitle:[localized languageSelected:@"MobAlert_button_setting_mark_as_read"] forState:UIControlStateNormal];
    
    [[KGModal sharedInstance] setShowCloseButton:NO];
    [[KGModal sharedInstance] showWithContentView:viewSetting andAnimated:YES];
}
-(void)tableTemplateRegisterCell:(UITableView *)tableView
{
    [tableAlert registerNib:[UINib nibWithNibName:[AlertCellDefault reuseIdentifier] bundle:nil] forCellReuseIdentifier:[AlertCellDefault reuseIdentifier]];
}

-(void) mobAlertTouchedAlert:(NSNotification*) notification
{
    [tableAlert reloadData];
}

-(void) mobAlertReceiveAlert:(NSNotification*) notification
{
    MobAlertObject *obj=notification.object;
    
    if(obj.alertType==ALERT_FRIEND_MOBNICK)
        return;
    
    if(!self.alerts)
        self.alerts=[NSMutableArray array];
    
    [self.alerts insertObject:obj atIndex:0];
    
    NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
    [_tableTemplate insertRowAtIndexPath:indexPath];
    
    [_tableTemplate endLoadData:tableAlert];
}


//-(void) pushBack:(id) sender
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [self.navigationController popViewControllerAnimated:true];
//}

-(int)tableTemplateNumberOfRowPerPage:(UITableView *)tableView
{
    return DEFAULT_NUMBER_OF_PAGE;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.alerts.count;
}

-(int)tableTemplateSourceDataCount:(UITableView *)tableView
{
    return self.alerts.count;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   // if(!self.alerts)
    //    [[GUIManager shareInstance] showIndicator:self.tabBarController.view msg:[localized localizeLoading]];
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MobAlertObject *alert = [self.alerts objectAtIndex:indexPath.row];
    AlertCellDefault *cell = [tableView dequeueReusableCellWithIdentifier:[AlertCellDefault reuseIdentifier]];
    [cell reset];
    NSString *msg=@"";
    NSString *mobnick=@"";
    if(alert.idUser!=0)
    {
        if(alert.mobnick.length>0)
            mobnick=[NSString stringWithStringDefault:alert.mobnick];
        else
        {
            User *user = [User userWithID:alert.idUser];
            if(user && user.mobNick.length>0)
                mobnick=[NSString stringWithStringDefault:user.mobNick];
        }
    }
    msg=alert.msg;
    if(alert.idUser==0)
        [cell loadImage:[UIImage imageNamed:@"foodmob_logo.png"]];
    else
    {
        if([[CoreDataManager shareInstance].currentUser friendsWithIDFriend:alert.idUser])
            [cell loadImageWithUserID:alert.idUser];
        else
            [cell loadImageWithURL:[NSURL URLWithString:SERVER_IMAGE_MAKE(alert.avatar)]];
    }
    [cell loadContent:msg];
    [cell bold:alert.alertStatus!=MSG_READ];

    if(alert.dateClient)
    {
        NSDate *date=[NSDate dateWithTimeIntervalSinceNow:-[NSTimeZone systemTimeZone].secondsFromGMT];
        NSDateComponents *dateDiff=[[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:alert.dateClient toDate:date options:0];
        NSString *time=@"";
        if(dateDiff.day>0)
            time=[localized mobAlertDayAgo:dateDiff.day];
        else if(dateDiff.hour>0)
            time=[localized mobAlertHourAgo:dateDiff.hour];
        else if(dateDiff.minute>0)
            time=[localized mobAlertMinuteAgo:dateDiff.minute];
        else
            time=[localized languageSelected:@"JustNow"];
        
        [cell loadTime:time];
    }
    
    if(alert.idAlert==_selectedIDAlert)
        [tableView selectRowAtIndexPath:indexPath animated:true scrollPosition:UITableViewScrollPositionNone];
    
    return cell;
}

- (void)viewDidUnload {
    tableAlert = nil;
    [super viewDidUnload];
}

-(void)tableTemplateLoadNext:(UITableView *)tableView needWait:(bool *)needWait
{
    ConnectionGetListAlert *conn=[[ConnectionGetListAlert alloc] initConnection:self];
    [conn sendPostGetListAlert:_currentPage];
    *needWait=true;
    
}
-(void)processConnectionFinishWithConn:(ConnectionGetListAlert *)connection withParams:(NSDictionary *)jsondata withPacket:(NSString *)packet
{
    if ([packet isEqualToString:URL_GET_LIST_ALERT]) {
        //  update the last update date
        [[GUIManager shareInstance] removeIndicatorLoadingView];
        [[GUIManager shareInstance] removeIndicator:self.view];
        ConnectionGetListAlert* conn = (ConnectionGetListAlert*) connection;
        if(_currentPage==1)
            self.alerts=[[NSMutableArray alloc]init];
        
        if(conn.alerts && conn.alerts.count>0)
        {
            _currentPage+=1;
            [self.alerts addObjectsFromArray:[conn.alerts copy]];
        }
        [_tableTemplate endLoadData:tableAlert];
    }
}
-(void)processCommand:(NSString *)packet withData:(NSDictionary *)jsonData
{
    if ([packet isEqualToString:URL_FEED_BACK_ALERT]) {
        if (_checkReadAll==YES) {
            int result=[[jsonData objectForKey:RESULT]integerValue];
            if (result==ACT_OK) {
                [[GUIManager shareInstance]removeIndicator:self.view];
                [[MobAlertManager shareInstance] setNumberOfAlert:0];
                _currentPage=1;
                _checkReadAll=NO;
                ConnectionGetListAlert *conn=[[ConnectionGetListAlert alloc] initConnection:self];
                [conn sendPostGetListAlert:_currentPage];
            }
        }
    }
    else if ([packet isEqualToString:URL_REJECT_FRIEND])
    {
           [[GUIManager shareInstance]removeIndicator:self.view];
        int result=[[jsonData objectForKey:RESULT]integerValue];
        if (result==ACT_OK) {
         
            [AlertManager showAlertOKWithTitle:nil withMessage:[localized languageSelected:@"Alert12"] onOK:^{
                
                [self.alerts removeObjectAtIndex:[_tableTemplate indexPathForSelectorRow:tableAlert].row];
                [tableAlert reloadData];
            }];
        }
        else if (result==ACT_FAIL)
        {
            [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_ERROR icon:nil content:[localized languageSelected:@"Error14"] tag:nil closedWhenTouch:NO];
            
        }
    }
    if ([packet isEqualToString:URL_ACCEPT_FRIEND]) {
        
        [[GUIManager shareInstance] removeIndicator:self.view];
        int idUser=[[jsonData objectForKey:ID_USER] integerValue];
        if(idUser==-1)
        {
           [AlertManager showAlertOKWithTitle:nil withMessage:[localized mobAlertAcceptFriendFailed] onOK:nil];
            return;
        }
        
        User *user = [User userWithID:idUser];
        if(!user)
            user=[User insert];
        
        user.idUser=[NSNumber numberWithInt:idUser];
        user.mobNick=[jsonData objectForKey:MOBNICK];
        user.mood=[jsonData objectForKey:MOOD];
        user.avata=[NSString stringWithStringDefault:[jsonData objectForKey:AVATAR]];
        Friends *friend=[[CoreDataManager shareInstance].currentUser friendsWithIDFriend:idUser];
        if(!friend)
            friend=[Friends insert];
        
        friend.user=[CoreDataManager shareInstance].currentUser;
        friend.idUser=[CoreDataManager shareInstance].currentUser.idUser;
        friend.idFriend=[NSNumber numberWithInt:idUser];
        NSArray *arrGroups=[jsonData objectForKey:GROUP];
        for(int i=0;i<arrGroups.count;i++)
        {
            NSDictionary *dicGroup=[arrGroups objectAtIndex:i];
            int idGroup=[[dicGroup objectForKey:ID_GROUP]integerValue];
            
            Groups *group=[[CoreDataManager shareInstance].currentUser groupsWithIDGroup:idGroup];
            if(!group)
                group=[Groups insert];
            
            group.user=[CoreDataManager shareInstance].currentUser;
            group.idGroup=[NSNumber numberWithInt:idGroup];
            group.idUser=[CoreDataManager shareInstance].currentUser.idUser;
            
            GroupMember *member=[group groupMemberWithIDUser:idUser];
            if(!member)
                member=[GroupMember insert];
            
            member.groups=group;
            member.idGroup=group.idGroup;
            member.idMember=[NSNumber numberWithInt:idUser];
        }
        
        [AlertManager showAlertOKWithTitle:nil withMessage:[localized mobAlertFriendAccepted] onOK:^{
            [self.alerts removeObjectAtIndex:[_tableTemplate indexPathForSelectorRow:tableAlert].row];
            [tableAlert reloadData];
        }];
        [[CoreDataManager shareInstance] saveContext];
    }
    else if ([packet isEqualToString:URL_RESPONSE_FOLLOW]||[packet isEqualToString:URL_REQUEST_FOLLOW_SESSION])
    {
        [[GUIManager shareInstance] removeIndicator:self.view];
    
    }
    
//    else if ([packet isEqualToString:URL_DETAIL_POST])
//    {
//        if ([jsonData objectForKey:ERRORCODE]) {
//            [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_ERROR icon:nil content:[localized languageSelected:@"Error14"] tag:nil closedWhenTouch:NO];
//            return;
//        }
//        
//        SSpot *spot=[[SSpot alloc]init];
//        spot.idSpot=[[jsonData objectForKey:ID_SPOT]integerValue];
//        if (spot.idSpot==-1) {
//            [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_ERROR icon:nil content:[localized languageSelected:@"Error14"] tag:nil closedWhenTouch:NO];
//        }
//        else
//        {
//            spot.spotName=[jsonData objectForKey:SPOT_NAME];
//            spot.type=[[jsonData objectForKey:TYPE]integerValue];
//            spot.address=[jsonData objectForKey:ADDRESS];
//            spot.picture=[jsonData objectForKey:PHOTO_URL];
//            spot.numPost=[[jsonData objectForKey:NUM_POST]integerValue];
//            spot.numMobScan=[[jsonData objectForKey:NUM_SCAN]integerValue];
//            spot.numPic=[[jsonData objectForKey:NUM_PIC]integerValue];
//            spot.rating=[[jsonData objectForKey:RATING]doubleValue];
//            spot.latitude=[[jsonData objectForKey:LATITUDE]doubleValue];
//            spot.longitude=[[jsonData objectForKey:LONGITUDE]doubleValue];
//            [arrayJump addObject:[NSString stringWithFormat:@"%i",spot.idSpot]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%i",spot.type]];
//            [arrayJump addObject:spot.spotName];
//            [arrayJump addObject:spot.address];
//            [arrayJump addObject:spot.picture];
//            [arrayJump addObject:[NSString stringWithFormat:@"%i",spot.numPic]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%i",spot.numMobAdd]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%i",spot.numMobScan]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%f",spot.rating]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%f",spot.latitude]];
//            [arrayJump addObject:[NSString stringWithFormat:@"%f",spot.longitude]];
//            barLocation.enabled = YES;
//
//        }
//    }
    else if ([packet isEqualToString:URL_JOIN_VILLE])
    {
        if ([jsonData objectForKey:ERRORCODE]) {
              [[GUIManager shareInstance] showNotificationWithType:ANNOUNCEMENT_ERROR icon:nil content:[localized languageSelected:@"Error14"] tag:nil closedWhenTouch:false];
        }
        int result=[[jsonData objectForKey:RESULT]integerValue];
        
        if (result==ACT_OK)
        {
            if (_acceptedJoinVille==ACT_ACCEPTED) {
                [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_DOING icon:nil content:[localized languageSelected:@"MobVilleScreen_Message_Alert14"] tag:nil closedWhenTouch:false];
            }
            else if(_acceptedJoinVille==ACT_DENIED)
            {   [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_DOING icon:nil content:[localized languageSelected:@"MobVilleScreen_Message_Error_Denied"] tag:nil closedWhenTouch:false];
                
            }
        }
        else
        {
            [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_DOING icon:nil content:[localized languageSelected:@"MobVilleScreen_Message_Error24"] tag:nil closedWhenTouch:false];
        }
        
    }
    else if ([packet isEqualToString:URL_RESPONSE_JOIN_VILLE])
    {
        int result=[[jsonData objectForKey:RESULT]integerValue];
        if (result==ACT_OK) {
            if (_acceptedJoinVille==ACT_ACCEPTED) {
                [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_DOING icon:nil content:[localized languageSelected:@"MobVilleScreen_Message_Alert14"] tag:nil closedWhenTouch:false];
            }
            else if(_acceptedJoinVille==ACT_DENIED)
            {   [[GUIManager shareInstance]showNotificationWithType:ANNOUNCEMENT_DOING icon:nil content:[localized languageSelected:@"MobVilleScreen_Message_Error_Denied"] tag:nil closedWhenTouch:false];
                
            }
            //remove row 
            [self.alerts removeObjectAtIndex:[_tableTemplate indexPathForSelectorRow:tableAlert].row];
            [tableAlert reloadData];

        }
    }
}
#pragma mark
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return _reloading;
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods
- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:tableAlert];
	
}


#pragma mark -
#pragma mark UIScrollViewDelegate Methods



-(void)canScrollViewDidScroll:(UIScrollView *)scrollView
{
   // [_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}
-(void)canScrollViewDidEndDragging:(UIScrollView *)scrollView
{
   // [_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}
#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	 
    [self reloadTableViewDataSource];
    _currentPage=1;

   ConnectionGetListAlert *conn=[[ConnectionGetListAlert alloc]initConnection:self];
    [conn sendPostGetListAlert:_currentPage];
    
}



- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MobAlertObject *alert= [self.alerts objectAtIndex:indexPath.row];
    _selectedIDAlert=alert.idAlert;
    //Unread
    if(alert.alertType==ALERT_ADD_FRIEND)
    {
        if(![[CoreDataManager shareInstance].currentUser friendsWithIDFriend:alert.idUser])
            [self askAcceptFriend];
    }
    else if(alert.alertType == ALERT_NEW_POST ||
            alert.alertType == ALERT_LIKE ||
            alert.alertType == ALERT_NEW_COMMENT ||
            alert.alertType == ALERT_POST_UPDATE ||
            alert.alertType == ALERT_TAG_FRIEND)
    {
        [self askGoToDetailPost:alert.idPost withIdSpot:alert.idSpot];
        [[NSUserDefaults standardUserDefaults] setValue:@"Yes" forKey:@"isFromAlert"];
    }
    //Goto detailPostVille
    else if (alert.alertType==ALERT_NEW_POST_VILLE||
             alert.alertType==ALERT_LIKE_POSTVILLE||
             alert.alertType==ALERT_UPDATE_POSTVILLE||
             alert.alertType==ALERT_COMMENT_POSTVILLE||
             alert.alertType==ALERT_REPORT_POSTVILLE
    )
    {
        [self askGotoDetailPostVille:alert.IdPostVille :alert.numImg :alert.contentImg];
    }
    else if (alert.alertType==ALERT_SYSTEM)
    {
        if (alert.msg.length>0) {
      
            textViewEvent.text=alert.msg;
                [barGo setTitle:[localized languageSelected:@"NoticeDialog_Button_OK"]];
                barGo.enabled=YES;
                barLocation.enabled=NO;
            
            if (alert.link.length>0)
            {
                linkToGo=alert.link;
                barGo.enabled=YES;
                barLocation.enabled=YES;
                [barGo setTitle:[localized languageSelected:@"NewNotificationDialog_Button_Goto"]];
                [barLocation setTitle:[localized languageSelected:@"ButtonErrorCancel"]];
            }
            [KGModal sharedInstance].showCloseButton=NO;
           // [[KGModal sharedInstance] setModalBackgroundColor:[UIColor clearColor]];
            [[KGModal  sharedInstance]showWithContentView:viewEvent andAnimated:YES];
        }
    }
    else if (alert.alertType == ALERT_EVENT)
    {
        barLocation.enabled=YES;
        barGo.enabled=YES;
        if (alert.msg.length>0) {
            textViewEvent.text=alert.msg;
        }
        if ([alert.link isEqual:@""]) {
                  barGo.enabled=NO;
        }
        else
        {
            linkToGo=alert.link;
            barGo.enabled=YES;
            [barGo setTitle:[localized languageSelected:@"NewNotificationDialog_Button_Goto"]];
            [barLocation setTitle:[localized languageSelected:@"ButtonErrorCancel"]];
        }
    
        if (alert.idSpot==-1) {
           
                [barGo setTitle:[localized languageSelected:@"NewNotificationDialog_Button_Goto"]];
                [barLocation setTitle:[localized languageSelected:@"ButtonErrorCancel"]];
        }
        else
        {
                [barGo setTitle:[localized languageSelected:@"NewNotificationDialog_Event_Goto"]];
                [barLocation setTitle:[localized languageSelected:@"NewNotificationDialog_Button_Location"]];
                _idSpot=alert.idSpot;
            }
          
            [KGModal sharedInstance].showCloseButton = NO;
            [[KGModal sharedInstance] setModalBackgroundColor:[UIColor clearColor]];
            [[KGModal sharedInstance] showWithContentView:viewEvent andAnimated:YES];
            if (_idSpot!=0) {
                [[GlobalData shareInstance:self]sendPostSpotDetailWithIdSpot:_idSpot ];
                
            }
        
        
    }
    else if(alert.alertType==ALERT_SHAKE)
    {
        [self showMobShakeWithIDUser:alert.idUser withMobnick:alert.mobnick];
    }
    else if (alert.alertType == ALERT_FOLLOW_REQUEST)
    {
        [self askAcceptFollowResponse];
    }
    else if (alert.alertType == ALERT_FOLLOW_RESPONSE)
    {
        
    }
    else if (alert.alertType == ALERT_FOLLOW_INFO)
    {
        [self askAcceptFollowInfo];
    }
    else if (alert.alertType == ALERT_JOIN_VILLE_RESPONSE || alert.alertType == ALERT_NEW_POST_VILLE)
    {
        [self askGoToDetailVille:alert.idVille withName:alert.villeName];
    }
    else if (alert.alertType == ALERT_JOIN_VILLE_REQUEST)
    {
        [self askAcceptJoinVille];
    }
    if(alert.alertStatus!=MSG_READ)
    {
        switch (alert.alertType) {
            case ALERT_ADD_FRIEND:
                [self.alerts replaceObjectAtIndex:indexPath.row withObject:alert];
                [[GlobalData shareInstance:self]sendPostFeedBackAlertWithIdAler:alert.idAlert withStatusRead:alert.alertStatus];
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NUMBER_ALERT_READ object:nil];
                break;
            case ALERT_SYSTEM:
            case ALERT_EVENT:
            case ALERT_ACCEPT_FRIEND:
            case ALERT_FOLLOW_REQUEST:
            case ALERT_FOLLOW_INFO:
            case ALERT_FOLLOW_RESPONSE:
            case ALERT_LIKE:
            case ALERT_NEW_POST:
            case ALERT_NEW_COMMENT:
            case ALERT_TAG_FRIEND:
            case ALERT_SHAKE:
            case ALERT_POST_UPDATE:
            case ALERT_JOIN_VILLE_RESPONSE:
            case ALERT_JOIN_VILLE_REQUEST:
            case ALERT_NEW_POST_VILLE:
            case ALERT_UPDATE_POSTVILLE:
            case ALERT_REPORT_POSTVILLE:
            case ALERT_LIKE_POSTVILLE:
            case ALERT_COMMENT_POSTVILLE:
            case ALERT_VILLE_LOCK_MEMBER:
                alert.alertStatus=MSG_READ;
                [self.alerts replaceObjectAtIndex:indexPath.row withObject:alert];
                [[GlobalData shareInstance:self]sendPostFeedBackAlertWithIdAler:alert.idAlert withStatusRead:alert.alertStatus];
                   [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NUMBER_ALERT_READ object:nil];
                break;
                
            default:
                break;
        }
        
     
    }
    
    AlertCellDefault*cell = (AlertCellDefault*)[_tableTemplate cellForRowAtIndexPath:tableView indexPath:indexPath];
    [cell bold:alert.alertStatus!=MSG_READ];
}
-(void)askGotoDetailPostVille:(long)idpostVille :(int)numImage :(NSString*)content
{
    [[GUIManager shareInstance]showDetailPostVille:idpostVille :numImage :content];
}
-(void) askGoToDetailPost:(long) idPost withIdSpot:(int)idSpot
{
    [[GUIManager shareInstance] showDetailPost:idPost withIdSpot:idSpot];
}
-(void) askGoToDetailVille:(int) idVille withName:(NSString *)nameVille
{
    [[GUIManager shareInstance] showVille:idVille with:nameVille];
}

-(void) askAcceptFriend
{
    if(![_tableTemplate indexPathForSelectorRow:tableAlert])
        return;
    
    int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
    
    if(self.alerts.count<row)
        return;

    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:[localized languageSelected:@"FriendRequestOption_Title"] message:nil delegate:self cancelButtonTitle:[localized languageSelected:@"Option_Alert_Profile"] otherButtonTitles:[localized languageSelected:@"Option_Alert_Accept"], [localized languageSelected:@"Option_Alert_Reject"],[localized languageSelected:@"SuggestDialog_Button_Cancel"], nil];
    alert.tag=1;
    [alert show];
    //[alert setBackground:[UIColor orangeColor]];
}

-(void) askAcceptFollowResponse
{    
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:[localized localizeAccept],[localized localizeCancel], nil];
    
    alert.tag=3;
    [alert show];
    //[alert setBackground:[UIColor orangeColor]];
}

-(void) askAcceptFollowInfo
{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:[localized mobFollowInfo] delegate:self cancelButtonTitle:nil otherButtonTitles:[localized localizeAccept],[localized localizeCancel], nil];
    
    alert.tag=4;
    [alert show];
    //[alert setBackground:[UIColor orangeColor]];
}
-(void) askAcceptJoinVille
{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:[localized languageSelected:@"ButtonErrorCancel"] otherButtonTitles:[localized languageSelected:@"MobAlertButton_button_Accept"],[localized languageSelected:@"MobAlertButton_button_Denied"],[localized languageSelected:@"Option_Alert_Profile"],nil];
    
    alert.tag=5;
    [alert show];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==1)
    {
        int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
        MobAlertObject *alertList=[self.alerts objectAtIndex:row];
        //Profile
        if(buttonIndex==0)
        {
            _appearFromViewProfile=true;
            ProfileView *profile = [[ProfileView alloc] initWithIdUser:alertList.idUser nameProfile:alertList.mobnick mood:alertList.mood];
            [self.navigationController pushViewController:profile animated:true];
        }
        //Accept
        else if(buttonIndex==1)
        {
            [self showGroupWithObject:alertList];
        }
        //Delince
        else if (buttonIndex == 2) {
            [self sendRejectFriendWithIdFriend:alertList.idUser];
        }
    }
    else if(alertView.tag==2)
    {
        UIAlertViewGroups *alertGroup=(UIAlertViewGroups*) alertView;
        int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
        MobAlertObject *alertList=[self.alerts objectAtIndex:row];
        NSArray *array = [alertGroup.selectedGroups copy];
        
        if(array.count==0)
            [self sendAcceptFriendWithidGroups:array idFriend:alertList.idUser];
        else
            [self sendAcceptFriendWithidGroups: array idFriend:alertList.idUser];
    }
    else if (alertView.tag==3)
    {
        int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
        MobAlertObject *alertList=[self.alerts objectAtIndex:row];
        if (buttonIndex==0)
        {
            [self sendFollow:alertList.idUser status:ACT_ACCEPTED idAlert:alertList.idAlert];
        }
        else if (buttonIndex==1)
        {
            [self sendFollow:alertList.idUser status:ACT_DENIED idAlert:alertList.idAlert];
        }
    }
    else if (alertView.tag == 4)
    {
        int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
        MobAlertObject *alertList=[self.alerts objectAtIndex:row];
        if (buttonIndex==0)
        {
            [self sendFollow:alertList.idUser status:0 idAlert:alertList.idAlert];
        }
        [self showFollowInfo:alertList.idUser latitude:alertList.latitude longtitude:alertList.longitude];
    }
    else if (alertView.tag == 5)
    {
        int row = [_tableTemplate indexPathForSelectorRow:tableAlert].row;
        MobAlertObject *alertList=[self.alerts objectAtIndex:row];
        switch (buttonIndex) {
            case 1:
            {
                _acceptedJoinVille=ACT_ACCEPTED;
                [[GlobalData shareInstance:self]sendPostResponeJoinVilleWithIdVille:alertList.idVille withIdMember:alertList.idUser withStatus:ACT_ACCEPTED withIdManager:-1 withIdAlert:alertList.idAlert];
            }
                break;
                
            case 2:
            {
                _acceptedJoinVille=ACT_DENIED;
                [[GlobalData shareInstance:self]sendPostResponeJoinVilleWithIdVille:alertList.idVille withIdMember:alertList.idUser withStatus:ACT_DENIED withIdManager:DEFAULT_SEND_ENTRY withIdAlert:alertList.idAlert];
                
            }
                break;
            case 3:
            {
                ProfileView *profile = [[ProfileView alloc] initWithIdUser:alertList.idUser nameProfile:alertList.mobnick mood:alertList.mood];
                [self.navigationController pushViewController:profile animated:true];
            }
                break;
                
            default:
                break;
        }
    }
}

-(void) sendAcceptFriendWithidGroups:(NSArray*) arrIdGroups idFriend:(int) idFriend
{
    [[GlobalData shareInstance:self]sendPostAcceptFriendWithIdUser:idFriend withGroup:arrIdGroups];
    [[GUIManager shareInstance] showIndicator:self.view msg:[localized localizeRequest]];
}
-(void)sendRejectFriendWithIdFriend:(int)idFriend
{
    [[GlobalData shareInstance:self]sendPostRejectFriendWithIdUser:idFriend];
    [[GUIManager shareInstance]showIndicator:self.view msg:[localized localizeRequest]];
    
}

-(void) sendFollow:(int)idUser status:(int)status idAlert: (long)idAlert
{
    if (status != 0)
    {
        [[GlobalData shareInstance:self]sendPostResponseFollowWithIdUser:idUser withStatus:status withIdAlert:idAlert];
    }
    else
    {
        [[GlobalData shareInstance:self]sendPostRequestFollowSessionWithIdUser:idUser];
        
    }
}

-(void) showFollowInfo:(int)idUser latitude:(double)latitude longtitude:(double)longtitude
{
    User *user=[User userWithID:idUser];
    DirectionObject *diObject = [[DirectionObject alloc] initWithSpotType:FRIEND mobnick:user.mobNick searchType:SEARCH_USER key:[NSString stringWithFormat:@"%@",user.idUser] latitude:0 longtitude:0];
    DirectionsExample *direct = [[DirectionsExample alloc] initWithNibName:@"DirectionsExample" bundle:nil];
    [direct setDirectionObject:diObject willShowed:false];
    [self.navigationController pushViewController:direct animated:YES];
}

-(void)showMobShakeWithIDUser:(int)idUser withMobnick:(NSString *)mobNick
{
    DirectionObject *diObject = [[DirectionObject alloc] initWithSpotType:FRIEND mobnick:mobNick searchType:SEARCH_USER key:[NSString stringWithFormat:@"%i",idUser] latitude:0 longtitude:0];
    DirectionsExample *direct = [[DirectionsExample alloc] initWithNibName:@"DirectionsExample" bundle:nil];
    [direct setDirectionObject:diObject willShowed:false];
    [self.navigationController pushViewController:direct animated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(_appearFromViewProfile)
    {
        [self askAcceptFriend];
        
        _appearFromViewProfile=false;
    }
}
- (IBAction)barGoTouchUpInside
{
    if ([barGo.title isEqual:[localized languageSelected:@"NewNotificationDialog_Button_Goto"]]||[barGo.title isEqual:[localized languageSelected:@"NewNotificationDialog_Event_Goto"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkToGo]];
    }
    else if([barGo.title isEqual:[localized languageSelected:@"NoticeDialog_Button_OK"]])
    {
        [[KGModal sharedInstance]dissmissButton];
    }
}
- (IBAction)barLocationTouchUpInside
{
    [[KGModal sharedInstance]dissmissButton];
    if ([barLocation.title isEqual:[localized languageSelected:@"NewNotificationDialog_Button_Location"]])
    {
        
        [[NSUserDefaults standardUserDefaults] setValue:@"fromMobBook" forKey:@"MobFindBook"];
        DetailMobBook *detail = [[DetailMobBook alloc] initWithIDSpot:_idSpot];
        [self.navigationController pushViewController:detail animated:YES];
    }
}
- (IBAction)barCloseTouchUpInside
{
    [[KGModal sharedInstance] dissmissButton];
}
@end
