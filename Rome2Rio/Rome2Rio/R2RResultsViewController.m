//
//  R2RResultsViewController.m
//  R2RApp
//
//  Created by Ash Verdoorn on 6/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import "R2RResultsViewController.h"
#import "R2RDetailViewController.h"
#import "R2RTransitSegmentViewController.h"
#import "R2RWalkDriveSegmentViewController.h"

#import "R2RStatusButton.h"
#import "R2RResultSectionHeader.h"
#import "R2RResultsCell.h"
#import "R2RStringFormatters.h"
#import "R2RSegmentHandler.h"
#import "R2RSprite.h"

#import "R2RAirport.h"
#import "R2RAirline.h"
#import "R2RRoute.h"
#import "R2RWalkDriveSegment.h"
#import "R2RTransitSegment.h"
#import "R2RTransitItinerary.h"
#import "R2RTransitLeg.h"
#import "R2RTransitHop.h"
#import "R2RFlightSegment.h"
#import "R2RFlightItinerary.h"
#import "R2RFlightLeg.h"
#import "R2RFlightHop.h"
#import "R2RFlightTicketSet.h"
#import "R2RFlightTicket.h"
#import "R2RPosition.h"

@interface R2RResultsViewController ()

@property (strong, nonatomic) R2RResultSectionHeader *header;
@property (strong, nonatomic) R2RStatusButton *statusButton;

enum {
    stateEmpty = 0,
    stateEditingDidBegin,
    stateEditingDidEnd,
    stateResolved,
    stateLocationNotFound,
    stateError
};

enum R2RState
{
    IDLE = 0,
    RESOLVING_FROM,
    RESOLVING_TO,
    SEARCHING,
};

@end

@implementation R2RResultsViewController

@synthesize dataController;
//@synthesize searchResponse, fromSearchPlace, toSearchPlace;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTitle:) name:@"refreshTitle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshResults:) name:@"refreshResults" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStatusMessage:) name:@"refreshStatusMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSearchMessage:) name:@"refreshSearchMessage" object:nil];
    
    [self.tableView setSectionHeaderHeight:37.0];
    CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.tableView.sectionHeaderHeight);
    
    self.header = [[R2RResultSectionHeader alloc] initWithFrame:rect];

    [self refreshResultsViewTitle];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:234.0/256.0 green:228.0/256.0 blue:224.0/256.0 alpha:1.0]];

    self.statusButton = [[R2RStatusButton alloc] initWithFrame:CGRectMake(0.0, (self.view.bounds.size.height- self.navigationController.navigationBar.bounds.size.height-30), self.view.bounds.size.width, 30.0)];
    [self.statusButton addTarget:self action:@selector(statusButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.statusButton];
    
    [self setStatusMessage:self.dataController.statusMessage];

    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
}

- (void)viewDidUnload
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTitle" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshResults" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshStatusMessage" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshSearchMessage" object:nil];
    
//    [self setSearchLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//#warning Incomplete method implementation.
//    // Return the number of rows in the section.
//    return 0;
    
    //return [self.searchResponse.routes count];
    return [self.dataController.search.searchResponse.routes count]; //added plus one to temporarily include the message cell
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor colorWithRed:254.0/256.0 green:248.0/256.0 blue:244.0/256.0 alpha:1.0]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    R2RRoute *route = [self.dataController.search.searchResponse.routes objectAtIndex:indexPath.row];
    R2RSegmentHandler *segmentHandler  = [[R2RSegmentHandler alloc] init];
    NSString *CellIdentifier = @"ResultsCell";
    
    if ([route.segments count] == 1)
    {
        NSString *kind = [segmentHandler getSegmentKind:[route.segments objectAtIndex:0]];
        if ([kind isEqualToString:@"bus"] || [kind isEqualToString:@"train"] || [kind isEqualToString:@"ferry"])
        {
            CellIdentifier = @"ResultsCellTransit";
        }
        else if ([kind isEqualToString:@"car"] || [kind isEqualToString:@"walk"])
        {
            CellIdentifier = @"ResultsCellWalkDrive";
        }
    }
    
    R2RResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
