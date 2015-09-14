//
//  DiscoveringViewController.m
//  bluetooth-discovering
//
//  Created by Alex Rudyak on 9/14/15.
//  Copyright © 2015 *instinctools. All rights reserved.
//

#import "ConnectingViewController.h"
@import CoreBluetooth;

static NSString *const kDefaultCellId = @"DefaultCellId";

@interface ConnectingViewController () <UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ConnectingViewController {
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.peripheral services][section] characteristics] count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellId];
    CBService *service = [self.peripheral services][indexPath.section];
    CBCharacteristic *characteristic = service.characteristics[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - (%@)", characteristic.UUID.UUIDString, characteristic.value ?: @"No Value"];

    return cell;
}

- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [[self.peripheral services][section] UUID].UUIDString;
}

#pragma mark - CBPeripheralDelegate

- (NSInteger)numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return [[self.peripheral services] count];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSLog(@"%@ - discovered services", peripheral.identifier.UUIDString);

    self.peripheral = peripheral;
    if (!error) {
        for (CBService *service in peripheral.services) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    NSLog(@"%@ - discovered characteristics", service.UUID.UUIDString);

    NSUInteger serviceIndex = [[peripheral services] indexOfObjectPassingTest:^BOOL(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.UUID isEqual:service.UUID];
    }];

    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral readValueForCharacteristic:characteristic];
    }

    if (serviceIndex != NSNotFound) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:serviceIndex] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (void)cancelPeripheralConnection:(CBPeripheral *)peripheral
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSUInteger serviceIndex = [[peripheral services] indexOfObjectPassingTest:^BOOL(CBService * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [obj.UUID isEqual:characteristic.service.UUID];
    }];
    if (serviceIndex != NSNotFound) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:serviceIndex] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

@end
