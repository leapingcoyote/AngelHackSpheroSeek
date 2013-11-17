//
//  RobotBrain.h
//  SensorTagEX
//
//  Created by Craig Slagel on 2013-11-16.
//  Copyright (c) 2013 Texas Instruments. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeripheralViewController.h"

@interface RobotBrain2 : NSObject

@property (strong,nonatomic) CBPeripheral *p;
@property (strong,nonatomic) UILabel *foobar;

-(void)go:(CBPeripheral *)peripheral withFoo:(UILabel *)foo;

@end