//    [cell setBackgroundColor:[UIColor blueColor]];
    
    
    [cell.resultDescripionLabel setText:route.name];
    
    R2RStringFormatters *formatter = [[R2RStringFormatters alloc] init];
    
    [cell.resultDurationLabel setText:[formatter formatDuration:route.duration]];
    
    
    
    NSInteger iconCount = 0;
    float xOffset = 0;
    for (id segment in route.segments)
    {
        if (iconCount >= 5) break;
        
        if ([segmentHandler getSegmentIsMajor:segment])
        {
            UIImageView *iconView = [cell.icons objectAtIndex:iconCount];
            
            if (xOffset == 0)
            {
                xOffset = iconView.frame.origin.x;
            }
            
            R2RSprite *sprite = [segmentHandler getSegmentResultSprite:segment];
            
            CGRect iconFrame = CGRectMake(xOffset, iconView.frame.origin.y, sprite.size.width, sprite.size.height);
            [iconView setFrame:iconFrame];
            
            [self.dataController.spriteStore setSpriteInView:sprite :iconView];
//            [iconView setImage:icon];
            
            xOffset = iconView.frame.origin.x + iconView.frame.size.width + 7; //xPos of next icon

//            icon.image = [segmentHandler getSegmentResultIcon:segment];
            iconCount++;
        }
    }
    
    cell.iconCount = iconCount;
     
    return cell;
}

//-(UIImage *) getSegmentIcon:(id) segment
//{
//    R2RSegmentHandler *segmentHandler  = [[R2RSegmentHandler alloc] init];
//    
//    UIImage *icon = [segmentHandler getSegmentResultIcon:segment];
//
//    return icon;
//}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    R2RRoute *route = [self.dataController.search.searchResponse.routes objectAtIndex:indexPath.row];
//    if ([route.segments count] == 1)
//    {
//        R2RSegmentHandler *segmentHandler = [[R2RSegmentHandler alloc] init];
//        NSString *kind = [segmentHandler getSegmentKind:[route.segments objectAtIndex:0]];
//        if ([kind isEqualToString:@"bus"] || [kind isEqualToString:@"train"] || [kind isEqualToString:@"ferry"])
//        {
//            R2RTransitSegmentViewController *segmentViewController = [[R2RTransitSegmentViewController alloc] init];// [segue destinationViewController];
//            segmentViewController.dataController = self.dataController;
//            segmentViewController.route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
//            [self.navigationController pushViewController:segmentViewController animated:YES];
//        }
//        else if ([kind isEqualToString:@"car"] || [kind isEqualToString:@"walk"])
//        {
////            [self performSegueWithIdentifier:@"showWalkDriveSegment" sender:self];
//            R2RWalkDriveSegmentViewController *segmentViewController = [[R2RWalkDriveSegmentViewController alloc] init];
//            segmentViewController.dataController = self.dataController;
//            segmentViewController.route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
//            [self.navigationController pushViewController:segmentViewController animated:YES];
//        }
//        else
//        {
//            R2RDetailViewController *detailsViewController = [[R2RDetailViewController alloc] init];
//            detailsViewController.dataController = self.dataController;
//            detailsViewController.route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
//            [self.navigationController pushViewController:detailsViewController animated:YES];
//            [self performSegueWithIdentifier:@"showRouteDetails" sender:self];
//        }
//    }
//    else
//    {
//        R2RDetailViewController *detailsViewController = [[R2RDetailViewController alloc] init];
//        detailsViewController.dataController = self.dataController;
//        detailsViewController.route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
//        [self.navigationController pushViewController:detailsViewController animated:YES];
////        [self performSegueWithIdentifier:@"showRouteDetails" sender:self];
//    }
//    
//
//}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showRouteDetails"])
    {
        R2RDetailViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.dataController = self.dataController;
        detailsViewController.route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    }
    if ([[segue identifier] isEqualToString:@"showTransitSegment"])
    {
        R2RTransitSegmentViewController *segmentViewController = [segue destinationViewController];
        R2RRoute *route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row]; 
        segmentViewController.dataController = self.dataController;
        segmentViewController.route = route;
        segmentViewController.transitSegment = [route.segments objectAtIndex:0];
    }
    if ([[segue identifier] isEqualToString:@"showWalkDriveSegment"])
    {
        R2RWalkDriveSegmentViewController *segmentViewController = [segue destinationViewController];
        R2RRoute *route = [self.dataController.search.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        segmentViewController.dataController = self.dataController;
        segmentViewController.route = route;
        segmentViewController.walkDriveSegment = [route.segments objectAtIndex:0];
    }

}

