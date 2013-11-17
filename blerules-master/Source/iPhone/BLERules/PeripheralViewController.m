#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "PeripheralViewController.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"
#import "RobotBrain2.h"


#define WRITE_RSSI
//#define WRITE_TWEETS

// These UUID values are defined by the creator of the BLE-Shield:
// http://www.mkroll.mobi/?page_id=681
//
NSString * const BLEShieldServiceUUIDString = @"f9266fd7-ef07-45d6-8eb6-bd74f13620f9";
NSString * const BLEShieldCharacteristicRXUUIDString = @"4585c102-7784-40b4-88e1-3cb5c4fd37a3";
NSString * const BLEShieldCharacteristicTXUUIDString = @"e788d73b-e793-4d9e-a608-2f2bafc59a00";

// This is the Twitter "track" parameter. Refer to Twitter's docs for details:
// https://dev.twitter.com/docs/streaming-apis/parameters#track
//
NSString * const TwitterTrackParam = @"#blerules";

// How often we read the RSSI value from the peripheral.
//
NSTimeInterval const RSSIUpdateInterval = 0.1;

// Consts to define the locations of static cells displayed in this table view.
//
NSInteger const NameCellRow = 0;
NSInteger const RSSICellRow = 1;
NSInteger const MessageCellRow = 2;
NSInteger const TweetCountRow = 3;

/// Private interface for PeripheralViewController.
///
@interface PeripheralViewController ()  <CBPeripheralDelegate>

#pragma mark - Properties

/// Timer that determines when the RSSI value is read from the peripheral. We'll request
/// an RSSI update every time this timer fires.
///
@property (nonatomic, strong) NSTimer *RSSITimer;

/// Keeps track of the tweet count for tweets that match TwitterTrackParam. Note that the
/// tweet count displayed in the table view is automatically updated when this value is
/// changed.
///
@property (nonatomic, assign) NSInteger tweetCount;

/// Connection used to open a stream to Twitter and monitor TwitterTrackParam.
///
@property (nonatomic, strong) NSURLConnection *twitterConnection;

/// Keeps a reference to the BLE-Sheild TX characteristic, so we can refer to it later
/// without looping through all of the charachteristics of the BLE-Shield profile.
///
@property (nonatomic, strong) CBCharacteristic *TXCharacteristic;

#pragma mark - Outlets

/// Displays the last message we've received from the BLE-Shield peripheral by monitoring
/// the RX characteristic.
///
@property (nonatomic, weak) IBOutlet UILabel *messageLabel;

/// Displays the name of the peripheral.
///
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

/// Displays the current RSSI reading from the peripheral.
///
@property (nonatomic, weak) IBOutlet UILabel *RSSILabel;

/// Displays the current number of tweets received from our streaming twitter connection.
///
@property (nonatomic, weak) IBOutlet UILabel *tweetCountLabel;
@property (strong, nonatomic) RobotBrain2 *robotBrain;

#pragma mark - Private methods

/// Invoked by the timer every RSSIUpdateInterval.
///
/// @param timer
///     The timer that triggered this event. (Always RSSITimer.)
///
- (void)RSSITimerDidFire:(NSTimer *)timer;

/// Starts monitoring Twitter for tweets that match TwitterTrackParam. Note that this
/// method will return immediately if there are no Twitter accounts available on the
/// system.
///
- (void)startTwitterStreamWithAccount:(ACAccount *)account;

@end

@implementation PeripheralViewController

@synthesize robotBrain;
@synthesize InfoLable;
@synthesize ThreshHoldSlider;
@synthesize TheshHoldLabel;

BOOL robotOnline;

#pragma mark - Init and dealloc

- (void)dealloc
{
    // We don't want to receive any delete messages after we're deallocated.

    if (_peripheral.delegate == self)
    {
        _peripheral.delegate = nil;
    }
}

#pragma mark - peripheral accessor methods

