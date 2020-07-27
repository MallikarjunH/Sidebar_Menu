//
//  HomeNewDashBoardVC.m
//  emSigner
//
//  Created by Administrator on 1/11/17.
//  Copyright © 2017 Emudhra. All rights reserved.
//

#import "HomeNewDashBoardVC.h"
#import <QuartzCore/QuartzCore.h>
#import "PendingVCTableViewCell.h"
//#import "LoadingTableViewCell.h"
#import "MPBSignatureViewController.h"
#import "WebserviceManager.h"
#import "HoursConstants.h"
#import "SingletonAPI.h"
#import "MBProgressHUD.h"
#import "DocumentInfoNames.h"
#import "NSObject+Activity.h"
#import "DocumentLogVC.h"
#import "Reachability.h"
#import "UITextView+Placeholder.h"
#import "ShareVC.h"
#import "LMNavigationController.h"
#import "ListPdfViewer.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "CustomSignVC.h"
#import "NSString+DateAsAppleTime.h"
#import "CompletedNextVC.h"
#import "ParallelSigning.h"
#import "CommentsController.h"
#import "BulkDocVC.h"

@interface HomeNewDashBoardVC ()
{
    BOOL hasPresentedAlert;
    int currentPage;
    // MuDocRef *doc;
    NSMutableString * mstrXMLString;
    UILabel *noDataLabel;
    NSString *dateCategoryString;
    BOOL isPageRefreshing;
    
    NSString* searchSting;
    NSInteger* statusId;
    NSString* pdfFilePathForSignatures;
    NSData *data;
    NSMutableArray * coordinatesArray;
    NSArray *arr;
    NSString* path;
    NSString* createPdfString;
    NSIndexPath *selectedIndex;
    const char *password;
    NSUserDefaults *save;
    NSString* statusForPlaceholders;
    BOOL isdelegate;
    BOOL isopened;
    
}
-(void)moveViewWithGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer;
@property BOOL fieldShown;
@property (strong, nonatomic) UIImageView* backgroundView;

@end

@implementation HomeNewDashBoardVC

enum
{
    ResourceCacheMaxSize = 128<<20	/**< use at most 128M for resource cache */
};

- (id)init
{
    self = [super init];
    if (self) {
        self.fieldShown = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.title =  @"My Signatures";
    
    _declineBtn.enabled = YES;
    _downloadBtn.enabled = YES;
    _shareBtn.enabled = YES;
    
    currentPage = 0;
    _pendingToolBar.hidden = YES;
    
    //Empty cell keep blank
    self.pendingTableView.contentInset = UIEdgeInsetsMake(0, 0, 65, 0);
    
    createPdfString = [NSString string];
    //[self.pendingTableView setContentOffset:CGPointMake(0.0, self.pendingTableView.tableHeaderView.frame.size.height) animated:YES];
    
    _pendingTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    /*****************************tableview delegate*********************************/
    
    [self.pendingTableView setDelegate:self];
    [self.pendingTableView setDataSource:self];
    self.navigationController.navigationBar.topItem.title = @" ";
    
    /**************************Initializing response Array*****************************/
    _pendingArray = [[NSArray alloc] init];
    _pdfImageArray = [[NSMutableArray alloc] init];
    _declineArray = [[NSMutableArray alloc] init];
    _downloadArray = [[NSMutableArray alloc] init];
    _addFile = [[NSMutableArray alloc] init];
    _signPadDict = [[NSMutableDictionary alloc]init];
    _profileArray = [[NSMutableArray alloc]init];
    
    [self.pendingTableView registerNib:[UINib nibWithNibName:@"PendingVCTableViewCell" bundle:nil] forCellReuseIdentifier:@"PendingVCTableViewCell"];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    refreshControl.backgroundColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:241.0/255.0 alpha:1.0];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.pendingTableView addSubview:refreshControl];
    statusId = 0;
}


- (void)makeServieCallWithPageNumaber:(NSUInteger)pageNumber:(NSString*)search
{
    [self startActivity:@"Refreshing"];
    
    //Network Check
    if (![self connected])
    {
        if(hasPresentedAlert == false){
            
            // not connected
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            hasPresentedAlert = true;
        }
    } else
    {
        /*************************Web Service*******************************/
        if (self.searchResults == nil) {
            self.searchResults = [[NSMutableArray alloc] init];
        }
        
        NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentsByStatus?statusId=%@&PageSize=%lu&searchFilter=%@",kAllDocumetStatusUrl,@"pending",(unsigned long)pageNumber,search];
        
        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
            
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
            {
                
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                    
                    _pendingArray=[responseValue valueForKey:@"Response"];
                    
                    if (_pendingArray != (id)[NSNull null])
                    {
                        
                        [self startActivity:@"Refreshing"];
                        isPageRefreshing=NO;
                        
                        _filterSecondArray = [[NSMutableArray alloc]initWithArray:(NSMutableArray*)_pendingArray];
                        
                        [_searchResults addObjectsFromArray:_filterSecondArray];
                        
                        noDataLabel.hidden = YES;
                        [_pendingTableView reloadData];
                        
                        [self stopActivity];
                    }
                    else
                    {
                        
                        if (_searchResults.count == 0) {
                            
                            noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.pendingTableView.bounds.size.width, self.pendingTableView.bounds.size.height)];
                            noDataLabel.text             = @"You do not have any files";
                            noDataLabel.textColor        = [UIColor grayColor];
                            noDataLabel.textAlignment    = NSTextAlignmentCenter;
                            self.pendingTableView.backgroundView = noDataLabel;
                            self.pendingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                            //
                            //                                       //hide right bar button item if there is no data
                            //                                       self.navigationItem.rightBarButtonItem = nil;
                            [_searchResults removeAllObjects];
                            [_pendingTableView reloadData];
                        }
                        [self stopActivity];
                    }
                    
                });
                
            }
            else{
                
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                    [self stopActivity];
                    if (_searchResults.count == 0) {
                        
                        noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.pendingTableView.bounds.size.width, self.pendingTableView.bounds.size.height)];
                        noDataLabel.text             = @"You do not have any files";
                        noDataLabel.textColor        = [UIColor grayColor];
                        noDataLabel.textAlignment    = NSTextAlignmentCenter;
                        self.pendingTableView.backgroundView = noDataLabel;
                        self.pendingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                        //
                        //                                       //hide right bar button item if there is no data
                        //                                       self.navigationItem.rightBarButtonItem = nil;
                        [_searchResults removeAllObjects];
                        [_pendingTableView reloadData];
                    }
                    [self stopActivity];
                    return;
                    
                });
            }
            
        }];
        
        /*******************************************************************************/
        
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    _declineBtn.enabled = YES;
    _downloadBtn.enabled = YES;
    _shareBtn.enabled = YES;
    self.navigationItem.title = @"My Signatures";
    self.title =  @"My Signatures";
    [self startActivity:@"Refreshing"];
    _searchResults = [[NSMutableArray alloc]init];
    
    searchSting = @"";
    _currentPage = 1;
    [self makeServieCallWithPageNumaber:_currentPage :searchSting];
    
    [_pendingTableView reloadData];
    //[self stopActivity];
    //[self isAdminAccess];
    //    /*************************Web Service*******************************/
    
    //Network Check
    if (![self connected])
    {
        if(hasPresentedAlert == false){
            
            // not connected
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            hasPresentedAlert = true;
        }
    }
    else{
        //
        //
        //        //[self startActivity:@"Loading..."];
        //        NSString *requestURL = [NSString stringWithFormat:@"%@GetProfileDetails",kMyProfile];
        //
        //        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        //            if(status)
        //            {
        //                dispatch_async(dispatch_get_main_queue(),
        //                               ^{
        //
        //
        //                                   _profileArray = [responseValue valueForKey:@"Response"];
        //
        ////                                                                          NSString *name = [NSString stringWithFormat:@"%@",[_profileArray valueForKey:@"FullName"]];
        ////                                                                          [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Name"];
        ////                                                                          [[NSUserDefaults standardUserDefaults] synchronize];
        ////                                                                          //
        ////
        //                                                                          //Saving Email
        //                                                                          NSString *email = [NSString stringWithFormat:@"%@",[_profileArray valueForKey:@"Email_Id"]];
        //                                                                          [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"Email Save"];
        //                                                                          [[NSUserDefaults standardUserDefaults] synchronize];
        //
        //                                   [self stopActivity];
        //                               });
        //            }
        //            else
        //            {
        //                [self stopActivity];
        //
        //                    UIAlertController * alert = [UIAlertController
        //                                                 alertControllerWithTitle:nil
        //                                                 message:@"Your emsigner account is no longer active. Contact your administrator"
        //                                                 preferredStyle:UIAlertControllerStyleAlert];
        //
        //                    //Add Buttons
        //
        //                    UIAlertAction* yesButton = [UIAlertAction
        //                                                actionWithTitle:@"Ok"
        //                                                style:UIAlertActionStyleDefault
        //                                                handler:^(UIAlertAction * action) {
        //                                                    //Handle your yes please button action here
        //                                                    //Logout
        //                                                    AppDelegate *theDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        //                                                    theDelegate.isLoggedIn = NO;
        //                                                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:theDelegate.isLoggedIn] forKey:@"isLogin"];
        //                                                    [NSUserDefaults resetStandardUserDefaults];
        //                                                    [NSUserDefaults standardUserDefaults];
        //                                                    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        //                                                    ViewController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ViewController"];
        //                                                    //[self.navigationController pushViewController:objTrackOrderVC animated:YES];
        //                                                    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
        //                                                }];
        //                    [alert addAction:yesButton];
        //                    [self presentViewController:alert animated:YES completion:nil];
        //                    return;
        //                }
        //
        //
        //        }];
        //
    }
    
}



-(void)refresh:(UIRefreshControl *)refreshControl
{
    
    //Network Check
    if (![self connected])
    {
        if(hasPresentedAlert == false){
            
            // not connected
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            hasPresentedAlert = true;
        }
    }
    else
    {
        [self startActivity:@"Loading..."];
        NSString *requestURL = [NSString stringWithFormat:@"%@UserProfileDetails",kMyProfile];
        
        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
            
            // if(status)
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                
            {
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                    
                    _profileArray = [responseValue valueForKey:@"Response"];
                    
                    //Saving WorkflowID
                    NSString *name = [NSString stringWithFormat:@"%@",[_profileArray valueForKey:@"FullName"]];
                    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Name"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    //
                    //Saving Aadhaar Number
                    NSString *aadhaarNumber = [NSString stringWithFormat:@"%@",[_profileArray valueForKey:@"AadharNumber"]];
                    [[NSUserDefaults standardUserDefaults] setObject:aadhaarNumber forKey:@"SavedAadhaarNumber"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    //
                    
                });
            }
            else{
                
                [self stopActivity];
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:nil
                                             message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0]
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                //Add Buttons
                
                UIAlertAction* yesButton = [UIAlertAction
                                            actionWithTitle:@"Ok"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                    //Handle your yes please button action here
                    //Logout
                    AppDelegate *theDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    theDelegate.isLoggedIn = NO;
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:theDelegate.isLoggedIn] forKey:@"isLogin"];
                    [NSUserDefaults resetStandardUserDefaults];
                    [NSUserDefaults standardUserDefaults];
                    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    ViewController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ViewController"];
                    
                    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                }];
                
                
                
                [alert addAction:yesButton];
                
                
                [self presentViewController:alert animated:YES completion:nil];
                
                
                
                return;
            }
            
        }];
        [self stopActivity];
        /****************************************************************/
        
    }
    
    
    //Network Check
    if (![self connected])
    {
        if(hasPresentedAlert == false){
            
            // not connected
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            hasPresentedAlert = true;
        }
    } else
    {
        
        refreshControl.attributedTitle = [dateCategoryString refreshForDate];
        
        // [self makeServieCallWithPageNumaber:1];
        [self makeServieCallWithPageNumaber:0 :searchSting];
        [self.pendingTableView reloadData];
        [refreshControl endRefreshing];
        /*******************************************************************************/
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self pendingToolBar];
}

//Network Connection Checks
- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return !(networkStatus == NotReachable);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//implementation of delegate method

