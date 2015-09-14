//
//  DiscoveringViewController.h
//  bluetooth-discovering
//
//  Created by Alex Rudyak on 9/14/15.
//  Copyright © 2015 *instinctools. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CBCentralManager, CBPeripheral;

@interface ConnectingViewController : UIViewController

@property (nonatomic, weak) CBCentralManager *centralManager;

@property (nonatomic, strong) CBPeripheral *peripheral;

@end