- (void)setPeripheral:(CBPeripheral *)peripheral
{
    // Automatically set this instance up as the delegate of a peripheral as soon as it's
    // assigned.

    if (_peripheral != peripheral)
    {
        if (_peripheral.delegate == self)
        {
            _peripheral.delegate = nil;
        }

        _peripheral = peripheral;
        _peripheral.delegate = self;
    }
}

#pragma mark - tweetCount accessor methods

- (void)setTweetCount:(NSInteger)tweetCount
{
    _tweetCount = tweetCount;

    // Refresh the table view with the latest count.

    self.tweetCountLabel.text = [NSString stringWithFormat:@"%d", _tweetCount];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TweetCountRow inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];

#ifdef WRITE_TWEETS
    // If we're connected to the BLE-Shield and have a reference to the TX characteristic,
    // then take this opportunity to write a new value to the BLE-Shield. In the live
    // demo, this will update the LCD display on the BLE-Shield with the tweet count.

    if (self.TXCharacteristic)
    {
        NSString *tweetCountString = [NSString stringWithFormat:@"%d\n", _tweetCount];
        NSData *data = [tweetCountString dataUsingEncoding:NSASCIIStringEncoding];

        [self.peripheral writeValue:data
                  forCharacteristic:self.TXCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }
#endif
}

#pragma mark - Private methods

- (void)RSSITimerDidFire:(NSTimer *)timer
{
    // Request an RSSI update, so we can display the latest value. See
    // peripheralDidUpdateRSSI:error: below.

    [self.peripheral readRSSI];
}

