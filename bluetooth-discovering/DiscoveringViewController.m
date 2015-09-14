//
//  ViewController.m
//  bluetooth-discovering
//
//  Created by Alex Rudyak on 9/14/15.
//  Copyright © 2015 *instinctools. All rights reserved.
//

#import "DiscoveringViewController.h"
#import "ConnectingViewController.h"
@import CoreBluetooth;

static NSString *const kDefaultCellId = @"DefaultCellId";
static NSString *const kConnectingSegueIdentifier = @"Services";

@interface DiscoveringViewController () <UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) CBCentralManager *centralManager;

@end

@implementation DiscoveringViewController {
    NSMutableDictionary *_discoveredDevices;
    UIRefreshControl *_refreshControl;
    NSTimer *_discoveryTimer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(discoverAction:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:_refreshControl];

    _discoveredDevices = [NSMutableDictionary new];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    _discoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(stopDiscoveringTimerAction:) userInfo:nil repeats:NO];
}

- (void)prepareForSegue:(nonnull UIStoryboardSegue *)segue sender:(nullable CBPeripheral *)sender
{
    if ([segue.identifier isEqualToString:kConnectingSegueIdentifier]) {
        ConnectingViewController *destinationController = segue.destinationViewController;
        destinationController.centralManager = self.centralManager;
        destinationController.peripheral = sender;

        [_discoveryTimer fire];
    }
}

- (void)discoverAction:(id)sender
{
    //todo: discover
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    [_discoveredDevices removeAllObjects];
    [_refreshControl beginRefreshing];

    if ([_discoveryTimer isValid]) {
        [_discoveryTimer invalidate];
    }
    _discoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(stopDiscoveringTimerAction:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_discoveryTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - Timer

- (void)stopDiscoveringTimerAction:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.centralManager stopScan];
        [_refreshControl endRefreshing];
    });
}

#pragma mark - UITableViewDelegate

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
//    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CBPeripheral *peripheral = [_discoveredDevices allValues][indexPath.row];
    // load services
    [self.centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellId];
    CBPeripheral *peripheral = [_discoveredDevices allValues][indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@:%@", peripheral.name, peripheral.identifier.UUIDString];

    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_discoveredDevices count];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"%@ - updateState", NSStringFromClass([central class]));
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@ - peripheral discovered", peripheral.identifier.UUIDString);
    [_discoveredDevices setObject:peripheral forKey:peripheral.identifier.UUIDString];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });

    if ([_discoveryTimer isValid]) {
        [_discoveryTimer invalidate];
    }
    _discoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(stopDiscoveringTimerAction:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_discoveryTimer forMode:NSDefaultRunLoopMode];
}

- (void)centralManager:(nonnull CBCentralManager *)central didConnectPeripheral:(nonnull CBPeripheral *)peripheral
{
    NSLog(@"Success to connect - %@", peripheral.identifier.UUIDString);

    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:kConnectingSegueIdentifier sender:peripheral];
    });
}

- (void)centralManager:(nonnull CBCentralManager *)central didFailToConnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Failed to connect - %@", peripheral.identifier.UUIDString);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"Disconnected - %@", peripheral.identifier.UUIDString);
}

@end
