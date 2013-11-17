#import <UIKit/UIKit.h>

/// Custom table view cell that displays peripherals and an activity indicator. The
/// activity indicator is displayed when connecting.
///
/// View the implementation for more details. This class is heavily commented for demo
/// purposes.
///
@interface PeripheralCell : UITableViewCell

#pragma mark - Outlets

/// Name of the peripheral.
///
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

/// Activity indicator to display when connecting to this peripheral.
///
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
