//
//  ShowEditImagesFromImageList.m
//  emSigner
//
//  Created by Emudhra on 23/10/18.
//  Copyright © 2018 Emudhra. All rights reserved.
//

#import "ShowEditImagesFromImageList.h"
#import "MultipleImagesCell.h"
#import "SignersInformation.h"
#import "UploadDocuments.h"
#import <CoreData/CoreData.h>
#import "PreviewerController.h"
#import "RenameDocument.h"
#import "ShowPdfForImages.h"
#import "AttachedVC.h"
#import "SDImageCache.h"
#import "MWCommon.h"
#import "MWPhoto.h"

@interface ShowEditImagesFromImageList ()
{
    int currentPreviewIndex;
    NSString *pdfFileName;
    NSString *meta;
    NSMutableArray *_selections;
    
}

@end

@implementation ShowEditImagesFromImageList
- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem !=
        newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update theview.
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"imageCancelNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"imageNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"renameDocument"
                                               object:nil];
    
    _docresponsearray = [[NSMutableArray alloc]init];
    
    self.showMultipleImages.delegate = self;
    self.showMultipleImages.dataSource = self;
    self.navigationController.navigationBar.topItem.title = @" ";
    self.showMultipleImages.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.showMultipleImages registerNib:[UINib nibWithNibName:@"MultipleImagesCell" bundle:nil] forCellReuseIdentifier:@"MultipleImagesCell"];
    UIBarButtonItem *anotherButton1 = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(NextAction:)];
    
    self.navigationItem.rightBarButtonItems=@[anotherButton1];
    self.showMultipleImages.editing = YES;
    
    self.title = @"Explore";
    
}
-(void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationItem.title = @"Explore";
}

-(void) NextAction:(UIButton*)sender
{
    //Adarsha
    
    
    if (_uploadAttachment == true) {
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AttachedVC *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"AttachedVC"];
        // objTrackOrderVC.workFlowId = _workFlowID;
        
        NSString * base64data = [self createPdfWithName:@"sam" array:[NSArray arrayWithArray:_showMultImages]];
        
        NSData *convertToByrtes = [NSData dataWithContentsOfFile:base64data];
        NSString *base64image=[convertToByrtes base64EncodedStringWithOptions:0];
        objTrackOrderVC.base64Image = base64image;
        objTrackOrderVC.documentName = _documentName;
        objTrackOrderVC.isAttached = true;
        objTrackOrderVC.documentID = _documentId;
        objTrackOrderVC.parametersForWorkflow = _post;
        objTrackOrderVC.isDocStore = true;;
        objTrackOrderVC.document = @"ListAttachments";
        UINavigationController *objNavigationController = [[UINavigationController alloc]initWithRootViewController:objTrackOrderVC];
        [self presentViewController:objNavigationController animated:true completion:nil];
        // [self.navigationController presentViewController:objTrackOrderVC animated:true completion:nil];
        
        
    } else {
        NSUserDefaults * prefs = [NSUserDefaults standardUserDefaults];
        NSString *  CategoryId = [[prefs valueForKey:@"workflowCategoryId"]stringValue];
        NSString * base64data = [self createPdfWithName:@"sam" array:[NSArray arrayWithArray:_showMultImages]];
        
        NSData *convertToByrtes = [NSData dataWithContentsOfFile:base64data];
        NSString *base64image=[convertToByrtes base64EncodedStringWithOptions:0];
        NSLog(@"Base64StringIS:%@", base64image);
        NSMutableDictionary * senddict = [[NSMutableDictionary alloc]init];
        NSInteger categoryid = [CategoryId integerValue];
        [senddict setValue:[NSNumber numberWithLong:categoryid] forKey:@"CategoryID"];
        //[senddict setValue:CategoryId forKey:@"CategoryID"];
        [senddict setValue:base64image forKey:@"Base64FileData"];
        [senddict setValue:_categoryname forKey:@"DocumentNumber"];
        [senddict setValue:_documentName forKey:@"DocumentName"];
        [senddict setValue:@"" forKey:@"OptionalParam1"];
        [_delegate sendDataToA:senddict];
        // parametersNotification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"parametersNotification" object:senddict];
        //[self.navigationController popViewControllerAnimated:true];
        [self dismissViewControllerAnimated:true completion:nil];
        NSLog(@"%@",self.navigationController.viewControllers);}
    
}

