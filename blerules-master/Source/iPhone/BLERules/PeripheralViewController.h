#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

/// Displays information about the connected peripheral.
///
/// View the implementation for more details. This class is heavily commented for demo
/// purposes.
///
@interface PeripheralViewController : UITableViewController

#pragma mark - Properties

/// The peripheral to display information about.
///
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *InfoLable;
@property (weak, nonatomic) IBOutlet UISlider *ThreshHoldSlider;
@property (weak, nonatomic) IBOutlet UILabel *TheshHoldLabel;

@end