- (void) showImage: (UIImage*) signature {
    self.signatureImageView.image = signature;
    self.signatureImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.signatureImageView.layer.borderColor = [UIColor yellowColor].CGColor;
    self.signatureImageView.layer.borderWidth = 2.0f;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    NSInteger numOfSections = 0;
    if ([self.searchResults count] > 0)
    {
        self.pendingTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        numOfSections = 1;
        self.pendingTableView.backgroundView = nil;
    }
    else
    {
        //        UILabel *noDataLabel         = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.pendingTableView.bounds.size.width, self.pendingTableView.bounds.size.height)];
        //        noDataLabel.text             = @"No documents available";
        //        noDataLabel.textColor        = [UIColor grayColor];
        //        noDataLabel.textAlignment    = NSTextAlignmentCenter;
        //        self.pendingTableView.backgroundView = noDataLabel;
        //        self.pendingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        //        [self stopActivity];
        //        //hide right bar button item if there is no data
        //        self.navigationItem.rightBarButtonItem = nil;
    }
    
    return numOfSections;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    PendingVCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PendingVCTableViewCell" forIndexPath:indexPath];
    
    
    _workflowId = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
    cell.documentName.text = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
    
    cell.ownerName.text = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"Name"];
    
    cell.pdfImage.translatesAutoresizingMaskIntoConstraints = YES;
    cell.pdfImage.frame = CGRectMake(0, 0, 0, 0);
    cell.documentName.translatesAutoresizingMaskIntoConstraints = YES;
    
    CGRect frame = cell.documentName.frame;
    frame.origin.x=  cell.pdfImage.frame.origin.x+8;//pass the X cordinate
    cell.documentName.frame= frame;
    
    long numberOfAttachmentString = [[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"NoofAttachment"]intValue];
    if (numberOfAttachmentString == 0) {
        cell.attachmentsImage.image = [UIImage imageNamed:@""];
    }
    else {
        cell.attachmentsImage.image = [UIImage imageNamed:@"attachment-1x"];
    }
    
    
    //hide images for workflows and reviewer
    //|| [[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 4//
    if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 2  || [[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 5 )
    {
        cell.docInfoBtn.hidden = YES;
        
    }
    else{
        cell.docInfoBtn.hidden = NO;
        
    }
    
    
    
    
    NSArray* date= [[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"UploadTime"] componentsSeparatedByString: @" "];
    //    NSDate* firstBit = [date objectAtIndex: 0];
    //    NSDate *secondBit = [date objectAtIndex:1];
    
    NSString *dateFromArray = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"UploadTime"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"%@",timeStamp);
    //asdnsajdnsajdn
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    NSDate *dates = [formatter dateFromString:dateFromArray];
    
    dateCategoryString = [NSString string];
    cell.dateLable.text = [dateCategoryString transformedValue:dates];
    cell.timeLabel.text = [date objectAtIndex:1];
    
    //cell.timeBtn.text = [NSString stringWithFormat:@"%@", secondBit];
    
    //InfoButton
    cell.docInfoBtn.tag = indexPath.row;
    [cell.docInfoBtn addTarget:self action:@selector(verticalDotsBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath;
    //Saving WorkflowID
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"pdfpath"];
    
    NSUserDefaults * userDefaultssaveSignature = [NSUserDefaults standardUserDefaults];
    [userDefaultssaveSignature removeObjectForKey:@"saveSignature"];
    
    NSString *pendingWorkflowID =[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
    [[NSUserDefaults standardUserDefaults] setObject:pendingWorkflowID forKey:@"PendingWorkflowID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Saving Document Name
    NSString *pendingdocumentName =[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
    [[NSUserDefaults standardUserDefaults] setObject:pendingdocumentName forKey:@"PendingDisplayName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    int statusCheckForParallel =[[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]intValue];
    [[NSUserDefaults standardUserDefaults] setInteger:statusCheckForParallel forKey:@"statusCheckForParallel"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // _documentName= [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];;
    //Network Check
    if (![self connected])
    {
        if(hasPresentedAlert == false){
            
            // not connected
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            hasPresentedAlert = true;
        }
    } else
    {
        
        /*************************Web Service*******************************/
        
        [self startActivity:@"Loading..."];
        
        //workflow type 2
        if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 2)
        {
            [self alertForFlexiforms];
            return;
        }
        
        //workflow type 4
        
        if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 4 ) {
            //Call API
            [self GetBulkDocuments:[NSString stringWithFormat:@"%ld",(long)[[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"LotId"]integerValue]] workflowType:[NSString stringWithFormat:@"%ld",(long)[[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue]]];
            return;
        }
        
        //workflow type 5
        if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 5)
        {
            [self alertForCollaborative];
            return;
        }
    
        
        mstrXMLString = [[NSMutableString alloc] init];
        
        NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@&workflowType=%@",kOpenPDFImage,[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"],[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]];
        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
            
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
            {
                int issucess = [[responseValue valueForKey:@"IsSuccess"]intValue];
                
                if (issucess != 0) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        _checkNullArray = [responseValue valueForKey:@"Response"];
                        
                        if (_checkNullArray == (id)[NSNull null])
                        {
                            UIAlertController * alert = [UIAlertController
                                                         alertControllerWithTitle:@""
                                                         message:@"This file has been corrupted."
                                                         preferredStyle:UIAlertControllerStyleAlert];
                            
                            //Add Buttons
                            
                            UIAlertAction* yesButton = [UIAlertAction
                                                        actionWithTitle:@"Ok"
                                                        style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                //Handle your yes please button action here
                                
                            }];
                            
                            //Add your buttons to alert controller
                            
                            [alert addAction:yesButton];
                            
                            [self presentViewController:alert animated:YES completion:nil];
                            [self stopActivity];
                            
                            return;
                        }
                        
                        arr =  [_checkNullArray valueForKey:@"Signatory"];
                        
                        NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
                        NSData * data = [NSKeyedArchiver archivedDataWithRootObject:arr requiringSecureCoding:NO error:nil];
                        [prefs setObject:data forKey:@"Signatory"];
                        
                        if (arr.count > 0) {
                            NSString * ischeck = @"ischeck";
                            [mstrXMLString appendString:@"Signed By:"];
                            
                            for (int i = 0; arr.count>i; i++) {
                                NSDictionary * dict = arr[i];
                                
                                //status id for parallel signing
                                if ([dict[@"StatusID"]intValue] == 7) {
                                    // statusId = 1;
                                }
                                
                                //displaying signatories on top .
                                if ([dict[@"StatusID"]intValue] == 13) {
                                    NSString* emailid = dict[@"EmailID"];
                                    NSString* name = dict[@"Name"];
                                    NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                                    
                                    if ([mstrXMLString containsString:[NSString stringWithFormat:@"%@",totalstring]]) {
                                        
                                    }
                                    else
                                    {
                                        [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
                                    }
                                    
                                    //[mstrXMLString appendString:[NSString stringWithFormat:@"Signed By: %@",totalstring]];
                                    ischeck = @"Signatory";
                                    NSLog(@"%@",mstrXMLString);
                                }
                            }
                            if ([ischeck  isEqual: @"ischeck"])
                            {
                                NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
                                mstrXMLString = [NSMutableString string];
                                
                                [mstrXMLString appendString:@"Originated By:"];
                                for (int i = 0; arr1.count > i; i++) {
                                    NSDictionary * dict = arr1[i];
                                    
                                    NSString* emailid = dict[@"EmailID"];
                                    NSString* name = dict[@"Name"];
                                    NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                                    [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
                                    NSLog(@"%@",mstrXMLString);
                                }
                            }
                            //}
                        }
                        
                        else
                        {
                            NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
                            [mstrXMLString appendString:@"Originated By:"];
                            
                            for (int i = 0; arr1.count > i; i++) {
                                NSDictionary * dict = arr1[i];
                                
                                NSString* emailid = dict[@"EmailID"];
                                NSString* name = dict[@"Name"];
                                NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                                [mstrXMLString appendString:[NSString stringWithFormat:@"%@",totalstring]];
                                NSLog(@"%@",mstrXMLString);
                            }
                        }
                        
                        coordinatesArray = [[NSMutableArray alloc]init];
                        //Checking for signatorys and multiple PDF
                        for (int i = 0; i<arr.count; i++) {
                            
                            if ([[arr[i]valueForKey:@"EmailID"] caseInsensitiveCompare:[[NSUserDefaults standardUserDefaults]valueForKey:@"Email"]] == NSOrderedSame)
                            {
                                // ([[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"IsOpened"]intValue]== 1)
                                if (([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)) {
                                    isdelegate = false;
                                    statusId = 0;
                                }
                                else if ([[arr[i]valueForKey:@"StatusID"]integerValue] == 7){
                                    isdelegate = true;
                                    statusId = 1;
                                }
                                if ((([[arr[i]valueForKey:@"StatusID"]integerValue] == 7)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 8))) {
                                    
                                    if ([[arr[i]valueForKey:@"DocumentId"]integerValue]== [[[_checkNullArray valueForKey:@"DocumentId"]objectAtIndex:0]integerValue]) {
                                        [coordinatesArray addObject:arr[i]];
                                    }
                                }
                            }
                        }
                        
                        statusForPlaceholders = [coordinatesArray valueForKey:@"StatusID"];
                        
                        //FileDataBytes
                        _pdfImageArray=[[responseValue valueForKey:@"Response"] valueForKey:@"Document"];
                        
                        if (_pdfImageArray != (id)[NSNull null])
                        {
                            NSUserDefaults *statusIdForMultiplePdf = [NSUserDefaults standardUserDefaults];
                            [statusIdForMultiplePdf setInteger:(long)statusId forKey:@"statusIdForMultiplePdf"];
                            [statusIdForMultiplePdf synchronize];
                            
                            if ([[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
                                
                                NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                                
                                self.pdfDocument = [[PDFDocument alloc] initWithData:data];
                                
                                
                                //workflow type  == 3
                                
                                if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 3)
                                {
                                    [self parallelSigning:indexPath.row];
                                    
                                }
                                
                                NSString *checkPassword = [[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"];
                                [[NSUserDefaults standardUserDefaults] setObject:checkPassword forKey:@"checkPassword"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                                NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
                                NSString *path = [documentsDirectory stringByAppendingPathComponent:[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"]];
                                [data writeToFile:path atomically:YES];
                                
                                
                                [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"pathForDoc"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                NSString *displayName = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
                                [[NSUserDefaults standardUserDefaults] setObject:displayName forKey:@"displayName"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                NSString *docCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                                [[NSUserDefaults standardUserDefaults] setObject:docCount forKey:@"docCount"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                NSString *attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                                [[NSUserDefaults standardUserDefaults] setObject:attachmentCount forKey:@"attachmentCount"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                NSString *workflowId = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
                                [[NSUserDefaults standardUserDefaults] setObject:workflowId forKey:@"workflowId"];
                                [[NSUserDefaults standardUserDefaults] synchronize];
                                
                                
                                
                                if ([self.pdfDocument isLocked]) {
                                    UIAlertView *passwordAlertView = [[UIAlertView alloc]initWithTitle: @"Password Protected"
                                                                                               message:  [NSString stringWithFormat: @"%@ %@", path.lastPathComponent, @"is password protected"]
                                                                                              delegate: self
                                                                                     cancelButtonTitle: @"Cancel"
                                                                                     otherButtonTitles: @"Done", nil];
                                    passwordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
                                    [passwordAlertView show];
                                    return;
                                    
                                }
                                
                                [self stopActivity];
                                
                            }
                            else
                            {
                                
                                NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                                // from your converted Base64 string
                                NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
                                NSString *path = [documentsDirectory stringByAppendingPathComponent:[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"]];
                                [data writeToFile:path atomically:YES];
                                
                                CFUUIDRef uuid = CFUUIDCreate(NULL);
                                CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                                CFRelease(uuid);
                                
                                UIImage *image = [UIImage imageNamed:@"signer.png"];
                                
                                if (coordinatesArray.count != 0) {
                                    
                                }
                                //[self stopActivity];
                                // return;
                            }
                            
                            //workflow type  == 3
                            //parallel signing
                            if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 3)
                            {
                                [self parallelSigningNoPassword:indexPath.row];
                                
                            }
                            
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"data"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSData * data = [NSKeyedArchiver archivedDataWithRootObject:coordinatesArray requiringSecureCoding:NO error:nil];
                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"coordinatesArray"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            
                            
                            //                            NSData * arrdata = [NSKeyedArchiver archivedDataWithRootObject:arr requiringSecureCoding:NO error:nil];
                            //                            [[NSUserDefaults standardUserDefaults] setObject:arrdata forKey:@"arr"];
                            //                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            if (isdelegate == true)
                            {
                                PendingListVC *temp = [[PendingListVC alloc]init];
                                
                                temp.pdfImagedetail = _pdfImageArray;
                                temp.workFlowID = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
                                temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                                temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                                temp.documentID = [[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
                                temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
                                temp.myTitle = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
                                temp.signatoryString = mstrXMLString;
                                temp.statusId = statusId;
                                temp.signatoryHolderArray = arr;
                                temp.placeholderArray = coordinatesArray;
                                temp.workFlowType = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"];
                                temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
                                temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
                                temp.isDocStore = true;
                                [self.navigationController pushViewController:temp animated:YES];
                                [self stopActivity];
                            }
                            else if(isdelegate == false){
                                PendingListVC *temp = [[PendingListVC alloc]init];
                                
                                temp.pdfImagedetail = _pdfImageArray;
                                temp.workFlowID = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
                                temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                                temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                                temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
                                temp.documentID = [[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
                                
                                temp.myTitle = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
                                temp.signatoryString = mstrXMLString;
                                temp.statusId = statusId;
                                temp.signatoryHolderArray = arr;
                                temp.placeholderArray = coordinatesArray;
                                temp.workFlowType = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"];
                                temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
                                temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
                                temp.isDocStore = true;
                                [self.navigationController pushViewController:temp animated:YES];
                                [self stopActivity];
                            }
                            
                        }
                        else{
                            
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"This file was corrupted. Please contact eMudhra for more details." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                            [alert show];
                            [self stopActivity];
                        }
                    });
                    
                }
                else{
                    //Alert at the time of no server connection
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                        [self stopActivity];
                        
                    });
                    
                }
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"The API request is invalid or improperly formed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                    [self stopActivity];
                });
            }
        }];
        
    }
    
}
-(void)GetBulkDocuments:(NSString *)lotId workflowType:(NSString *)workflowType  {
    //BulkDocVC
    
    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    BulkDocVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"BulkDocVC"];
    objTrackOrderVC.lotId = lotId;
    objTrackOrderVC.type = @"Me";
    objTrackOrderVC.workflowType = workflowType;
    [self.navigationController pushViewController:objTrackOrderVC animated:YES];
}

//-(void)callForPushNotifications{
//
//        /*************************Web Service*******************************/
//
//        [self startActivity:@"Loading..."];
//
//        //workflow type 2
//        //flexiforms
//        //workflow type 4
//
//       // if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 4)
//        //{
//          //  [self alertForBulkDocuments];
//           // return;
//        //}
//
//        //workflow type 5
//        //if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 5)
//        //{
//          //  [self alertForCollaborative];
//            //return;
//        //}
//        //
//
//        //reviewer documents
////        if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"SignatureType"]integerValue] == 2)
////        {
////            [self alertForReview];
////            return;
////        }
//
//        mstrXMLString = [[NSMutableString alloc] init];
//
//
//       // NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@&workflowType=%@",kOpenPDFImage,[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"],[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]];
//        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
//
//            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
//            {
//                int issucess = [[responseValue valueForKey:@"IsSuccess"]intValue];
//
//                if (issucess != 0) {
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    _checkNullArray = [responseValue valueForKey:@"Response"];
//
//                    if (_checkNullArray == (id)[NSNull null])
//                    {
//                        UIAlertController * alert = [UIAlertController
//                                                     alertControllerWithTitle:@""
//                                                     message:@"This file has been corrupted."
//                                                     preferredStyle:UIAlertControllerStyleAlert];
//
//                        //Add Buttons
//
//                        UIAlertAction* yesButton = [UIAlertAction
//                                                    actionWithTitle:@"Ok"
//                                                    style:UIAlertActionStyleDefault
//                                                    handler:^(UIAlertAction * action) {
//                                                        //Handle your yes please button action here
//
//                                                    }];
//
//                        //Add your buttons to alert controller
//
//                        [alert addAction:yesButton];
//
//                        [self presentViewController:alert animated:YES completion:nil];
//                        [self stopActivity];
//
//                        return;
//                    }
//
//                    arr =  [_checkNullArray valueForKey:@"Signatory"];
//
//                    NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
//                    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:arr requiringSecureCoding:NO error:nil];
//                    [prefs setObject:data forKey:@"Signatory"];
//
//                    if (arr.count > 0) {
//                        NSString * ischeck = @"ischeck";
//                        [mstrXMLString appendString:@"Signed By:"];
//
//                        for (int i = 0; arr.count>i; i++) {
//                            NSDictionary * dict = arr[i];
//
//                            //status id for parallel signing
//                            if ([dict[@"StatusID"]intValue] == 7) {
//                               // statusId = 1;
//                            }
//
//                            //displaying signatories on top .
//                            if ([dict[@"StatusID"]intValue] == 13) {
//                                NSString* emailid = dict[@"EmailID"];
//                                NSString* name = dict[@"Name"];
//                                NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
//
//                                if ([mstrXMLString containsString:[NSString stringWithFormat:@"%@",totalstring]]) {
//
//                                }
//                                else
//                                {
//                                    [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
//                                }
//
//                                //[mstrXMLString appendString:[NSString stringWithFormat:@"Signed By: %@",totalstring]];
//                                ischeck = @"Signatory";
//                                NSLog(@"%@",mstrXMLString);
//                            }
//                        }
//                        if ([ischeck  isEqual: @"ischeck"])
//                        {
//                            NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
//                            mstrXMLString = [NSMutableString string];
//
//                            [mstrXMLString appendString:@"Originated By:"];
//                            for (int i = 0; arr1.count > i; i++) {
//                                NSDictionary * dict = arr1[i];
//
//                                NSString* emailid = dict[@"EmailID"];
//                                NSString* name = dict[@"Name"];
//                                NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
//                                [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
//                                NSLog(@"%@",mstrXMLString);
//                            }
//                        }
//                        //}
//                    }
//
//                    else
//                    {
//                        NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
//                        [mstrXMLString appendString:@"Originated By:"];
//
//                        for (int i = 0; arr1.count > i; i++) {
//                            NSDictionary * dict = arr1[i];
//
//                            NSString* emailid = dict[@"EmailID"];
//                            NSString* name = dict[@"Name"];
//                            NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
//                            [mstrXMLString appendString:[NSString stringWithFormat:@"%@",totalstring]];
//                            NSLog(@"%@",mstrXMLString);
//                        }
//                    }
//
//                    coordinatesArray = [[NSMutableArray alloc]init];
//                    //Checking for signatorys and multiple PDF
//                    for (int i = 0; i<arr.count; i++) {
//
//                        if ([[arr[i]valueForKey:@"EmailID"] caseInsensitiveCompare:[[NSUserDefaults standardUserDefaults]valueForKey:@"Email"]] == NSOrderedSame)
//                        {
//                            // ([[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"IsOpened"]intValue]== 1)
//                            if (([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)) {
//                                isdelegate = false;
//                                statusId = 0;
//                            }
//                            else if ([[arr[i]valueForKey:@"StatusID"]integerValue] == 7){
//                                isdelegate = true;
//                                statusId = 1;
//                            }
//                            if ((([[arr[i]valueForKey:@"StatusID"]integerValue] == 7)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 8))) {
//
//                                if ([[arr[i]valueForKey:@"DocumentId"]integerValue]== [[[_checkNullArray valueForKey:@"DocumentId"]objectAtIndex:0]integerValue]) {
//                                    [coordinatesArray addObject:arr[i]];
//                                }
//                            }
//                        }
//                    }
//
//                    statusForPlaceholders = [coordinatesArray valueForKey:@"StatusID"];
//
//                    //FileDataBytes
//                    _pdfImageArray=[[responseValue valueForKey:@"Response"] valueForKey:@"Document"];
//
//                    if (_pdfImageArray != (id)[NSNull null])
//                    {
//                        NSUserDefaults *statusIdForMultiplePdf = [NSUserDefaults standardUserDefaults];
//                        [statusIdForMultiplePdf setInteger:(long)statusId forKey:@"statusIdForMultiplePdf"];
//                        [statusIdForMultiplePdf synchronize];
//
//                        if ([[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
//
//                            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
//
//                            self.pdfDocument = [[PDFDocument alloc] initWithData:data];
//
//
//                            //workflow type  == 3
//
//                        //    if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 3)
//                          //  {
//                            //    [self parallelSigning:indexPath.row];
//
//                           // }
//
//                            NSString *checkPassword = [[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"];
//                            [[NSUserDefaults standardUserDefaults] setObject:checkPassword forKey:@"checkPassword"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
//                            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//                            NSString *path = [documentsDirectory stringByAppendingPathComponent:[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"]];
//                            [data writeToFile:path atomically:YES];
//
//
//                            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"pathForDoc"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            NSString *displayName = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
//                            [[NSUserDefaults standardUserDefaults] setObject:displayName forKey:@"displayName"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            NSString *docCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
//                            [[NSUserDefaults standardUserDefaults] setObject:docCount forKey:@"docCount"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            NSString *attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
//                            [[NSUserDefaults standardUserDefaults] setObject:attachmentCount forKey:@"attachmentCount"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            NSString *workflowId = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
//                            [[NSUserDefaults standardUserDefaults] setObject:workflowId forKey:@"workflowId"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//
//
//                            if ([self.pdfDocument isLocked]) {
//                                UIAlertView *passwordAlertView = [[UIAlertView alloc]initWithTitle: @"Password Protected"
//                                                                                           message:  [NSString stringWithFormat: @"%@ %@", path.lastPathComponent, @"is password protected"]
//                                                                                          delegate: self
//                                                                                 cancelButtonTitle: @"Cancel"
//                                                                                 otherButtonTitles: @"Done", nil];
//                                passwordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
//                                [passwordAlertView show];
//                                return;
//
//                            }
//
//                            [self stopActivity];
//
//                        }
//                        else
//                        {
//
//                            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
//                            // from your converted Base64 string
//                            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//                            NSString *path = [documentsDirectory stringByAppendingPathComponent:[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"]];
//                            [data writeToFile:path atomically:YES];
//
//                            CFUUIDRef uuid = CFUUIDCreate(NULL);
//                            CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
//                            CFRelease(uuid);
//
//                            UIImage *image = [UIImage imageNamed:@"signer.png"];
//
//                            if (coordinatesArray.count != 0) {
//
//                            }
//                                //[self stopActivity];
//                               // return;
//                            }
//
//                            //workflow type  == 3
//                            //parallel signing
//                            if ([[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]integerValue] == 3)
//                            {
//                                [self parallelSigningNoPassword:indexPath.row];
//
//                            }
//
//                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"data"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            NSData * data = [NSKeyedArchiver archivedDataWithRootObject:coordinatesArray requiringSecureCoding:NO error:nil];
//                            [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"coordinatesArray"];
//                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//
//
////                            NSData * arrdata = [NSKeyedArchiver archivedDataWithRootObject:arr requiringSecureCoding:NO error:nil];
////                            [[NSUserDefaults standardUserDefaults] setObject:arrdata forKey:@"arr"];
////                            [[NSUserDefaults standardUserDefaults] synchronize];
//
//                            if (isdelegate == true)
//                            {
//                                PendingListVC *temp = [[PendingListVC alloc]init];
//
//                                temp.pdfImagedetail = _pdfImageArray;
//                                temp.workFlowID = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
//                                temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
//                                temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
//                                temp.documentID = [[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
//                                temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
//                                temp.myTitle = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
//                                temp.signatoryString = mstrXMLString;
//                                temp.statusId = statusId;
//                                temp.signatoryHolderArray = arr;
//                                temp.placeholderArray = coordinatesArray;
//                                temp.workFlowType = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"];
//                                temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
//                                temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
//
//                                [self.navigationController pushViewController:temp animated:YES];
//                                [self stopActivity];
//                            }
//                            else if(isdelegate == false){
//                                PendingListVC *temp = [[PendingListVC alloc]init];
//
//                                temp.pdfImagedetail = _pdfImageArray;
//                                temp.workFlowID = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
//                                temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
//                                temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
//                                temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
//                                temp.documentID = [[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
//
//                                temp.myTitle = [[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
//                                temp.signatoryString = mstrXMLString;
//                                temp.statusId = statusId;
//                                temp.signatoryHolderArray = arr;
//                                temp.placeholderArray = coordinatesArray;
//                                temp.workFlowType = [[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"];
//                                temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
//                                temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
//
//                                [self.navigationController pushViewController:temp animated:YES];
//                                [self stopActivity];
//                            }
//
//                        }
//                    else{
//
//                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"This file was corrupted. Please contact eMudhra for more details." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//                        [alert show];
//                        [self stopActivity];
//                    }
//                });
//
//            }
//            else{
//                //Alert at the time of no server connection
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//                    [alert show];
//                    [self stopActivity];
//
//                });
//
//                }
//            }
//            else{
//                   dispatch_async(dispatch_get_main_queue(), ^{
//                       UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"The API request is invalid or improperly formed." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//                        [alert show];
//                        [self stopActivity];
//                        });
//            }
//        }];
//
//    }

/******************************Swipe Edit*********************************************/
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
//Saving WorkflowID
//    NSString *pendingWorkflowID =[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"];
//    [[NSUserDefaults standardUserDefaults] setObject:pendingWorkflowID forKey:@"PendingWorkflowID"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    //
//
//    //Saving Document Name
//    NSString *pendingdocumentName =[[_searchResults objectAtIndex:indexPath.row] objectForKey:@"DisplayName"];
//    [[NSUserDefaults standardUserDefaults] setObject:pendingdocumentName forKey:@"PendingDisplayName"];
//    [[NSUserDefaults standardUserDefaults] synchronize];

//   return YES;

//}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    //Nothing gets called here if you invoke `tableView:editActionsForRowAtIndexPath:` according to Apple docs so just leave this method blank
//}
//- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//
//
//    /*************************Web Service*******************************/
//
//    NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@&workflowType=%@",kOpenPDFImage,[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkFlowId"],[[_searchResults objectAtIndex:indexPath.row] valueForKey:@"WorkflowType"]];
//    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
//
//
//        if(status)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                _pdfImageArraySwipe=responseValue;
//                //if ([[[_pdfImageArraySwipe valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
//
//                //}
//
//            });
//
//        }
//        else{
//            //Alert at the time of no server connection
//
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//            [alert show];
//            [self stopActivity];
//
//        }
//
//    }];
//
//    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"           " handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
//                                          {
//
//
////                                              if ([[[_pdfImageArraySwipe valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
////                                                  UIAlertController * alert = [UIAlertController
////                                                                               alertControllerWithTitle:@""
////                                                                               message:@"At present password protected documents are not supported"
////                                                                               preferredStyle:UIAlertControllerStyleAlert];
////
////                                                  //Add Buttons
////
////                                                  UIAlertAction* yesButton = [UIAlertAction
////                                                                              actionWithTitle:@"Ok"
////                                                                              style:UIAlertActionStyleDefault
////                                                                              handler:^(UIAlertAction * action) {
////                                                                                  //Handle your yes please button action here
////
////                                                                              }];
////
////                                                  //Add your buttons to alert controller
////
////                                                  [alert addAction:yesButton];
////
////                                                  [self presentViewController:alert animated:YES completion:nil];
////                                                  _pendingToolBar.hidden = NO;
////                                              }
////                                              else{
//
//                                                  [self showModal:UIModalPresentationFullScreen style:[MPBDefaultStyleSignatureViewController alloc]];
//
//
////                                                  UIActionSheet *actionSheet102 = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"eSign",@"eSignature", nil];
////                                                  actionSheet102.tag = 102;
////                                                  [actionSheet102 showInView:self.view];
//
//                                              //}
//
//
//    }];
//    _pendingToolBar.hidden = YES;
//    UITableViewCell *commentCell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
//
//    CGFloat height = commentCell.frame.size.height;
//
//    UIImage *backgroundImage = [self deleteImageForHeight:height];
//
//    deleteAction.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
//
//    return @[deleteAction];
//}

- (UIImage*)deleteImageForHeight:(CGFloat)height{
    
    CGRect frame = CGRectMake(0, 0, 62, height);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(62, height), NO, [UIScreen mainScreen].scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.0/255.0 green:96.0/255.0 blue:192.0/255.0 alpha:1.0].CGColor);
    CGContextFillRect(context, frame);
    
    UIImage *image = [UIImage imageNamed:@"slide-sign-1x"];
    
    [image drawInRect:CGRectMake(frame.size.width/2.0, frame.size.height/2.0 - 10, 18, 20)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(nullable NSIndexPath *)indexPath
{
    _declineBtn.enabled = YES;
    _downloadBtn.enabled = YES;
    _shareBtn.enabled = YES;
    _pendingToolBar.hidden = YES;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //commented for pagination
    // Check scrolled percentage
    //    CGFloat yOffset = tableView.contentOffset.y;
    //    CGFloat height = tableView.contentSize.height - tableView.frame.size.height;
    //    CGFloat scrolledPercentage = yOffset / height;
    //
    //    // Check if all the conditions are met to allow loading the next page
    //    if (scrolledPercentage > .6f){
    //        // This is the bottom of the table view, load more data here.
    //        //[self makeServieCallWithPageNumaber:currentPage];
    //        if (_totalRow > self.searchResults.count) {
    //            _currentPage+= 10;
    //            [self makeServieCallWithPageNumaber:_currentPage];
    //            [self stopActivity];
    //        }
    //        else{
    //           // _currentPage = nil;
    //        }
    //
    //    }
    
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat yOffset = _pendingTableView.contentOffset.y;
    CGFloat height = _pendingTableView.contentSize.height - _pendingTableView.bounds.size.height;
    if(yOffset >= height)
    {
        if(isPageRefreshing==NO){
            isPageRefreshing=YES;
            _currentPage+=1;
            // [self makeServieCallWithPageNumaber:_currentPage];
            [self makeServieCallWithPageNumaber:_currentPage :searchSting];
            //[self callPageNumbers:_currentPage];
        }
    }
    
}



/**************************************************************************************/

-(void)verticalDotsBtnClicked:(UIButton*)sender
{
    NSIndexPath* indexpath = [self.pendingTableView indexPathForSelectedRow];
    //[self showModal:UIModalPresentationFullScreen style:[MPBDefaultStyleSignatureViewController alloc]];
    
    UIAlertController * view=   [[UIAlertController
                                  alloc]init];
    UIAlertAction* Info = [UIAlertAction
                           actionWithTitle:@"View Document Information"
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
        //Do some thing here
        
        [self getDocumentInfo:[[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"]];
        
    }];
    
    UIAlertAction* Decline = [UIAlertAction
                              actionWithTitle:@"Decline Document"
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeclineVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DeclineVC"];
        self.definesPresentationContext = YES; //self is presenting view controller
        objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        objTrackOrderVC.workflowID = [[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];;
        [self.navigationController presentViewController:objTrackOrderVC animated:YES completion:nil];
    }];
    
    UIAlertAction* Doclog = [UIAlertAction
                             actionWithTitle:@"Document log"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DocumentLogVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DocumentLogVC"];
        
        objTrackOrderVC.workflowID = [[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];;
        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
    }];
    UIAlertAction* Comments = [UIAlertAction
                               actionWithTitle:@"Comments"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        CommentsController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"CommentsController"];
        objTrackOrderVC.documentID = [[_searchResults objectAtIndex:sender.tag] valueForKey:@"DocumentId"];
        objTrackOrderVC.workflowID = [[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];
        
        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
    }];
    UIAlertAction* Download = [UIAlertAction
                               actionWithTitle:@"Download Document"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
        
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Download"
                                                                      message:@"Do you want to download document"
                                                               preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Yes"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
            /** What we write here???????? **/
            NSLog(@"you pressed Yes, please button");
            
            
            [self startActivity:@"Loading..."];
            NSString *requestURL = [NSString stringWithFormat:@"%@DownloadWorkflowDocuments?WorkFlowId=%@",kDownloadPdf,[[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"]];
            [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
                
                //  if(status)
                if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                    
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        _pdfImageArray=[responseValue valueForKey:@"Response"];
                        if (_pdfImageArray != (id)[NSNull null])
                        {
                            [_addFile removeAllObjects];
                            for(int i=0; i<[_pdfImageArray count];i++)
                            {
                                
                                _pdfFileName = [[_pdfImageArray objectAtIndex:i] objectForKey:@"DocumentName"];
                                _pdfFiledata = [[_pdfImageArray objectAtIndex:i] objectForKey:@"Base64FileData"];
                                
                                NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfFiledata options:0];
                                NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
                                CFUUIDRef uuid = CFUUIDCreate(NULL);
                                CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                                CFRelease(uuid);
                                NSString *uniqueFileName = [NSString stringWithFormat:@"%@%@%@%@",_pdfFileName,@"                                                 ",(__bridge NSString *)uuidString, _pdfFileName];
                                
                                
                                NSString *path = [documentsDirectory stringByAppendingPathComponent:uniqueFileName];
                                [_addFile addObject:path];
                                
                                [data writeToFile:path atomically:YES];
                                
                                
                                if (i==_pdfImageArray.count-1)
                                {
                                    [self stopActivity];
                                    QLPreviewController *previewController=[[QLPreviewController alloc]init];
                                    previewController.delegate=self;
                                    previewController.dataSource=self;
                                    [self presentViewController:previewController animated:YES completion:nil];
                                    [previewController.navigationItem setRightBarButtonItem:nil];
                                }
                                
                            }
                            
                        }
                        else{
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                            [alert show];
                        }
                        
                    });
                    
                }
                else{
                    [self stopActivity];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    });
                }
                
            }];
            
            // call method whatever u need
        }];
        
        UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
            /** What we write here???????? **/
            NSLog(@"you pressed No, thanks button");
            // call method whatever u need
        }];
        
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }];
    UIAlertAction* Share = [UIAlertAction
                            actionWithTitle:@"Share Document"
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
        NSString *pendingdocumentName =[[_searchResults objectAtIndex:sender.tag] valueForKey:@"DisplayName"];
        NSString* documentId = [[_searchResults objectAtIndex:sender.tag] valueForKey:@"DocumentId"];
        
        NSString *pendingWorkflowID =[[_searchResults objectAtIndex:sender.tag] valueForKey:@"WorkFlowId"];
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ShareVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ShareVC"];
        objTrackOrderVC.documentName = pendingdocumentName;
        objTrackOrderVC.documentID = documentId;
        objTrackOrderVC.workflowID = pendingWorkflowID;
        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
        
        
    }];
    
    UIAlertAction* BulkSign = [UIAlertAction
                               actionWithTitle:@"BulkSign"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
        
        [self showModals:UIModalPresentationFullScreen style:[MPBDefaultStyleSignatureViewController alloc] Lot:[[_searchResults objectAtIndex:sender.tag] valueForKey:@"LotId"]];
    }];
    UIAlertAction* BulkDocuments = [UIAlertAction
                                    actionWithTitle:@"BulkDownload"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
        
        
        
        UIAlertController * alert=[UIAlertController alertControllerWithTitle:@"Download"
                                                                      message:@"Do you want to download document"
                                                               preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Yes"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
            /** What we write here???????? **/
            NSLog(@"you pressed Yes, please button");
            
            
            [self startActivity:@"Loading..."];
            NSString *requestURL = [NSString stringWithFormat:@"%@BulkDownload?lotId=%@",kbulkDownload,[[_searchResults objectAtIndex:sender.tag] valueForKey:@"LotId"]];
            [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodPOST body:requestURL completionBlock:^(BOOL status, id responseValue) {
                
                //  if(status)
                if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                    
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self stopActivity];
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    });
                    
                } else{
                    [self stopActivity];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    });
                }
                
            }];
            
            // call method whatever u need
        }];
        
        UIAlertAction* noButton = [UIAlertAction actionWithTitle:@"No"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
                                   {
            /** What we write here???????? **/
            NSLog(@"you pressed No, thanks button");
            // call method whatever u need
        }];
        
        [alert addAction:yesButton];
        [alert addAction:noButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action)
                             {
        
    }];
    
    [Info setValue:[[UIImage imageNamed:@"information-outline-2.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Decline setValue:[[UIImage imageNamed:@"cancel.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Doclog setValue:[[UIImage imageNamed:@"stack-exchange.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Comments setValue:[[UIImage imageNamed:@"comments"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Download setValue:[[UIImage imageNamed:@"download.png"]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    
    [Share setValue:[[UIImage imageNamed:@"share-variant.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [Info setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Decline setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Doclog setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Comments setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Download setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [Share setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    view.view.tintColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
    
    
    [BulkDocuments setValue:[[UIImage imageNamed:@"download.png"]
                             imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [BulkSign setValue:[[UIImage imageNamed:@"signatories.png"]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
    [BulkDocuments setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    [BulkSign setValue:kCAAlignmentLeft forKey:@"titleTextAlignment"];
    //EMIOS1109
    if ([[[_searchResults objectAtIndex:sender.tag] valueForKey:@"LotId"]intValue] != 0){
        [view addAction:BulkSign];
        [view addAction:BulkDocuments];
    } else {
        [view addAction:Info];
        [view addAction:Decline];
        [view addAction:Doclog];
        [view addAction:Comments];
        [view addAction:Download];
        [view addAction:Share];
    }
    
    [view addAction:cancel];
    
    [self presentViewController:view animated:YES completion:nil];
    
}


-(NSString*) addSignature:(UIImage *) imgSignature onPDFData:(NSData *)pdfData withCoordinates:(NSMutableArray*)arr Count:(NSArray*)array {
    
    NSMutableData* outputPDFData = [[NSMutableData alloc] init];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)outputPDFData);
    
    long pnum = 0;
    CFMutableDictionaryRef attrDictionary = NULL;
    attrDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrDictionary, kCGPDFContextTitle, CFSTR("My Doc"));
    NSString *pass = [[NSUserDefaults standardUserDefaults] valueForKey:@"Password"];
    
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer, NULL, attrDictionary);
    CFRelease(dataConsumer);
    CFRelease(attrDictionary);
    CGRect pageRect;
    CGRect coordinatesRect;
    NSMutableArray * coordinatesArray;
    // Draw the old "pdfData" on pdfContext
    CFDataRef myPDFData = (__bridge CFDataRef) pdfData;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithProvider(provider);
    CGPDFDocumentUnlockWithPassword(pdf, [pass UTF8String]);
    CGDataProviderRelease(provider);
    long pageCount = CGPDFDocumentGetNumberOfPages(pdf);
    
    
    for (int k=1; k<=pageCount; k++) {
        coordinatesArray = [[NSMutableArray alloc]init];
        for (int i = 0; i<arr.count; i++) {
            
            
            if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"FIRST"]) {
                pnum = 1;
                // coordinatesRect = CGRectMake([[dict valueForKey:@"Left"]doubleValue], [[dict valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"LAST"]) {
                pnum = pageCount;
                // coordinatesRect = CGRectMake([[arr[k] valueForKey:@"Left"]doubleValue], [[arr[k] valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
                
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"EVEN PAGES"]) {
                if (k%2 == 0) {
                    pnum = k;
                    //                coordinatesRect = CGRectMake([[arr[k] valueForKey:@"Left"]doubleValue], [[arr[k] valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                    [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
                }
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"ODD PAGES"]) {
                if (k%2 != 0) {
                    pnum = k;
                    //                coordinatesRect = CGRectMake([[arr[k] valueForKey:@"Left"]doubleValue], [[arr[k] valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                    [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i]  valueForKey:@"Left"]doubleValue], [[arr[i]   valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
                }
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"ALL"]) {
                pnum = k;
                //            coordinatesRect = CGRectMake([[arr[k] valueForKey:@"Left"]doubleValue], [[arr[k] valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"SPECIFY"]) {
                NSArray* str = [[arr[i] valueForKey:@"PageNo"]componentsSeparatedByString:@","];
                for (int j=0; j<str.count; j++) {
                    
                    if (k == [str[j]intValue])
                    {
                        pnum = k;
                        //                    coordinatesRect = CGRectMake([[arr[k] valueForKey:@"Left"]doubleValue], [[arr[k] valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                        [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
                    }
                }
            }
            else if ([[arr[i] valueForKey:@"SinaturePage"] isEqualToString:@"PAGE LEVEL"]) {
                // coordinatesArray = [NSMutableArray array];
                //  for (int i = 0; i< array.count; i++) {
                
                if ([[arr[i]valueForKey:@"PageNo"]intValue] == k) {
                    pnum = k;//[[array[i]valueForKey:@"PageNo"]intValue];
                    // coordinatesRect = CGRectMake([[array[i] valueForKey:@"Left"]doubleValue], [[array[i]  valueForKey:@"Top"]doubleValue] - 58, 112 , 58);
                    [coordinatesArray  addObject:[NSValue valueWithCGRect:CGRectMake([[arr[i] valueForKey:@"Left"]doubleValue], [[arr[i]  valueForKey:@"Top"]doubleValue] - 58,112 , 58)]];
                    //[self pageLevel:pdfContext :pdf :k :pnum :coordinatesRect :imgSignature :outputPDFData];
                    // return;
                }
                
                //}
            }
            
            //for (int i = 0; i<coordinatesArray.count; i++) {
            
        }
        CGPDFPageRef page3 = CGPDFDocumentGetPage(pdf, k);
        pageRect = CGPDFPageGetBoxRect(page3, kCGPDFMediaBox);
        CGContextBeginPage(pdfContext, &pageRect);
        CGContextDrawPDFPage(pdfContext, page3);
        
        if (k == pnum) {
            for (int i = 0; i<coordinatesArray.count; i++) {
                pageRect = [coordinatesArray[i]CGRectValue];
                // pageRect = coordinatesRect;
                
                CGImageRef pageImage = [imgSignature CGImage];
                CGContextDrawImage(pdfContext, pageRect, pageImage);
            }
        }
        CGPDFContextEndPage(pdfContext);
        // }
    }
    //}
    // release the allocated memory
    CGPDFContextEndPage(pdfContext);
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
    
    // write new PDFData in "outPutPDF.pdf" file in document directory
    NSString *docsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pdfFilePath =[NSString stringWithFormat:@"%@/outPutPDF.pdf",docsDirectory];
    [outputPDFData writeToFile:pdfFilePath atomically:YES];
    return pdfFilePath;
    
}
- (void)showModals:(UIModalPresentationStyle) style style:(MPBCustomStyleSignatureViewController*) controller Lot:(NSString*) lotId
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Saving token
        
        MPBCustomStyleSignatureViewController* signatureViewController = [controller initWithConfiguration:[MPBSignatureViewControllerConfiguration configurationWithFormattedAmount:@""]];
        signatureViewController.modalPresentationStyle = style;
        signatureViewController.strExcutedFrom=@"Waiting for Others";
        signatureViewController.preferredContentSize = CGSizeMake(800, 500);
        signatureViewController.configuration.scheme = MPBSignatureViewControllerConfigurationSchemeAmex;
        signatureViewController.signatureWorkFlowID = [[NSUserDefaults standardUserDefaults] valueForKey:@"PendingWorkflowID"];
        signatureViewController.LotId = lotId;
        signatureViewController.isBulk = true;
        signatureViewController.continueBlock = ^(UIImage *signature) {
            [self showImage: signature];
        };
        signatureViewController.cancelBlock = ^ {
            
        };
        [self presentViewController:signatureViewController animated:YES completion:nil];
        
    });
}
- (void)showModal:(UIModalPresentationStyle) style style:(MPBCustomStyleSignatureViewController*) controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Saving token
        
        MPBCustomStyleSignatureViewController* signatureViewController = [controller initWithConfiguration:[MPBSignatureViewControllerConfiguration configurationWithFormattedAmount:@""]];
        signatureViewController.modalPresentationStyle = style;
        signatureViewController.strExcutedFrom=@"Waiting for Others";
        signatureViewController.preferredContentSize = CGSizeMake(800, 500);
        signatureViewController.configuration.scheme = MPBSignatureViewControllerConfigurationSchemeAmex;
        signatureViewController.signatureWorkFlowID = [[NSUserDefaults standardUserDefaults] valueForKey:@"PendingWorkflowID"];
        signatureViewController.continueBlock = ^(UIImage *signature) {
            [self showImage: signature];
        };
        signatureViewController.cancelBlock = ^ {
            
        };
        [self presentViewController:signatureViewController animated:YES completion:nil];
        
    });
}