- (void)receiveNotification:(NSNotification *)notification
{
    _showMultImages = [[NSMutableArray alloc]init];
    if ([[notification name] isEqualToString:@"imageNotification"]) {
        NSDictionary *myDictionary = (NSDictionary *)notification.object;
        _showMultImages = myDictionary.mutableCopy;
        [self.showMultipleImages reloadData];
        //doSomething here.
        
        
    }
    else if ([[notification name] isEqualToString:@"renameDocument"])
    {
        NSString *myString = (NSString *)notification.object;
        
        self.title = myString;
    }
    else if ([[notification name] isEqualToString:@"imageCancelNotification"])
    {
        NSDictionary *myDictionary = (NSDictionary *)notification.object;
        NSMutableArray * multiAray = [[NSMutableArray alloc]init];
        multiAray = myDictionary.mutableCopy;
        [multiAray removeLastObject];
        _showMultImages = multiAray.mutableCopy;
        [self.showMultipleImages reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addMultipleDocs:(id)sender {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Plase select your Documents" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [imagePicker setDelegate:self];
            [self presentViewController:imagePicker animated:YES completion:nil];
            
            //            UIDocumentMenuViewController *picker =  [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[@"com.adobe.pdf"] inMode:UIDocumentPickerModeImport];
            //
            //            picker.delegate = self;
            //
            //            [self presentViewController:picker animated:YES completion:nil];
            //
            
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"Your device doesn't have a camera." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Gallery" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        imagePickerController.navigationBar.translucent = false;
        imagePickerController.navigationBar.barTintColor = [UIColor colorWithRed:0.0/255.0 green:96.0/255.0 blue:192.0/255.0 alpha:1.0];
        imagePickerController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
        imagePickerController.navigationBar.tintColor = [UIColor whiteColor]; // Cancel button ~ any UITabBarButton items
        
        [self presentViewController:imagePickerController animated:YES completion:nil];
        
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [alert setModalPresentationStyle:UIModalPresentationPopover];
    
    //    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    //    popPresenter.sourceView = sender;
    //    popPresenter.sourceRect = sender.bounds; // You can set position of popover
    [self presentViewController:alert animated:TRUE completion:nil];
    
    
}
- (IBAction)Deletedocument:(id)sender {
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:@"Are you sure you want delete the document"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    //Add Buttons
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
        //Handle your yes please button action here
        [[NSNotificationCenter defaultCenter]postNotificationName:@"DeleteNotification"
                                                           object:self];
        [self.navigationController popToViewController:[self.navigationController viewControllers][0] animated:true];
    }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action)
                             {
        
    }];
    
    [alert addAction:yesButton];
    [alert addAction:cancel];
    //[self stopActivity];
    [self presentViewController:alert animated:YES completion:nil];
    
}
- (IBAction)EditDocument:(id)sender {
    
    RenameDocument *objTrackOrderVC= [[RenameDocument alloc] initWithNibName:@"RenameDocument" bundle:nil];
    self.definesPresentationContext = YES; //self is presenting view controller
    objTrackOrderVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController pushViewController:objTrackOrderVC animated:YES];
    
}

