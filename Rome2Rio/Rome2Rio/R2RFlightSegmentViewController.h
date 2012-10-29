//
//  R2RFlightSegmentViewController.h
//  Rome2Rio
//
//  Created by Ash Verdoorn on 14/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "R2RDataController.h"
//#import "R2RFlightSegment.h"
////#import "R2RSpriteStore.h"


@interface R2RFlightSegmentViewController : UITableViewController <UIActionSheetDelegate>// <R2RAirlineIconLoaderDelegate>

@property (strong, nonatomic) R2RDataController *dataController;
@property (strong, nonatomic) R2RRoute *route;
@property (strong, nonatomic) R2RFlightSegment *flightSegment;

- (IBAction)ReturnToSearch:(id)sender;
-(void) sortFlightSegment;

@end