-(void)getDocumentInfo:(NSString*)workflowId

{
    
    [self startActivity:@"Loading.."];
    NSString *requestURL = [NSString stringWithFormat:@"%@GetWorkflowInfo?WorkFlowId=%@",kDocumentInfo,workflowId];
    
    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        
        // if(status)
        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
            
        {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                _docInfoArray = [responseValue valueForKey:@"Response"];
                
                if (_docInfoArray != (id)[NSNull null])
                {
                    // [self.documentInfoTable reloadData];
                    
                    
                    if(_docInfoArray.count == 1)
                    {
                        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        DocumentInfoVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DocumentInfoVC"];
                        objTrackOrderVC.documentInfoArray = _docInfoArray[0];
                        
                        NSString *names = [[_docInfoArray objectAtIndex:0]valueForKey:@"DocumentName"];
                        
                        objTrackOrderVC.titleString = names;
                        
                        // objTrackOrderVC.status = self.status;
                        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                        
                    }
                    else{
                        DocumentInfoNames *objTrackOrderVC= [[DocumentInfoNames alloc] initWithNibName:@"DocumentInfoNames" bundle:nil];
                        objTrackOrderVC.docInfoWorkflowId = workflowId;
                        objTrackOrderVC.status = @"Pending";
                        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                        
                        // [self.documentInfoTable reloadData];
                    }
                    //Check Null Originator
                    
                    [self stopActivity];
                }
                else
                {
                    UIAlertController * alert = [UIAlertController
                                                 alertControllerWithTitle:@""
                                                 message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                 preferredStyle:UIAlertControllerStyleAlert];
                    
                    //Add Buttons
                    
                    UIAlertAction* yesButton = [UIAlertAction
                                                actionWithTitle:@"Ok"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                    
                    //Add your buttons to alert controller
                    
                    [alert addAction:yesButton];
                    [self presentViewController:alert animated:YES completion:nil];
                    [self stopActivity];
                }
                
            });
        }
        else{
            //if ([responseValue isKindOfClass:[NSString class]]) {
            // if ([responseValue isEqualToString:@"Invalid token Please Contact Adminstrator"]) {
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:nil
                                             message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0]
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                //Add Buttons
                
                UIAlertAction* yesButton = [UIAlertAction
                                            actionWithTitle:@"Ok"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                    //Handle your yes please button action here
                    //Logout
                    //                                            AppDelegate *theDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    //                                            theDelegate.isLoggedIn = NO;
                    //                                            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:theDelegate.isLoggedIn] forKey:@"isLogin"];
                    //                                            [NSUserDefaults resetStandardUserDefaults];
                    //                                            [NSUserDefaults standardUserDefaults];
                    //                                            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    //                                            ViewController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ViewController"];
                    //                                            [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                }];
                
                [alert addAction:yesButton];
                
                [self presentViewController:alert animated:YES completion:nil];
                
                return;
                //}
            });
        }
    }];
    
    
}