- (NSString *)createPdfWithName: (NSString *)name array:(NSArray*)images
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docspath = [paths objectAtIndex:0];
    pdfFileName = [docspath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",name]];
    UIGraphicsBeginPDFContextToFile(pdfFileName, CGRectZero, nil);
    for (int index = 0; index <[images count] ; index++)
    {
        
        UIImage *pngImage = [[images objectAtIndex:index]valueForKey:@"Image"];
        
        UIImage *lowResImage = [UIImage imageWithData:UIImageJPEGRepresentation(pngImage, 0.02)];
        
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, (lowResImage.size.width), (lowResImage.size.height)), nil);
        //  UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 612, 792), nil);
        
        [lowResImage drawInRect:CGRectMake(0, 0, (lowResImage.size.width), (lowResImage.size.height))];
    }
    UIGraphicsEndPDFContext();
    
    NSError *attributeserror = nil;
    // Use the NSFileManager to obtain the size of our source file in bytes.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *sourceAttributes = [fileManager  attributesOfItemAtPath:pdfFileName error:&attributeserror];
    NSNumber *sourceFileSize= [sourceAttributes objectForKey:NSFileSize];
    long long fileSize = [sourceFileSize longLongValue];
    NSString *displayFileSize = [NSByteCountFormatter stringFromByteCount:fileSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    NSLog(@"Display file size: %@", displayFileSize);
    
    NSUserDefaults *savePathForPdf = [NSUserDefaults standardUserDefaults];
    [savePathForPdf setObject:pdfFileName forKey:@"savedPathForPdf"];
    [savePathForPdf synchronize];
    
    
    
    return pdfFileName;
    
    
    ////////////////////////////////////////////////////////
    //    QLPreviewController *previewController=[[QLPreviewController alloc]init];
    //    previewController.delegate=self;
    //    previewController.dataSource=self;
    // [self presentModalViewController:previewController animated:YES];
    
    //    [self presentViewController:previewController animated:YES completion:nil];
    //    [previewController.navigationItem setRightBarButtonItem:nil];
    
    
    //    NSData *data = [[NSData alloc]initWithContentsOfFile:pdfFileName];
    ////    // from your converted Base64 string
    ////    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    ////    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"test.pdf"];
    //    [data writeToFile:pdfFileName atomically:YES];
    ////
    //    MuDocRef *doc;
    //
    //    doc = [[MuDocRef alloc] initWithFilename:pdfFileName];
    //    if (!doc) {
    //        NSLog(@"Cannot open document '%@'", pdfFileName);
    //        //return YES;
    //    }
    //
    //
    //   // return pdfFileName;
    //    //PreviewImageAsPdf *passimages = [[PreviewImageAsPdf alloc]initWithNibName:@"PreviewImageAsPdf" bundle:nil];
    //    PreviewImageAsPdf *temp = [[PreviewImageAsPdf alloc] initWithFilename:pdfFileName path:pdfFileName document: doc];
    //
    //    temp.pdfPath = pdfFileName;
    //    [self.navigationController pushViewController:temp animated:YES];
}

-(void) sendDataToShowEdit:(NSMutableArray *)addImages
{
    [_showMultImages addObject:addImages];
    [_showMultipleImages reloadData];
    
    
}

-(void) imageupdater:(NSMutableArray *)ImageArray
{
    
}


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:picker completion:nil];
    UIImage* imag = [info valueForKey:UIImagePickerControllerOriginalImage];
    UIImageView *  imageView ;
    imageView.image = imag;
    NSDictionary *metadataDictionary = (NSDictionary *)[info valueForKey:UIImagePickerControllerMediaMetadata];
    
    meta = [[[info objectForKey:UIImagePickerControllerMediaMetadata] objectForKey:@"{TIFF}"] objectForKey:@"DateTime"];
    
    if (meta == nil) {
        NSDateFormatter *form = [[NSDateFormatter alloc] init];
        form.dateFormat = @"yyyy:MM:dd HH:mm:ss";
        NSString* date = [form stringFromDate:[NSDate date]];
        [_showMultImages addObject:@{@"Image":imag,@"Date":date}];
    }
    else
    {
        [_showMultImages addObject:@{@"Image":imag,@"Date":meta}];
    }
    
    //[_showMultipleImages reloadData];
    
    if (imag != nil) {
        UIStoryboard *newStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        PreviewerController *objTrackOrderVC= [newStoryBoard instantiateViewControllerWithIdentifier:@"PreviewerController"];
        objTrackOrderVC.Previewimg = imag;
        objTrackOrderVC.categoryname = self.categoryname;
        objTrackOrderVC.documentName = self.documentName;
        objTrackOrderVC.sourceImageArray =_showMultImages;
        objTrackOrderVC.imageupdateDelegate = self;
        [self.navigationController pushViewController:objTrackOrderVC animated:YES];
    }
    
    
}


