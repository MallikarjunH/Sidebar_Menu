//
//  DocumentLogVC.m
//  emSigner
//
//  Created by Administrator on 8/2/16.
//  Copyright © 2016 Emudhra. All rights reserved.
//

#import "DocumentLogVC.h"
#import "MBProgressHUD.h"
#import "NSObject+Activity.h"
#import "WebserviceManager.h"
#import "HoursConstants.h"
#import "AppDelegate.h"
#import "NSString+DateAsAppleTime.h"
#import "ViewController.h"


@interface DocumentLogVC ()
{
    NSString *descriptionStr;
    NSString *dateCategoryString;

}

@end

@implementation DocumentLogVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource  = self;
    // Do any additional setup after loading the view.
    
   // [self.tableView setContentOffset:CGPointMake(0.0, self.tableView.tableHeaderView.frame.size.height) animated:YES];
   // _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
//    UIImage *img = [UIImage imageNamed:@"logo-1.png"];
//    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
//    [imgView setImage:img];
//    // setContent mode aspect fit
//    [imgView setContentMode:UIViewContentModeScaleAspectFit];
//    self.navigationItem.titleView = imgView;
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.topItem.title = @" ";
    
    _docArray = [NSMutableArray arrayWithObjects:@"Document Name",@"Action", @"Date and Time",@"IP Address",@"User Email", nil];
    
   /*self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                                                         initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];*/
   // self.navigationController.navigationBar.topItem.title = @"Document Details";

    self.title = @"Document Details";;
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
   // [self.tableView registerNib:[UINib nibWithNibName:@"CustomDocumentLogTableViewCell" bundle:nil] forCellReuseIdentifier:@"CustomDocumentLogTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"DocumentLogTableViewCell" bundle:nil] forCellReuseIdentifier:@"DocumentLogTableViewCell"];
    self.tableView.allowsSelection = NO;
    /*************************Web Service*******************************/
    
    [self startActivity:@"Loading..."];
    NSString *requestURL = [NSString stringWithFormat:@"%@GetDocumentLog?workflowId=%@",kDocumentlog,_workflowID];
    
    [WebserviceManager sendSyncRequestWithURLGet:requestURL method:SAServiceReqestHTTPMethodGET body:requestURL completionBlock:^(BOOL status, id responseValue) {
        
      //  if(status)
            if(status && ![[responseValue valueForKey:@"Response"] isKindOfClass:[NSNull class]])

        {
            
             _documentNamesDic = [responseValue valueForKey:@"Response"];
             dispatch_async(dispatch_get_main_queue(), ^{   
           
                 
            //_docArray = [responseValue valueForKey:@"Response"];
                 
            [_tableView reloadData];
            
            [self stopActivity];
           }); 
            
        }
        else{
            // if ([responseValue isKindOfClass:[NSString class]]) {
            // if ([responseValue isEqualToString:@"Invalid token Please Contact Adminstrator"]) {
            
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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0)
    {
        NSArray *docLogs = [_documentNamesDic valueForKey:@"DocumentLogs"];
        return [[docLogs firstObject] count];
        
    } else return 0;//if (section == 1)
   // {
       
   // }/Users/emudhra/Documents/adarsha/emSigner/emsigner-iOS/emSigner/DocumentLogVC.m
    
    //return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            static NSString *CellIdentifier = @"cell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
           
           // cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
           
            NSArray *docLogs = [_documentNamesDic valueForKey:@"DocumentLogs"];
            UILabel *title = [cell viewWithTag:1];
            UILabel *subTitle = [cell viewWithTag:2];
            subTitle.numberOfLines = 0;
            
            if (indexPath.row == 0) {
                 title.text = [_docArray objectAtIndex:indexPath.row];
                [subTitle setText:[[AppDelegate AppDelegateInstance] strCheckNull:[NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%@",[_documentNamesDic valueForKey:@"DocumentName"][0]]]]];
            } else if (indexPath.row == [[docLogs firstObject] count ] - 1) {
                title.text = @"IPAddress";
                subTitle.text = @"10.80.102.121";

                } else {

                 NSString *dateFromArray = [[AppDelegate AppDelegateInstance] strCheckNull:[NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%@",[docLogs.firstObject[indexPath.row] valueForKey:@"DateTime"]]]];
                if (![dateFromArray isEqualToString:@"N/A"])
                                       {
                                           NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                           [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
                                           NSDate *dates = [formatter dateFromString:dateFromArray];
                                           NSString *case0String = [NSString string];

                                            NSArray* date= [[docLogs.firstObject[indexPath.row] valueForKey:@"DateTime"] componentsSeparatedByString:@"T"];
                                           NSString *transformedDate = [case0String transformedValue:dates];

                                          if ([transformedDate isEqualToString:@"Today"]) {
                                               title.text = [date objectAtIndex:1];

                                           }
                                           else{
                                              
                                           title.text = [case0String transformedValue:dates];
                                           }
                                       }
                                       else cell.textLabel.text = dateFromArray;
                subTitle.text = [docLogs.firstObject[indexPath.row] valueForKey:@"Action"];}
            
        return cell;
        }
             break;
        case 1:
        {
            DocumentLogTableViewCell *cell1 = [tableView dequeueReusableCellWithIdentifier:@"DocumentLogTableViewCell"];
            //Check Null String
            descriptionStr=[[AppDelegate AppDelegateInstance] strCheckNull:[NSString stringWithFormat:@"%@",[[_documentNamesDic valueForKey:@"Desecription"] objectAtIndex:indexPath.row]]];
            cell1.descriptionTextView.text = descriptionStr;
            cell1.selectionStyle = UITableViewCellSelectionStyleNone;
            //Check Null String Date
            NSString *descriptionStr1;
            descriptionStr1=[[AppDelegate AppDelegateInstance] strCheckNull:[NSString stringWithFormat:@"%@",[[_documentNamesDic valueForKey:@"ModifyDateTime"] objectAtIndex:indexPath.row]]];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
            NSDate *dates = [formatter dateFromString:descriptionStr1];

            NSString *case1String = [NSString string];
            
            NSArray* date= [[[_documentNamesDic valueForKey:@"ModifyDateTime"] objectAtIndex:indexPath.row]componentsSeparatedByString:@" "];

            NSString *transformedDate = [case1String transformedValue:dates];
            if ([transformedDate isEqualToString:@"Today"]) {
           
                cell1.dateTimeLable.text = [date objectAtIndex:1]; //[NSString stringWithFormat: @"%@ %@", [date objectAtIndex:1], [date objectAtIndex:2]];

            }
           else
           {
               cell1.dateTimeLable.text = [NSString stringWithFormat: @"%@   %@", transformedDate, [date objectAtIndex:1]] ;
           }
            return cell1;
        }
             break;
        default:
            break;
    }
    abort();
}

//- (id)transformedValue:(NSDate *)date
//{
//    // Initialize the formatter.
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateStyle:NSDateFormatterShortStyle];
//    [formatter setTimeStyle:NSDateFormatterNoStyle];
//
//    // Initialize the calendar and flags.
//    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSWeekdayCalendarUnit;
//    NSCalendar *calendar = [NSCalendar currentCalendar];
//
//    // Create reference date for supplied date.
//    NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
//    [comps setHour:0];
//    [comps setMinute:0];
//    [comps setSecond:0];
//    NSDate *suppliedDate = [calendar dateFromComponents:comps];
//
//    // Iterate through the eight days (tomorrow, today, and the last six).
//    int i;
//    for (i = -1; i < 7; i++)
//    {
//        // Initialize reference date.
//        comps = [calendar components:unitFlags fromDate:[NSDate date]];
//        [comps setHour:0];
//        [comps setMinute:0];
//        [comps setSecond:0];
//        [comps setDay:[comps day] - i];
//        NSDate *referenceDate = [calendar dateFromComponents:comps];
//        // Get week day (starts at 1).
//        int weekday = [[calendar components:unitFlags fromDate:referenceDate] weekday] - 1;
//
//        if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == -1)
//        {
//            // Tomorrow
//            return [NSString stringWithString:@""];
//        }
//        else if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == 0)
//        {
//            // Today's time (a la iPhone Mail)
//            formatter.dateFormat = @"HH:mm:ss";
//            NSString *convertedString = [formatter stringFromDate:date];
//            // [formatter setDateStyle:NSDateFormatterNoStyle];
//            //[formatter setTimeStyle:NSDateFormatterShortStyle];
//            return convertedString;
//        }
//        else if ([suppliedDate compare:referenceDate] == NSOrderedSame && i == 1)
//        {
//            // Today
//            return [NSString stringWithString:@"Yesterday"];
//        }
//        else if ([suppliedDate compare:referenceDate] == NSOrderedSame)
//        {
//            // Day of the week
//            NSString *day = [[formatter weekdaySymbols] objectAtIndex:weekday];
//            return day;
//        }
//    }
//
//    // It's not in those eight days.
//    NSString *defaultDate = [formatter stringFromDate:date];
//    return defaultDate;
//};

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //EMIOS1106
     NSArray *docLogs = [_documentNamesDic valueForKey:@"DocumentLogs"];
    if (indexPath.row == 0) {
        
        
        return 70;
        
    } else if (indexPath.row == [[docLogs firstObject] count ] - 1) {
        //gastos is an array
        
        return 70;
    } else {
        return 90;
    }

    //return 120.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Document Log";
        
    } else if (section == 1) {
        
        return @"Document Log";
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 70;
        
    } else if (section == 1) {
    
        return 40;
    }
    return 0;
}
//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
//{
//    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
//    v.backgroundView.backgroundColor =  [UIColor colorWithRed:241/255.0 green:241/255.0 blue:241/255.0 alpha:1];
//    [v.textLabel setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1]];

//}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//}

- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
}

- (IBAction)backBtn:(id)sender
{
    
    [self dismissViewControllerAnimated:YES completion:Nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end