#pragma mark - alerts for documents

-(void) alertForFlexiforms
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Flexiforms can't be opened as of now."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        
        [self stopActivity];
        
        
    }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    [self stopActivity];
}

- (void) alertForBulkDocuments
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Bulk documents can't be opened as of now."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        
        [self stopActivity];
        
        
    }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    [self stopActivity];
}

-(void) alertForCollaborative
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Collaborative documents can't be opened as of now."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        
        [self stopActivity];
        
        
    }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    [self stopActivity];
    
    
}

-(void) alertForReview
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Review documents can't be opened as of now."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        
        [self stopActivity];
        
        
    }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    [self stopActivity];
    
    
}

#pragma mark  - parallel signing

-(void)parallelSigningNoPassword:(long)indexpath
{
    int checkIsOpen = [[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"IsOpened"]intValue];
    
    if (checkIsOpen == 1)
    {
        
        // [@"Email Id : " stringByAppendingFormat:@"%@", [[signatoriescount objectAtIndex:indexPath.row]valueForKey:@"EmailID"]]
        
        NSString *namneAndString = [NSString stringWithFormat:@"%@,%@.", [[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"Name"],[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"EmailId"]];
        
        NSString *message = [[@"Document is currently opened by " stringByAppendingString:namneAndString] stringByAppendingString:@" So document can be opened in read only mode ."];
        
        
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@""
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        //Add Buttons
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
            //Handle your yes please button action here
            
            _pdfImageArray=[_checkNullArray valueForKey:@"Document"];
            
            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *path = [documentsDirectory stringByAppendingPathComponent:[[_searchResults objectAtIndex:indexpath] objectForKey:@"DisplayName"]];
            [data writeToFile:path atomically:YES];
            
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
            CFRelease(uuid);
            
            //Add signBox
            UIImage *image = [UIImage imageNamed:@"signer.png"];
            
            if (coordinatesArray.count != 0) {
                // path = [createPdfString addSignature:image onPDFData:data withCoordinates:coordinatesArray Count:arr];
                
                
            }
            //                                            BOOL statuscheck = false;
            //                                            for (int i = 0; i<coordinatesArray.count; i++) {
            //                                                if ([[coordinatesArray[i]valueForKey:@"StatusID"]isEqualToString:@"53"]) {
            //                                                    statuscheck = true;
            //                                                }
            //                                            }
            
            if (isdelegate == false) {
                CompletedNextVC *temp = [[CompletedNextVC alloc] init];//WithFilename:path path:path document: doc];
                temp._pathForDoc = path;
                temp.pdfImagedetail = _pdfImageArray;
                temp.myTitle = [[_checkNullArray valueForKey:@"DocumentName"]objectAtIndex:0];
                temp.strExcutedFrom=@"Completed";
                temp.workflowID = [[_searchResults objectAtIndex:indexpath] valueForKey:@"WorkFlowId"];
                temp.documentCount = [[_checkNullArray valueForKey:@"NoOfDocuments"] stringValue];
                temp.signatoryString = mstrXMLString;
                temp.attachmentCount = [[_checkNullArray valueForKey:@"NoOfAttachments"] stringValue];
                [self.navigationController pushViewController:temp animated:YES];
                [self stopActivity];
                return;
            }
            else{
                ParallelSigning *temp = [[ParallelSigning alloc] init];//WithFilename:path path:path document: doc];
                
                temp._pathForDoc = path;
                temp.pdfImagedetail = _pdfImageArray;
                temp.myTitle = [[_checkNullArray valueForKey:@"DocumentName"]objectAtIndex:0];
                temp.strExcutedFrom=@"Completed";
                temp.workflowID = [[_searchResults objectAtIndex:indexpath] valueForKey:@"WorkFlowId"];
                temp.documentCount = [[_checkNullArray valueForKey:@"NoOfDocuments"] stringValue];
                temp.placeholderArray = coordinatesArray;
                
                temp.signatoryString = mstrXMLString;
                temp.matchSignersList = arr;
                
                temp.attachmentCount = [[_checkNullArray valueForKey:@"NoOfAttachments"] stringValue];
                [self.navigationController pushViewController:temp animated:YES];
                [self stopActivity];
            }
        }];
        
        //Add your buttons to alert controller
        
        [alert addAction:yesButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        [self stopActivity];
        
    }
    
}