#pragma mark - tableview delegates and datasource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (_showMultImages.count > 1) {
        self.showMultipleImages.hidden = false;
    }
    else{
        self.showMultipleImages.hidden = true;
        
    }
    return _showMultImages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    MultipleImagesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MultipleImagesCell" forIndexPath:indexPath];
    
    [self.showImageFromListView setImage:[[_showMultImages objectAtIndex:indexPath.row]valueForKey:@"Image"]];
    for(int i=0; i<[_showMultImages count];i++) {
        cell.imagesMultiple.image = [[_showMultImages objectAtIndex:indexPath.row]valueForKey:@"Image"];
        
    }
    cell.imageCount.text = [NSString stringWithFormat:@"%ld. ",(long)indexPath.row+1];
    
    return cell;
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 150;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // ShowPdfForImages.h
    
    NSLog(@"%ld",(long)indexPath.row);
    
    MWPhoto *photo;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = NO;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    
    [_showMultipleImages deselectRowAtIndexPath:indexPath animated:YES];
    _imagesArray = [[NSMutableArray alloc]init];
    
    for (int i =0 ; i<_showMultImages.count; i++) {
        photo = [MWPhoto photoWithImage:[[_showMultImages objectAtIndex:i]valueForKey:@"Image"]];
        [_imagesArray addObject:photo];
    }
    
    //startOnGrid = YES;
    displayNavArrows = YES;
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    [browser setCurrentPhotoIndex:0];
    //browser.currentIndex = i
    // browser.currentIndex = indexPath.row;
    [self.navigationController pushViewController:browser animated:YES];
    
    //    NSString* path = [self createPDFWithImagesArray:_imagesArray andFileName:@"Images"];
    //
    //
    //    ShowPdfForImages *objTrackOrderVC= [[ShowPdfForImages alloc] initWithNibName:@"ShowPdfForImages" bundle:nil];
    //    objTrackOrderVC.imgPdfString = path;
    //    [self.navigationController pushViewController:objTrackOrderVC animated:YES];
    
    //    MuDocRef *doc;
    //
    //    doc = [[MuDocRef alloc] initWithFilename:path];
    //    if (!doc) {
    //        NSLog(@"Cannot open document '%@'", path);
    //        //return YES;
    //    }
    //
    //    ShowPdfForImages *objTrackOrderVC= [[ShowPdfForImages alloc] initWithFilename:path path:path document:doc];
    //    objTrackOrderVC.imgPdfString = path;
    //    [self.navigationController pushViewController:objTrackOrderVC animated:YES];
}

- (NSString*)createPDFWithImagesArray:(NSMutableArray *)array andFileName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *PDFPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdf",fileName]];
    
    // CGRect rect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginPDFContextToFile(PDFPath, CGRectZero, nil);
    for (UIImage *image in array)
    {
        
        // Mark the beginning of a new page.
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height), nil);
        
        [image drawInRect:CGRectMake(0, 0,  self.view.frame.size.width,  self.view.frame.size.height)];
    }
    UIGraphicsEndPDFContext();
    
    return PDFPath;
}

//-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
//
//        [self tableView:self.showMultipleImages commitEditingStyle: UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
//        //        [self.heartCartTabel deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }];
//
//    return @[deleteAction];
//}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_showMultImages removeObjectAtIndex:indexPath.row];
        //  [_showImageFromListView setImage:[[_showMultImages objectAtIndex:0]valueForKey:@"Image"]];
        
        [tableView reloadData]; // tell table to refresh now
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Index,%ld",(long)indexPath.row);
    if (indexPath.row == [self.showMultImages count]) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSArray *item = [self.showMultImages objectAtIndex:fromIndexPath.row];
    
    
    [self.showMultImages removeObjectAtIndex:fromIndexPath.row];
    [self.showMultImages insertObject:item atIndex:toIndexPath.row];
    [tableView reloadData];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if ([proposedDestinationIndexPath row] < [self.showMultImages count]) {
        return proposedDestinationIndexPath;
    }
    NSIndexPath *betterIndexPath = [NSIndexPath indexPathForRow:[self.showMultImages count]-1 inSection:0];
    return betterIndexPath;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (IBAction)preview:(id)sender {
    [self createPdfWithName:@"sam" array:[NSArray arrayWithArray:_showMultImages]];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _imagesArray.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _imagesArray.count)
        return [_imagesArray objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _imagesArray.count)
        return [_imagesArray objectAtIndex:index];
    return nil;
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - data source(Preview)

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    //return [_showMultImages count];
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSString *fileName = pdfFileName;//[_showMultImages objectAtIndex:index];
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



@end