-(void) statusButtonClicked
{
    [self.navigationController popViewControllerAnimated:true];
}

-(void) refreshResultsViewTitle
{
    
    NSString *from = self.dataController.fromText;
    if (self.dataController.geoCoderFrom.responseCompletionState == stateResolved)
    {
        from = [[NSString alloc] initWithString:self.dataController.geoCoderFrom.geoCodeResponse.place.shortName];
    }
    
    NSString *to = self.dataController.toText;
    if (self.dataController.geoCoderTo.responseCompletionState == stateResolved)
    {
        to = [[NSString alloc] initWithString:self.dataController.geoCoderTo.geoCodeResponse.place.shortName];
    }
    
    NSString *joiner = @" to ";
    CGSize joinerSize = [joiner sizeWithFont:[UIFont systemFontOfSize:17.0]];
    joinerSize.width += 2;
    CGSize fromSize = [from sizeWithFont:[UIFont systemFontOfSize:17.0]];
    CGSize toSize = [to sizeWithFont:[UIFont systemFontOfSize:17.0]];
    
    NSInteger viewWidth = self.view.bounds.size.width;
    NSInteger fromWidth = fromSize.width;
    NSInteger toWidth = toSize.width;
    
    if (fromSize.width+joinerSize.width+toSize.width > viewWidth)
    {
        fromWidth = (fromSize.width/(fromSize.width+toSize.width))*(viewWidth-joinerSize.width);
        toWidth = (fromSize.width/(fromSize.width+toSize.width))*(viewWidth-joinerSize.width);
    }
    
    CGRect fromFrame = self.header.fromLabel.frame;
    fromFrame.size.width = fromWidth;
    fromFrame.origin.x = (viewWidth-(fromWidth+joinerSize.width+toWidth))/2;
    [self.header.fromLabel setFrame:fromFrame];
    
    CGRect joinerFrame = self.header.joinerLabel.frame;
    joinerFrame.size.width = joinerSize.width;
    joinerFrame.origin.x = fromFrame.origin.x + fromFrame.size.width;
    [self.header.joinerLabel setFrame:joinerFrame];
    
    CGRect toFrame = self.header.toLabel.frame;
    toFrame.size.width = toWidth;
    toFrame.origin.x = joinerFrame.origin.x + joinerFrame.size.width;
    [self.header.toLabel setFrame:toFrame];
    
    [self.header.fromLabel setText:from];
    [self.header.toLabel setText:to];
    [self.header.joinerLabel setText:joiner];
    
}

-(void) refreshTitle:(NSNotification *) notification
{
    [self refreshResultsViewTitle];
}

-(void) refreshResults:(NSNotification *) notification
{
    
    //[self configureResultsView];
    
    [self.tableView reloadData];
    
}

-(void) refreshStatusMessage:(NSNotification *) notification
{
    [self setStatusMessage:self.dataController.statusMessage];
    
//    [self.statusButton setTitle:self.dataController.statusMessage forState:UIControlStateNormal];
//    
//    if ([self.dataController.statusMessage length] == 0)
//    {
//        [self.statusButton setHidden:true];
//    }
//    else
//    {
//        [self.statusButton setHidden:false];
//    }
}

-(void) refreshSearchMessage:(NSNotification *) notification
{
    [self setStatusMessage:self.dataController.statusMessage];
}

-(void) setStatusMessage: (NSString *) message
{
    [self.statusButton setTitle:message forState:UIControlStateNormal];
}

- (IBAction)ReturnToSearch:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end