-(void)parallelSigning:(long )indexPath
{
    int checkIsOpen = [[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"IsOpened"]intValue];
    
    if (checkIsOpen == 1)
    {
        isopened = true;
        NSString *namneAndString = [NSString stringWithFormat:@"%@,%@.", [[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"Name"],[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"EmailId"]];
        
        NSString *message = [[@"Document is currently opened by " stringByAppendingString:namneAndString] stringByAppendingString:@" So document can be opened in read only mode ."];
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@""
                                     message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        //Add Buttons
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
            //Handle your yes please button action here
            
            
            
        }];
        
        //Add your buttons to alert controller
        
        [alert addAction:yesButton];
        
        [self presentViewController:alert animated:YES completion:nil];
        [self stopActivity];
        return;
    }
    else
    {
        isopened = false;
    }
    
}


#pragma mark - Method For Push Notifications


-(void)getWorkflowsForPush:(NSDictionary*)userInfo{
    
    [self startActivity:@"Loading"];
    NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@&workflowType=%@",kOpenPDFImage,[userInfo valueForKey:@"WorkflowID"],[userInfo valueForKey:@"workflowtype"]];
    
    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        
        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
        {
            int issucess = [[responseValue valueForKey:@"IsSuccess"]intValue];
            
            if (issucess != 0) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _checkNullArray = [[NSMutableArray alloc]init];
                    arr = [[NSMutableArray alloc]init];
                    coordinatesArray = [[NSMutableArray alloc]init];
                    _pdfImageArray = [[NSMutableArray alloc]init];
                    mstrXMLString = [[NSMutableString alloc]init];
                    
                    _checkNullArray = [responseValue valueForKey:@"Response"];
                    
                    if (_checkNullArray == (id)[NSNull null])
                    {
                        UIAlertController * alert = [UIAlertController
                                                     alertControllerWithTitle:@""
                                                     message:@"This file has been corrupted."
                                                     preferredStyle:UIAlertControllerStyleAlert];
                        
                        //Add Buttons
                        
                        UIAlertAction* yesButton = [UIAlertAction
                                                    actionWithTitle:@"Ok"
                                                    style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                            //Handle your yes please button action here
                            
                        }];
                        
                        //Add your buttons to alert controller
                        
                        [alert addAction:yesButton];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        [self stopActivity];
                        
                        return;
                    }
                    
                    
                    arr =  [_checkNullArray valueForKey:@"Signatory"];
                    
                    NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
                    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:arr requiringSecureCoding:NO error:nil];
                    [prefs setObject:data forKey:@"Signatory"];
                    
                    
                    /////////////////alerts
                    
                    if (arr.count > 0) {
                        NSString * ischeck = @"ischeck";
                        [mstrXMLString appendString:@"Signed By:"];
                        
                        for (int i = 0; arr.count>i; i++) {
                            NSDictionary * dict = arr[i];
                            
                            //status id for parallel signing
                            if ([dict[@"StatusID"]intValue] == 7) {
                                // statusId = 1;
                            }
                            
                            //displaying signatories on top .
                            if ([dict[@"StatusID"]intValue] == 13) {
                                NSString* emailid = dict[@"EmailID"];
                                NSString* name = dict[@"Name"];
                                NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                                
                                if ([mstrXMLString containsString:[NSString stringWithFormat:@"%@",totalstring]]) {
                                    
                                }
                                else
                                {
                                    [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
                                }
                                
                                //[mstrXMLString appendString:[NSString stringWithFormat:@"Signed By: %@",totalstring]];
                                ischeck = @"Signatory";
                                NSLog(@"%@",mstrXMLString);
                            }
                        }
                        if ([ischeck  isEqual: @"ischeck"])
                        {
                            NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
                            mstrXMLString = [NSMutableString string];
                            
                            [mstrXMLString appendString:@"Originated By:"];
                            for (int i = 0; arr1.count > i; i++) {
                                NSDictionary * dict = arr1[i];
                                
                                NSString* emailid = dict[@"EmailID"];
                                NSString* name = dict[@"Name"];
                                NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                                [mstrXMLString appendString:[NSString stringWithFormat:@" %@",totalstring]];
                                NSLog(@"%@",mstrXMLString);
                            }
                        }
                        //}
                    }
                    
                    else
                    {
                        NSArray *arr1 =  [[responseValue valueForKey:@"Response"] valueForKey:@"Originatory"];
                        [mstrXMLString appendString:@"Originated By:"];
                        
                        for (int i = 0; arr1.count > i; i++) {
                            NSDictionary * dict = arr1[i];
                            
                            NSString* emailid = dict[@"EmailID"];
                            NSString* name = dict[@"Name"];
                            NSString * totalstring = [NSString stringWithFormat:@"%@[%@]",name,emailid];
                            [mstrXMLString appendString:[NSString stringWithFormat:@"%@",totalstring]];
                            NSLog(@"%@",mstrXMLString);
                        }
                    }
                    
                    // _coordinatesArray = [[NSMutableArray alloc]init];
                    //Checking for signatorys and multiple PDF
                    for (int i = 0; i<arr.count; i++) {
                        
                        if ([[arr[i]valueForKey:@"EmailID"] caseInsensitiveCompare:[[NSUserDefaults standardUserDefaults]valueForKey:@"Email"]] == NSOrderedSame)
                        {
                            // ([[[_checkNullArray valueForKey:@"CurrentStatus"]valueForKey:@"IsOpened"]intValue]== 1)
                            if (([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)) {
                                isdelegate = false;
                                statusId = 0;
                            }
                            else if ([[arr[i]valueForKey:@"StatusID"]integerValue] == 7){
                                isdelegate = true;
                                statusId = 1;
                            }
                            if ((([[arr[i]valueForKey:@"StatusID"]integerValue] == 7)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 53)|| ([[arr[i]valueForKey:@"StatusID"]integerValue] == 8))) {
                                
                                if ([[arr[i]valueForKey:@"DocumentId"]integerValue]== [[[_checkNullArray valueForKey:@"DocumentId"]objectAtIndex:0]integerValue]) {
                                    [coordinatesArray addObject:arr[i]];
                                }
                            }
                        }
                    }
                    
                    statusForPlaceholders = [coordinatesArray valueForKey:@"StatusID"];
                    
                    //FileDataBytes
                    _pdfImageArray=[[responseValue valueForKey:@"Response"] valueForKey:@"Document"];
                    
                    if (_pdfImageArray != (id)[NSNull null])
                    {
                        NSUserDefaults *statusIdForMultiplePdf = [NSUserDefaults standardUserDefaults];
                        [statusIdForMultiplePdf setInteger:(long)statusId forKey:@"statusIdForMultiplePdf"];
                        [statusIdForMultiplePdf synchronize];
                        
                        if ([[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
                            
                            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                            
                            self.pdfDocument = [[PDFDocument alloc] initWithData:data];
                            
                            //[userInfo valueForKey:@"WorkflowID"],[userInfo valueForKey:@"workflowtype"]];
                            //workflow type  == 3
                            
                            if ([[userInfo valueForKey:@"workflowtype"]integerValue] == 3)
                            {
                                // [self parallelSigning:indexPath.row];
                                
                            }
                            
                            NSString *checkPassword = [[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"];
                            [[NSUserDefaults standardUserDefaults] setObject:checkPassword forKey:@"checkPassword"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
                            NSString *path = [documentsDirectory stringByAppendingPathComponent:[[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentName"]objectAtIndex:0]];
                            [data writeToFile:path atomically:YES];
                            
                            
                            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"pathForDoc"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSString *displayName = [[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentName"]objectAtIndex:0];
                            [[NSUserDefaults standardUserDefaults] setObject:displayName forKey:@"displayName"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSString *docCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                            [[NSUserDefaults standardUserDefaults] setObject:docCount forKey:@"docCount"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSString *attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                            [[NSUserDefaults standardUserDefaults] setObject:attachmentCount forKey:@"attachmentCount"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            NSString *workflowId = [userInfo valueForKey:@"WorkflowID"];
                            [[NSUserDefaults standardUserDefaults] setObject:workflowId forKey:@"workflowId"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                            
                            
                            
                            if ([_pdfDocument isLocked]) {
                                UIAlertView *passwordAlertView = [[UIAlertView alloc]initWithTitle: @"Password Protected"
                                                                                           message:  [NSString stringWithFormat: @"%@ %@", path.lastPathComponent, @"is password protected"]
                                                                                          delegate: self
                                                                                 cancelButtonTitle: @"Cancel"
                                                                                 otherButtonTitles: @"Done", nil];
                                passwordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
                                [passwordAlertView show];
                                return;
                                
                            }
                            
                            [self stopActivity];
                            
                        }
                        else
                        {
                            
                            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfImageArray options:0];
                            // from your converted Base64 string
                            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
                            NSString *path = [documentsDirectory stringByAppendingPathComponent:[[[responseValue valueForKey:@"Response"] valueForKey:@"DocumentName"]objectAtIndex:0]];
                            [data writeToFile:path atomically:YES];
                            
                            CFUUIDRef uuid = CFUUIDCreate(NULL);
                            CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                            CFRelease(uuid);
                            
                            UIImage *image = [UIImage imageNamed:@"signer.png"];
                            
                            if (coordinatesArray.count != 0) {
                                
                            }
                            //[self stopActivity];
                            // return;
                        }
                        
                        //workflow type  == 3
                        //parallel signing
                        if ([[userInfo valueForKey:@"workflowtype"]integerValue] == 3)
                        {
                            // [self parallelSigningNoPassword:indexPath.row];
                            
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"data"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        NSData * data = [NSKeyedArchiver archivedDataWithRootObject:coordinatesArray requiringSecureCoding:NO error:nil];
                        [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"coordinatesArray"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        //                        [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"arr"];
                        //                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                        if (isdelegate == true)
                        {
                            PendingListVC *temp = [[PendingListVC alloc]init];//WithNibName:@"PendingListVC" bundle:nil];
                            
                            temp.pdfImagedetail = _pdfImageArray;
                            temp.workFlowID = [userInfo valueForKey:@"WorkflowID"];
                            temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                            temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                            temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
                            temp.myTitle = [userInfo valueForKey:@"DocumentName"];
                            
                            temp.signatoryString = mstrXMLString;
                            temp.statusId = statusId;
                            temp.signatoryHolderArray = arr;
                            temp.placeholderArray = coordinatesArray;
                            
                            temp.workFlowType = [userInfo valueForKey:@"workflowtype"];
                            temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
                            temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
                            
                            UINavigationController *navigationRootController = [[UINavigationController alloc] initWithRootViewController:temp];
                            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:navigationRootController animated:YES completion:NULL];
                            
                            [self stopActivity];
                        }
                        else if(isdelegate == false){
                            PendingListVC *temp = [[PendingListVC alloc]init];//WithNibName:@"PendingListVC" bundle:nil];
                            
                            temp.pdfImagedetail = [[responseValue valueForKey:@"Response"] valueForKey:@"Document"];
                            temp.workFlowID = [userInfo valueForKey:@"WorkflowID"];
                            temp.documentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfDocuments"] stringValue];
                            temp.attachmentCount = [[[responseValue valueForKey:@"Response"] valueForKey:@"NoOfAttachments"] stringValue];
                            temp.isPasswordProtected = [[[responseValue valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue];
                            temp.myTitle = [userInfo valueForKey:@"DocumentName"];
                            temp.signatoryString = mstrXMLString;
                            temp.statusId = statusId;
                            temp.signatoryHolderArray = arr;
                            temp.placeholderArray = coordinatesArray;
                            temp.workFlowType = [userInfo valueForKey:@"workflowtype"];
                            temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
                            temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
                            
                            UINavigationController *navigationRootController = [[UINavigationController alloc] initWithRootViewController:temp];
                            [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:navigationRootController animated:YES completion:NULL];
                            
                            //  [self.navigationController pushViewController:temp animated:YES];
                            [self stopActivity];
                        }
                        
                    }
                    else{
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: @"This file was corrupted. Please contact eMudhra for more details." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                        [self stopActivity];
                    }
                });
                
            }
            else{
                //Alert at the time of no server connection
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                    [self stopActivity];
                    
                });
                
            }
        }
    }];
}


#pragma mark - Search Bar
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    // Do the search...
}
-(void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    //This'll Show The cancelButton with Animation
    [searchBar setShowsCancelButton:YES animated:YES];
    //remaining Code'll go here
}
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    //This'll Hide The cancelButton with Animation
    _searchResults = [NSMutableArray array];
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    _currentPage = 1;
    searchSting = @"";
    [self makeServieCallWithPageNumaber:_currentPage :searchSting];
    
    //remaining Code'll go here
}




-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //    if ([searchText length] == 0) {
    //        [_searchResults removeAllObjects];
    //            if (_pendingArray != (id)[NSNull null])
    //            {
    //                [_searchResults addObjectsFromArray:(NSMutableArray*)_pendingArray];
    //            }
    //    [searchBar resignFirstResponder];
    //    }
    if ([searchText length] >= 3)
    {
        if(isPageRefreshing==NO){
            isPageRefreshing=YES;
            [_searchResults removeAllObjects];
            
            _currentPage = 1;
            searchSting = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            //searchSting = searchText;
            [self makeServieCallWithPageNumaber:_currentPage :searchSting];
            
        }
        [_pendingTableView reloadData];
    }
    
}



-(void) actionSheet: (UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(actionSheet.tag == 101) {
            //do something
            switch (buttonIndex) {
                case 0: {
                    
                    break;
                }
                case 1:
                {
                    UIAlertView *alertView3 = [[UIAlertView alloc] initWithTitle:@"Download"
                                                                         message:@"Do you want to download document?"
                                                                        delegate:self
                                                               cancelButtonTitle:@"Yes"
                                                               otherButtonTitles:@"No", nil];
                    alertView3.tag = 3;
                    [alertView3 show];
                    
                    break;
                }
                    
                default:
                    break;
            }
            
            
        }
        else if(actionSheet.tag == 102) {
            //do something else
            switch (buttonIndex) {
                case 0:
                {
                    
                    
                    NSString * aadhaarNumber = [[NSUserDefaults standardUserDefaults]
                                                valueForKey:@"SavedAadhaarNumber"];
                    if ([aadhaarNumber isEqualToString:@"<null>"] || [aadhaarNumber isEqualToString:@""])
                    {
                        
                        
                        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        GetOTPVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"GetOTPVC"];
                        self.definesPresentationContext = YES; //self is presenting view controller
                        objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                        [self.navigationController presentViewController:objTrackOrderVC animated:YES completion:nil];
                        
                        
                    }
                    else
                    {
                        
                        //SavedAadhaarNumber
                        
                        [self startActivity:@"Processing..."];
                        NSString *requestURL = [NSString stringWithFormat:@"%@GetOTP?AadhaarNumber=%@",kGetOTP,[[NSUserDefaults standardUserDefaults]valueForKey:@"SavedAadhaarNumber"]];
                        
                        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
                            
                            //if(status)
                            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                                
                            {
                                dispatch_async(dispatch_get_main_queue(),
                                               ^{
                                    NSNumber * isSuccessNumber = (NSNumber *)[responseValue valueForKey:@"IsSuccess"];
                                    if([isSuccessNumber boolValue] == YES)
                                    {
                                        _otpArray = responseValue;
                                        UIAlertController * alert = [UIAlertController
                                                                     alertControllerWithTitle:@""
                                                                     message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                        
                                        //Add Buttons
                                        
                                        UIAlertAction* yesButton = [UIAlertAction
                                                                    actionWithTitle:@"Ok"
                                                                    style:UIAlertActionStyleDefault
                                                                    handler:^(UIAlertAction * action) {
                                            //Handle your yes please button action here
                                            
                                            UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                            CustomSignVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"CustomSignVC"];
                                            objTrackOrderVC.aadhaarString = [[NSUserDefaults standardUserDefaults]valueForKey:@"SavedAadhaarNumber"];
                                            self.definesPresentationContext = YES; //self is presenting view controller
                                            objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                                            [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                                        }];
                                        
                                        //Add your buttons to alert controller
                                        
                                        [alert addAction:yesButton];
                                        
                                        
                                        [self presentViewController:alert animated:YES completion:nil];
                                        
                                        
                                        [_pendingTableView reloadData];
                                        
                                        [self stopActivity];
                                    }
                                    else{
                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                        [alert show];
                                        [self stopActivity];
                                    }
                                    
                                    
                                });
                                
                            }
                            else{
                                
                                NSError *error = (NSError *)responseValue;
                                if (error) {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Error from KSA Server" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                    //_adharText.text = nil;
                                    [alert show];
                                    [self stopActivity];
                                    return;
                                }
                                
                                [self stopActivity];
                            }
                            
                        }];
                        
                        // [self stopActivity];
                        
                    }
                    break;
                }
                case 1:
                {
                    [self showModal:UIModalPresentationFullScreen style:[MPBDefaultStyleSignatureViewController alloc]];
                    [_pendingTableView reloadData];
                    
                    break;
                }
                    
                default:
                    break;
            }
            
        }
    });
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    NSString *resultText = [textField.text stringByReplacingCharactersInRange:range
                                                                   withString:string];
    return resultText.length <= 12;
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    UIAlertViewStyle style = alertView.alertViewStyle;
    
    if ((style == UIAlertViewStyleSecureTextInput) ||
        (style == UIAlertViewStylePlainTextInput) ||
        (style == UIAlertViewStyleLoginAndPasswordInput))
    {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0)
        {
            return NO;
        }
    }
    
    return YES;
    
}




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *emailInput = [alertView textFieldAtIndex:0].text;
    
    [[NSUserDefaults standardUserDefaults] setObject:emailInput forKey:@"Password"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    password = [alertView textFieldAtIndex: 0].text.UTF8String;
    [alertView dismissWithClickedButtonIndex: buttonIndex animated: TRUE];
    if (buttonIndex == 1) {
        
        if ([self.pdfDocument isLocked])
            
            [self onPasswordOK];
        else
            [self askForPassword: @"Wrong password. Try again:"];
    }
    
    else{
        [self stopActivity];
        //Network Check
        if (![self connected])
        {
            if(hasPresentedAlert == false){
                
                // not connected
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No internet connection!" message:@"Check internet connection!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [alert show];
                hasPresentedAlert = true;
            }
        } else
        {
            
            if (alertView.tag == 4)
            {
                if (buttonIndex == 1)
                {
                    //Login
                    UITextField *aadharNumber = [alertView textFieldAtIndex:0];
                    NSLog(@"Aadhar Number: %@", aadharNumber.text);
                    
                    //Saving Aadhaar Number
                    NSString *aadhaar = aadharNumber.text;
                    [[NSUserDefaults standardUserDefaults] setObject:aadhaar forKey:@"Aadhaar Number"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    //
                    
                    /*************************Web Service Get OTP***************************/
                    
                    [self startActivity:@"Loading..."];
                    NSString *requestURL = [NSString stringWithFormat:@"%@GetAadharOTP?AadhaarNumber=%@",kGetOTP,aadharNumber.text];
                    
                    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
                        
                        // if(status)
                        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                            
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                NSNumber * isSuccessNumber = (NSNumber *)[responseValue valueForKey:@"IsSuccess"];
                                if([isSuccessNumber boolValue] == YES)
                                {
                                    _otpArray = [[responseValue valueForKey:@"Messages"] objectAtIndex:0];
                                    
                                    [_pendingTableView reloadData];
                                    
                                    UIAlertView * alert5 =[[UIAlertView alloc ] initWithTitle:@"OTP" message:@"Please enter OTP" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
                                    alert5.alertViewStyle = UIAlertViewStylePlainTextInput;
                                    [[alert5 textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
                                    [[alert5 textFieldAtIndex:0] becomeFirstResponder];
                                    [alert5 addButtonWithTitle:@"Sign"];
                                    alert5.tag = 5;
                                    [alert5 show];
                                    [self stopActivity];
                                }
                                else
                                {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                    [alert show];
                                    [self stopActivity];
                                }
                                
                            });
                            
                        }
                        else{
                            
                            NSError *error = (NSError *)responseValue;
                            if (error) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"Error from KSA Server" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                                //_adharText.text = nil;
                                [alert show];
                                [self stopActivity];
                                return;
                            }
                            
                            
                        }
                        [self stopActivity];
                    }];
                    
                    //
                }
                else if (buttonIndex == 0)
                {
                    
                }
            }
            /***************************Aadhar based Sign***********************************/
            else if(alertView.tag == 5)
            {
                if (buttonIndex == 1) {
                    UITextField *otp = [alertView textFieldAtIndex:0];
                    NSLog(@"OTP: %@", otp.text);
                    NSString *PendingWorkflowID = [[NSUserDefaults standardUserDefaults]
                                                   valueForKey:@"PendingWorkflowID"];
                    /*************************Web Service Get OTP*******************************/
                    
                    [self startActivity:@"Loading..."];
                    
                    NSString *post = [NSString stringWithFormat:@"AdhaarNumber=%@&OTP=%@&WorkFlowId=%@",[[NSUserDefaults standardUserDefaults]
                                                                                                         valueForKey:@"Aadhaar Number"],otp.text,PendingWorkflowID];
                    [WebserviceManager sendSyncRequestWithURL:keSign method:SAServiceReqestHTTPMethodPOST body:post completionBlock:^(BOOL status, id responseValue)
                     {
                        
                        // if(status)
                        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                            
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                _signArray =[responseValue valueForKey:@"IsSuccess"];
                                NSNumber * isSuccessNumber = (NSNumber *)_signArray;
                                if([isSuccessNumber boolValue] == YES)
                                {
                                    UIAlertView *alertView28 = [[UIAlertView alloc] initWithTitle:@""
                                                                                          message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"Ok"
                                                                                otherButtonTitles:nil, nil];
                                    alertView28.tag = 28;
                                    [alertView28 show];
                                    
                                    
                                    /**********************************************************/
                                    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                    LMNavigationController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"HomeNavController"];
                                    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                                    //
                                    [_pendingTableView reloadData];
                                    [self stopActivity];
                                }
                                else{
                                    UIAlertView *alertView28 = [[UIAlertView alloc] initWithTitle:@""
                                                                                          message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"Ok"
                                                                                otherButtonTitles:nil, nil];
                                    alertView28.tag = 28;
                                    [alertView28 show];
                                    [self stopActivity];
                                }
                                
                                
                            });
                        }
                        else{
                            
                        }
                        
                    }];
                    
                    
                }
                else if (buttonIndex == 0)
                {
                    
                }
            }
            //
            
            
            /***********************Aadhar based Sign(from user)****************************/
            else if(alertView.tag == 6)
            {
                if (buttonIndex == 1) {
                    UITextField *otp = [alertView textFieldAtIndex:0];
                    NSLog(@"OTP: %@", otp.text);
                    NSString *PendingWorkflowID = [[NSUserDefaults standardUserDefaults]
                                                   valueForKey:@"PendingWorkflowID"];
                    /*************************Web Service Get OTP*******************************/
                    
                    [self startActivity:@"Loading..."];
                    
                    NSString *post = [NSString stringWithFormat:@"AdhaarNumber=%@&OTP=%@&WorkFlowId=%@",[[NSUserDefaults standardUserDefaults]
                                                                                                         valueForKey:@"SavedAadhaarNumber"],otp.text,PendingWorkflowID];
                    [WebserviceManager sendSyncRequestWithURL:keSign method:SAServiceReqestHTTPMethodPOST body:post completionBlock:^(BOOL status, id responseValue)
                     {
                        
                        // if(status)
                        if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                            
                        {
                            dispatch_async(dispatch_get_main_queue(),
                                           ^{
                                _signArray =[responseValue valueForKey:@"IsSuccess"];
                                NSNumber * isSuccessNumber = (NSNumber *)_signArray;
                                if([isSuccessNumber boolValue] == YES)
                                {
                                    UIAlertView *alertView28 = [[UIAlertView alloc] initWithTitle:@""
                                                                                          message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"Ok"
                                                                                otherButtonTitles:nil, nil];
                                    alertView28.tag = 28;
                                    [alertView28 show];
                                    
                                    
                                    /**********************************************************/
                                    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                    LMNavigationController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"HomeNavController"];
                                    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
                                    //
                                    [_pendingTableView reloadData];
                                    [self stopActivity];
                                }
                                else{
                                    UIAlertView *alertView28 = [[UIAlertView alloc] initWithTitle:@""
                                                                                          message:[[responseValue valueForKey:@"Messages"] objectAtIndex:0]
                                                                                         delegate:self
                                                                                cancelButtonTitle:@"Ok"
                                                                                otherButtonTitles:nil, nil];
                                    alertView28.tag = 28;
                                    [alertView28 show];
                                    [self stopActivity];
                                }
                                
                            });
                        }
                        else{
                            
                        }
                        
                    }];
                    
                }
                else if (buttonIndex == 0)
                {
                    
                }
            }
        }
    }
}



