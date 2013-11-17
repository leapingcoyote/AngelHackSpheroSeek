#import <CoreBluetooth/CoreBluetooth.h>
#import "MainViewController.h"
#import "PeripheralViewController.h"
#import "PeripheralCell.h"

/// Private interface for MainViewController.
///
@interface MainViewController () <CBCentralManagerDelegate>

#pragma mark - Properties

/// Our central manager instance.
///
@property (nonatomic, strong) CBCentralManager *central;

/// Maintains a reference to the currently connected peripheral. This value is nil if no
/// peripheral is connected.
///
@property (nonatomic, strong) CBPeripheral *connectedPeripheral;

/// Tracks BLE peripherals discovered while scanning.
///
@property (nonatomic, strong) NSMutableArray *peripherals;

/// Indicates whether or not the central is currently scanning.
///
@property (nonatomic, assign) BOOL scanning;

#pragma mark - Actions

/// Invoked when the "Scan" switch is toggled on or off. Note that toggling the switch is
/// not allowed when a peripheral is connected or connected.
///
- (IBAction)didToggleScanSwitch:(id)sender;

@end

@implementation MainViewController

#pragma mark - Init and dealloc

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self)
    {
        // Create our central instance when this object is initialized. The queue: param
        // can be a custom dispatch queue, but we'll leave it nil so the central uses the
        // main queue.

        _central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _peripherals = [NSMutableArray array];
        _scanning = NO;
    }

    return self;
}

#pragma mark - Actions

- (IBAction)didToggleScanSwitch:(id)sender
{
    UISwitch *scanSwitch = sender;

    if (self.connectedPeripheral != nil)
    {
        // Don't allow toggling the switch when a connection is in progress.
        [scanSwitch setOn:NO animated:YES];

        return;
    }

    if (scanSwitch.on == YES)
    {
        // We can only start a scan if the Bluetooth radio is powered on. Otherwise, we'll
        // display an alerty message about the failure. In a real (non-demo) app, we
        // should give the user more info about the failure based on the current state.

        if (self.central.state == CBCentralManagerStatePoweredOn)
        {
            // Note that we're not specifying services here, but Apple recommends
            // we do. In fact, scanning while your app is in the background
            // won't work unless you specifiy services.

            [self.central scanForPeripheralsWithServices:nil options:nil];
            self.scanning = YES;
            DLog(@"Started scanning");
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:@"Can't Scan"
                                        message:@"Scanning failed due to unsupported CBCentralManagerState."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];

            scanSwitch.on = NO;
        }
    }
    else
    {
        [self.central stopScan];
        self.scanning = NO;
        DLog(@"Stopped scanning");
    }

    // The tableView's cells change state based on whether we're currently scanning or
    // not, so refresh the tableView.

    [self.tableView reloadData];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // In this demo app, we just log the state of the Bluetooth radio, but we could
    // display a message or otherwise alert the user when the state is anything other
    // than CBCentralManagerStatePoweredOn.

    NSString *stateString = nil;

    switch (central.state)
    {
        case CBCentralManagerStateUnknown:
            stateString = @"Unknown";
            break;

        case CBCentralManagerStateResetting:
            stateString = @"Resetting";
            break;

        case CBCentralManagerStateUnsupported:
            stateString = @"Unsupported";
            break;

        case CBCentralManagerStateUnauthorized:
            stateString = @"Unauthorized";
            break;

        case CBCentralManagerStatePoweredOff:
            stateString = @"Powered Off";
            break;

        case CBCentralManagerStatePoweredOn:
            stateString = @"Powered On";
            break;
    }

    DLog(@"State: %@", stateString);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Only add this peripheral to our array if we haven't already received a notification
    // about it. Even though we haven't enabled duplicates, we're still not guarenteed
    // that the same peripheral won't show up more than once.

    if ([self.peripherals containsObject:peripheral] == NO)
    {
        DLog(@"Found peripheral: %@", peripheral);

        [self.peripherals addObject:peripheral];

        NSInteger row = self.peripherals.count - 1;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];

        [self.tableView insertRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    DLog(@"Connected to peripheral: %@", peripheral);

    // Display the detail view for this peripheral. Note that the detail view will
    // automatically be popped when the connection is lost.

    [self performSegueWithIdentifier:@"ShowPeripheralViewController" sender:self];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.connectedPeripheral = nil;

    [[[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];

    // Turn off the activity indicator for this tableView row.

    NSUInteger row = [self.peripherals indexOfObject:peripheral];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];
    PeripheralCell *cell = (PeripheralCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.activityIndicatorView stopAnimating];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    DLog(@"Disconnected from peripheral: %@", peripheral);

    // We should check to make sure that this notification is related to the peripheral
    // that we're connected to. In a simple app like this, it always will be, but it's a
    // good idea to check before making any changes to the view state.

    if (self.connectedPeripheral == peripheral)
    {
        if (self.navigationController.topViewController != self)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }

        self.connectedPeripheral = nil;

        // Turn off the activity indicator for this tableView row.

        NSUInteger row = [self.peripherals indexOfObject:peripheral];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:1];
        PeripheralCell *cell = (PeripheralCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell.activityIndicatorView stopAnimating];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // First section has the "Scan" switch.
    // Second section lists found peripherals.

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1; // First group has a single row for the "Scan" swich.
    }
    else
    {
        return self.peripherals.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeripheralCell *cell = nil;

    if (indexPath.section == 0)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ScanCell"
                                                    forIndexPath:indexPath];

        if (self.scanning == YES)
        {
            [cell.activityIndicatorView startAnimating];
        }
    }
    else
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"PeripheralCell"
                                                    forIndexPath:indexPath];

        CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
        cell.nameLabel.text = peripheral.name;

        if (self.scanning == NO && self.connectedPeripheral == nil)
        {
            cell.nameLabel.textColor = [UIColor blackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        else
        {
            cell.nameLabel.textColor = [UIColor lightGrayColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only allow tapping on peripherals. Also, only allow tapping on a row when we're not
    // actively scanning or connecting/connected to a peripheral.

    if (indexPath.section == 1
        && self.scanning == NO
        && self.connectedPeripheral == nil)
    {
        CBPeripheral *peripheral = [self.peripherals objectAtIndex:indexPath.row];
        [self.central connectPeripheral:peripheral options:nil];

        // Set this now to prevent the user from tapping on more than one peripheral at
        // once. If the connection fails, we'll set this back to nil.
        self.connectedPeripheral = peripheral;

        PeripheralCell *cell = (PeripheralCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell.activityIndicatorView startAnimating];
    }
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowPeripheralViewController"])
    {
        // Is anyone even reading these comments? I spent a lot of time on this, people!

        PeripheralViewController *peripheralViewController = segue.destinationViewController;
        peripheralViewController.peripheral = self.connectedPeripheral;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];

    if (selectedIndexPath)
    {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:animated];
    }

    // Most likely reason this view is appearing is because the user tapped the back
    // button from the peripheral detail view. The detail view doesn't have a reference
    // to central by design, so we disconnect here.

    if (self.connectedPeripheral)
    {
        [self.central cancelPeripheralConnection:self.connectedPeripheral];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Replace the default table view background image with the custom version.

    UIImage *backgroundImage = [UIImage imageNamed:@"Background"];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.contentMode = UIViewContentModeCenter;
    backgroundImageView.frame = self.tableView.bounds;

    self.tableView.backgroundView = backgroundImageView;
}

@end