- (void)startTwitterStreamWithAccount:(ACAccount *)account
{
    if (account == nil)
    {
        DLog(@"A Twitter account is required");
        return;
    }

    NSURL *URL = [NSURL URLWithString:@"https://stream.twitter.com/1.1/statuses/filter.json"];

    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:URL
                                               parameters:@{ @"track": TwitterTrackParam }];

    request.account = account;

    self.twitterConnection = [NSURLConnection connectionWithRequest:request.preparedURLRequest
                                                           delegate:self];

    [self.twitterConnection start];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    DLog(@"%@", peripheral.services);

    for (CBService *service in peripheral.services)
    {
        [self.peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    DLog(@"%@", service.characteristics);

    // We need to transform our string UUIDs into CBUUIDs for use with CBPeripheral.

    CBUUID *serviceUUID = [CBUUID UUIDWithString:BLEShieldServiceUUIDString];
    CBUUID *characteristicRXUUID = [CBUUID UUIDWithString:BLEShieldCharacteristicRXUUIDString];
    CBUUID *characteristicTXUUID = [CBUUID UUIDWithString:BLEShieldCharacteristicTXUUIDString];

    if ([service.UUID isEqual:serviceUUID])
    {
        for (CBCharacteristic *characteristic in service.characteristics )
        {
            if ([characteristic.UUID isEqual:characteristicRXUUID])
            {
                // This is the RX characteristic on the BLE-Sheild. Request to be notified
                // when the RX value changes.
                [self.peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            else if ([characteristic.UUID isEqual:characteristicTXUUID])
            {
                // This is the TX chacteristic on the BLE-Shield. Keep track of this, so
                // we can use it to write a value to this characteristic later.
                self.TXCharacteristic = characteristic;
            }
        }
    }

    // As soon as we discover any characteristics, we can start monitoring Twitter for
    // tweets. Note that this code checks the list of Twitter accounts on the OS and tries
    // to start monitoring Twitter with the first account in the list.

    if (self.twitterConnection == nil)
    {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

        [accountStore requestAccessToAccountsWithType:accountType
                                              options:nil
                                           completion:^(BOOL granted, NSError *error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                                                   ACAccount *account = [accounts objectAtIndex:0];
                                                   [self startTwitterStreamWithAccount:account];
                                               });
                                           }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{


    // This method is invoked when the peripheral sends a notification that there's new
    // data to read on the RX characteristic. Update the message label with the new value.

    DLog(@"Received characteristic notification: %@", characteristic);

    NSString *valueString = [[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding];
    self.messageLabel.text = valueString;

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:MessageCellRow inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    // The peripheral invokes this method when it has a new RSSI value to share.
    [self.robotBrain go:peripheral withFoo:InfoLable usingThreshHoldSlider:ThreshHoldSlider];
    DLog(@"%@", self.peripheral.RSSI);

    self.RSSILabel.text = [NSString stringWithFormat:@"%@", self.peripheral.RSSI];

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:RSSICellRow inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];

#ifdef WRITE_RSSI
    // If we're connected to the BLE-Shield and have a reference to the TX characteristic,
    // then take this opportunity to write a new value to the BLE-Shield. In the live
    // demo, this will update the LCD display on the BLE-Shield with the RSSI.

    if (self.TXCharacteristic)
    {
        NSInteger absoluteRSSI = abs([self.peripheral.RSSI integerValue]);
        NSString *RSSIString = [NSString stringWithFormat:@"%d\n", absoluteRSSI];
        NSData *data = [RSSIString dataUsingEncoding:NSASCIIStringEncoding];

        [self.peripheral writeValue:data
                  forCharacteristic:self.TXCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }
#endif
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Data from the Twitter stream comes in as a single JSON object.

    NSError *error = nil;
    id tweet = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error == nil)
    {
        if ([tweet isKindOfClass:[NSDictionary class]] && [tweet objectForKey:@"disconnect"] == nil)
        {
            // This is a new, legit tweet. Count it and update the tweet count via the
            // accessor method for tweetCount above called setTweetCount:.

            DLog(@"Tweet: %@", [tweet objectForKey:@"text"]);
            self.tweetCount += 1;
        }
    }
    else
    {
        // Sometimes the stream sends a blank value to keep the connection alive.

        DLog(@"JSON parsing error: %@", error);
        DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // This is for demo purposes only. We all want to handle situations like this nicely
    // in a production app.

    DLog(@"Twitter connection error: %@", error);
}

#pragma mark - UIViewController

- (void)handleRobotOnline {
    /*The robot is now online, we can begin sending commands*/
    
    robotOnline = YES;
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
        [self setupRobotConnection];
    robotOnline = NO;
    
    self.robotBrain = [[RobotBrain2 alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Now that we're connected, we can start reading the RSSI value from the peripheral.

    self.RSSITimer = [NSTimer scheduledTimerWithTimeInterval:RSSIUpdateInterval
                                                  target:self
                                                selector:@selector(RSSITimerDidFire:)
                                                userInfo:nil
                                                 repeats:YES];

    [self.peripheral discoverServices:nil];

    if (self.peripheral.name && self.peripheral.name.length > 0)
    {
        self.nameLabel.text = self.peripheral.name;
    }
    else
    {
        self.nameLabel.text = @"Unknown";
    }

    self.RSSILabel.text = @"";
    self.messageLabel.text = @"";
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.RSSITimer invalidate];
    [self.twitterConnection cancel];

    [super viewDidDisappear:animated];
}

-(void)moveRobot {
    [RKRollCommand sendCommandWithHeading:270.0 velocity:0.9];
}

- (IBAction)onThreshHoldSliderValueChanged:(UISlider *)sender forEvent:(UIEvent *)event {
    TheshHoldLabel.text = [NSString stringWithFormat:@"%f",ThreshHoldSlider.value];

}

-(void)stopRobot {
    //The sendStop method sends a roll command with zero velocity and the last heading to make Sphero stop
    [RKRollCommand sendStop];
}

-(void)setupRobotConnection {
    /*Try to connect to the robot*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];
    if ([[RKRobotProvider sharedRobotProvider] isRobotUnderControl]) {
        [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    }
}

@end