#pragma mark - Toolbar
- (IBAction)cancelBtn:(id)sender
{
    [_pendingTableView reloadData];
    _pendingToolBar.hidden = YES;
    
}

- (IBAction)declineBtn:(id)sender
{
    
    /*************************Web Service*******************************/
    
    NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@",kOpenPDFImage,[[NSUserDefaults standardUserDefaults]
                                                                                                               valueForKey:@"PendingWorkflowID"]];
    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //if(status)
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                
            {
                
                _pdfImageArray=responseValue;
                
            }
            else{
                
                //Alert at the time of no server connection
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
                [self stopActivity];
                
            }
            
        });
        
    }];
    
    //    if ([[[_pdfImageArraySwipe valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
    //        _declineBtn.enabled = NO;
    //    }
    // else{
    _declineBtn.enabled = YES;
    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeclineVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"DeclineVC"];
    self.definesPresentationContext = YES;
    objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    objTrackOrderVC.strExcutedFrom=@"Pending";
    objTrackOrderVC.workflowID = [[NSUserDefaults standardUserDefaults]
                                  valueForKey:@"PendingWorkflowID"];
    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
    
    //  }
    
    
}



- (IBAction)downloadBtn:(id)sender
{
    
    /*************************Web Service*******************************/
    
    //    if ([[[_pdfImageArraySwipe valueForKey:@"Response"] valueForKey:@"IsPasswordProtected"] boolValue]==YES) {
    //        _downloadBtn.enabled = YES;
    //    }
    //else{
    _downloadBtn.enabled = YES;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@""
                                 message:@"Do you want to download document?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        
        NSString *requestURL = [NSString stringWithFormat:@"%@DownloadWorkflowDocuments?WorkFlowId=%@",kOpenPDFImage,[[NSUserDefaults standardUserDefaults]                                                                                                                                                                 valueForKey:@"PendingWorkflowID"]];
        [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //if(status)
                if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                    
                {
                    
                    _pdfImageArray=[responseValue valueForKey:@"Response"];
                    if (_pdfImageArray != (id)[NSNull null])
                    {
                        [_addFile removeAllObjects];
                        for(int i=0; i<[_pdfImageArray count];i++)
                        {
                            
                            _pdfFileName = [[_pdfImageArray objectAtIndex:i] objectForKey:@"DocumentName"];
                            _pdfFiledata = [[_pdfImageArray objectAtIndex:i] objectForKey:@"Document"];
                            
                            NSData *data = [[NSData alloc]initWithBase64EncodedString:_pdfFiledata options:0];
                            NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
                            
                            CFUUIDRef uuid = CFUUIDCreate(NULL);
                            CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
                            CFRelease(uuid);
                            NSString *uniqueFileName = [NSString stringWithFormat:@"%@%@%@%@",_pdfFileName,@"                                                 ",(__bridge NSString *)uuidString, _pdfFileName];
                            
                            
                            NSString *path = [documentsDirectory stringByAppendingPathComponent:uniqueFileName];
                            [_addFile addObject:path];
                            
                            [data writeToFile:path atomically:YES];
                            
                            if (i==_pdfImageArray.count-1)
                            {
                                [self stopActivity];
                                QLPreviewController *previewController=[[QLPreviewController alloc]init];
                                previewController.delegate=self;
                                previewController.dataSource=self;
                                [self presentViewController:previewController animated:YES completion:nil];
                                [previewController.navigationItem setRightBarButtonItem:nil];
                            }
                            
                        }
                        
                    }
                    else{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[[responseValue valueForKey:@"Messages"]objectAtIndex:0] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                        [alert show];
                    }
                    
                }
                else{
                    
                    //Alert at the time of no server connection
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message: @"Try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                    [self stopActivity];
                }
            });
        }];
    }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        //Handle no, thanks button
    }];
    
    //Add your buttons to alert controller
    
    [alert addAction:yesButton];
    [alert addAction:noButton];
    
    [self presentViewController:alert animated:YES completion:nil];
    //}
    
}

- (IBAction)shareBtn:(id)sender
{
    
    /*************************Web Service*******************************/
    
    NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentDetailsById?workFlowId=%@",kOpenPDFImage,[[NSUserDefaults standardUserDefaults]valueForKey:@"PendingWorkflowID"]];
    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // if(status)
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])
                
            {
                _shareBtn.enabled = YES;
                
                NSString *pendingdocumentName =[[NSUserDefaults standardUserDefaults]
                                                valueForKey:@"PendingDisplayName"];
                NSString *pendingWorkflowID =[[NSUserDefaults standardUserDefaults]
                                              valueForKey:@"PendingWorkflowID"];
                UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                ShareVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ShareVC"];
                objTrackOrderVC.documentName = pendingdocumentName;
                objTrackOrderVC.workflowID = pendingWorkflowID;
                [self.navigationController pushViewController:objTrackOrderVC animated:YES];
                
            }
            else{
                
                
            }
            
        });
        
    }];
    
    
    
}

- (IBAction)recallBtn:(id)sender
{
    UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ListPdfViewer *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"ListPdfViewer"];
    self.definesPresentationContext = YES;
    objTrackOrderVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:objTrackOrderVC animated:YES completion:nil];
}

#pragma mark ValidationMethod

-(BOOL)IsValidEmail:(NSString *)checkString
{
    BOOL isvalidate;
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    //Valid email address
    
    if ([emailTest evaluateWithObject:checkString] == YES)
    {
        isvalidate = YES;
        //Do Something
    }
    else
    {
        isvalidate = NO;
        //NSLog(@"email not in proper format");
    }
    return isvalidate;
}

#pragma mark ask password

- (void)openDocument:(NSString *)file
{
    if ([self.pdfDocument isLocked]) {
        NSString *path  = [[NSUserDefaults standardUserDefaults] valueForKey:@"pathForDoc"];
        
        UIAlertView *passwordAlertView = [[UIAlertView alloc]initWithTitle: @"Password Protected"
                                                                   message: [NSString stringWithFormat: @"bbu", path.lastPathComponent]
                                                                  delegate: self
                                                         cancelButtonTitle: @"Cancel"
                                                         otherButtonTitles: @"Done", nil];
        passwordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [passwordAlertView show];
        
    }
    else {
        [self onPasswordOK];
    }
    
}

- (void)askForPassword:(NSString *)prompt
{
    NSString *path  = [[NSUserDefaults standardUserDefaults] valueForKey:@"pathForDoc"];
    UIAlertView *passwordAlertView = [[UIAlertView alloc]
                                      initWithTitle: @"Password Protected"
                                      message: [NSString stringWithFormat: prompt, path.lastPathComponent]
                                      delegate: self
                                      cancelButtonTitle: @"Cancel"
                                      otherButtonTitles: @"Done", nil];
    passwordAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [passwordAlertView show];
    
}

- (void)onPasswordOK//:(MuDocRef *)doc
{
    
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"data"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:coordinatesArray requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"coordinatesArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //    [[NSUserDefaults standardUserDefaults] setObject:arr forKey:@"arr"];
    //    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIImage *image = [UIImage imageNamed:@"signer.png"];
    if (coordinatesArray.count != 0) {
    }
    else
    {
        path  = [[NSUserDefaults standardUserDefaults] valueForKey:@"pathForDoc"];
    }
    
    NSString *displayName = [[NSUserDefaults standardUserDefaults] valueForKey:@"displayName"];
    NSString *docCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"docCount"];
    NSString *attachmentCount = [[NSUserDefaults standardUserDefaults] valueForKey:@"attachmentCount"];
    NSString *workflowId = [[NSUserDefaults standardUserDefaults] valueForKey:@"workflowId"];
    NSString *passwordProtected = [[NSUserDefaults standardUserDefaults] valueForKey:@"checkPassword"];
    
    if (![self.pdfDocument unlockWithPassword:[[NSUserDefaults standardUserDefaults] valueForKey:@"Password"]]) {
        [self askForPassword: @"Wrong password. Try again:"];
        [self stopActivity];
        return;
    }
    
    if (isopened) {
        if (isdelegate == true) {
            ParallelSigning *temp = [[ParallelSigning alloc] init];
            
            temp._pathForDoc = path;
            temp.pdfImagedetail = _pdfImageArray;
            temp.myTitle = [[_checkNullArray valueForKey:@"DocumentName"]objectAtIndex:0];
            temp.strExcutedFrom=@"Completed";
            temp.workflowID = workflowId;
            temp.documentID = [[[_checkNullArray valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
            
            temp.documentCount = [[_checkNullArray  valueForKey:@"NoOfDocuments"] stringValue];
            temp.attachmentCount = attachmentCount;
            temp.signatoryString = mstrXMLString;
            temp.matchSignersList = arr;
            temp.placeholderArray = coordinatesArray;
            temp.passwordForPDF = password;
            
            temp.attachmentCount = [[_checkNullArray  valueForKey:@"NoOfAttachments"] stringValue];
            [self.navigationController pushViewController:temp animated:YES];
            [self stopActivity];
            return;
        }
        else{
            CompletedNextVC *temp = [[CompletedNextVC alloc] init];
            temp._pathForDoc = path;
            temp.pdfImagedetail = _pdfImageArray;
            temp.myTitle = displayName;
            temp.documentID = [[[_checkNullArray valueForKey:@"Response"] valueForKey:@"DocumentId"]objectAtIndex:0];
            
            temp.strExcutedFrom=@"Completed";
            temp.workflowID = workflowId;
            temp.documentCount = docCount;
            temp.signatoryString = mstrXMLString;
            temp.passwordForPDF = password;
            
            temp.attachmentCount = attachmentCount;
            [self.navigationController pushViewController:temp animated:YES];
            [self stopActivity];
            return;
        }
    }
    else{
        if (isdelegate == true) {
            PendingListVC *temp = [[PendingListVC alloc] init];
            temp.pdfImagedetail = _pdfImageArray;
            temp.workFlowID = workflowId;
            temp.documentCount = docCount;
            temp.attachmentCount = attachmentCount;
            temp.isPasswordProtected = passwordProtected;
            temp.myTitle = displayName;
            temp.signatoryString = mstrXMLString;
            temp.statusId = statusId;
            temp.signatoryHolderArray = arr;
            temp.placeholderArray = coordinatesArray;
            temp.workFlowType = [[_searchResults objectAtIndex:selectedIndex.row] valueForKey:@"WorkflowType"];
            temp.passwordForPDF = password;
            temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
            temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
            
            [self.navigationController pushViewController:temp animated:YES];
            [self stopActivity];
        }
        else{
            PendingListVC *temp = [[PendingListVC alloc] init];
            temp.pdfImagedetail = _pdfImageArray;
            temp.workFlowID = workflowId;
            temp.documentCount = docCount;
            temp.attachmentCount = attachmentCount;
            temp.isPasswordProtected = passwordProtected;
            temp.myTitle = displayName;
            temp.signatoryString = mstrXMLString;
            temp.statusId = statusId;
            temp.signatoryHolderArray = arr;
            temp.placeholderArray = coordinatesArray;
            temp.workFlowType = [[_searchResults objectAtIndex:selectedIndex.row] valueForKey:@"WorkflowType"];
            temp.passwordForPDF = password;
            temp.isSignatory = [[_checkNullArray valueForKey:@"IsSignatory"]boolValue];
            temp.isReviewer = [[_checkNullArray valueForKey:@"IsReviewer"]boolValue];
            
            
            [self.navigationController pushViewController:temp animated:YES];
            [self stopActivity];
        }
    }
    
    
}


#pragma mark - data source(Preview)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return [_addFile count];
    
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSString *fileName = [_addFile objectAtIndex:index];
    return [NSURL fileURLWithPath:fileName];
}

#pragma mark - delegate methods


- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item
{
    return YES;
}

- (CGRect)previewController:(QLPreviewController *)controller frameForPreviewItem:(id <QLPreviewItem>)item inSourceView:(UIView **)view
{
    
    //Rectangle of the button which has been pressed by the user
    //Zoom in and out effect appears to happen from the button which is pressed.
    UIView *view1 = [self.view viewWithTag:currentPreviewIndex+1];
    return view1.frame;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"Login"]){
        PendingListVC *controller = (PendingListVC *)segue.destinationViewController;
        //controller.detail = _pdfImageArray;
        //       controller.passData = self.mPassword.text;
        //        controller.passData = self.mMobileNumber.text;
        //controller.passData =
        NSLog(@"%@",controller);
    }
}


@end
