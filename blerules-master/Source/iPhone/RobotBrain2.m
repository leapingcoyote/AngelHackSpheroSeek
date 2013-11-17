//
//  RobotBrain.m
//  SensorTagEX
//
//  Created by Craig Slagel on 2013-11-16.
//  Copyright (c) 2013 Texas Instruments. All rights reserved.
//

#import "RobotBrain2.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"

#define DOUBLE_MOVE_TIME 0.2
#define DOUBLE_VELOCITY 0.6
#define DOUBLE_STOP_WAIT_TIME 1.5
#define STOP_RSSI_MAXIMUM 55

//#define MOVE_TIME_SCALAR_BASELINE 30
//#define MOVE_TIME_SHIFT_BASELINE 20

#define SECONDS_BETWEEN_RSSI_SAMPLES 0.1
#define NUMBER_OF_RSSI_SAMPLES 10

#define MAX_RSSI_RESET_VALUE 1000

@implementation RobotBrain2

@synthesize p;
@synthesize foobar;

double doubleAlfa;
double doubleBravo;

bool boolMoving;

int intAlfaSamples;
int intBravoSamples;

int intZ;

-(id) init {
    self = [super init];
    if (self) {
        boolMoving = NO;
    }
    return self;
}

-(void)stopRobot
{
    NSLog(@"Stopping Robot");
    
    [RKRollCommand sendStop];
}

-(void)go:(CBPeripheral *)peripheral withFoo:(UILabel *)foo
{
    self.p = peripheral;
    self.foobar = foo;
    
    if (boolMoving == NO)
    {
        boolMoving = YES;

        [self gotoRandomZ];
    }
}

-(void)doneZ
{
    [self stopRobot];
    
    NSLog(@"Waiting time for ball to stop before calling GetBravo");
    
    [self performSelector:@selector(getBravo) withObject:nil afterDelay:DOUBLE_STOP_WAIT_TIME];
}

-(void)onGetBravoSample
{
    intBravoSamples++;
    
    double doubleRSSI = fabs(p.RSSI.doubleValue);
    
    if (doubleRSSI < doubleBravo)
    {
        doubleBravo = doubleRSSI;
    }
    
    if (intBravoSamples < NUMBER_OF_RSSI_SAMPLES)
    {
        [self performSelector:@selector(onGetBravoSample) withObject:nil afterDelay:SECONDS_BETWEEN_RSSI_SAMPLES];
    }
    
    else
    {
        self.foobar.text = [NSString stringWithFormat:@"Bravo is %f", doubleBravo];
        
        [self onGotFinalBravo];
    }
}

-(void) onGotFinalBravo
{
    if (doubleBravo > STOP_RSSI_MAXIMUM)
    {
        if (doubleBravo < doubleAlfa)
        {
            self.foobar.text = [NSString stringWithFormat:@"%f, %f, repeating Z %d", doubleAlfa, doubleBravo, intZ];
            
            doubleAlfa = doubleBravo;
            [RKRGBLEDOutputCommand sendCommandWithRed:0 green:1 blue:1];
            [RKRollCommand sendCommandWithHeading:intZ velocity:DOUBLE_VELOCITY];
            
//            [self performSelector:@selector(doneZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME * (doubleBravo - MOVE_TIME_SHIFT_BASELINE) / MOVE_TIME_SCALAR_BASELINE];
            [self performSelector:@selector(doneZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME];
        }
        
        else
        {
            self.foobar.text = [NSString stringWithFormat:@"%f, %f, Backtracking %d", doubleAlfa, doubleBravo, 360 - intZ];
            [RKRGBLEDOutputCommand sendCommandWithRed:1 green:0 blue:0];
            [RKRollCommand sendCommandWithHeading:(360 - intZ) velocity:DOUBLE_VELOCITY];
            
//            [self performSelector:@selector(doneReverseZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME * (doubleBravo - MOVE_TIME_SHIFT_BASELINE) / MOVE_TIME_SCALAR_BASELINE];
            [self performSelector:@selector(doneReverseZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME];
        }
    }
    
    else
    {
        self.foobar.text = [NSString stringWithFormat:@"Found target"];
        
    }
}

-(void) doneReverseZ
{
    [self stopRobot];
    
    NSLog(@"Waiting time for ball to stop before calling GotoRandomZ");

    [self performSelector:@selector(gotoRandomZ) withObject:nil afterDelay:DOUBLE_STOP_WAIT_TIME];
}

-(void)getBravo
{
    NSLog(@"In GetBravo");
    
    intBravoSamples = 0;
    doubleBravo = MAX_RSSI_RESET_VALUE;
    
    [self performSelector:@selector(onGetBravoSample) withObject:nil afterDelay:SECONDS_BETWEEN_RSSI_SAMPLES];
}

-(void)onGotFinalAlfa
{
    intZ = arc4random() % 359;
    
    self.foobar.text = [NSString stringWithFormat:@"Angle Z is: %d", intZ];

    [RKRGBLEDOutputCommand sendCommandWithRed:0 green:1 blue:0];
    [RKRollCommand sendCommandWithHeading:intZ velocity:DOUBLE_VELOCITY];
    
//    [self performSelector:@selector(doneZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME * (doubleAlfa - MOVE_TIME_SHIFT_BASELINE) / MOVE_TIME_SCALAR_BASELINE];
    [self performSelector:@selector(doneZ) withObject:nil afterDelay:DOUBLE_MOVE_TIME];
}

-(void)onGetAlfaSample
{
    intAlfaSamples++;
    
    double doubleRSSI = fabs(p.RSSI.doubleValue);
    
    if (doubleRSSI < doubleAlfa)
    {
        doubleAlfa = doubleRSSI;
    }
    
    if (intAlfaSamples < NUMBER_OF_RSSI_SAMPLES)
    {
        [self performSelector:@selector(onGetAlfaSample) withObject:nil afterDelay:SECONDS_BETWEEN_RSSI_SAMPLES];
    }
    
    else
    {
        self.foobar.text = [NSString stringWithFormat:@"Alfa is %f", doubleAlfa];
        
        [self onGotFinalAlfa];
    }
}

-(void)gotoRandomZ
{
    NSLog(@"In GotoRandomZ");

    intAlfaSamples = 0;
    doubleAlfa = MAX_RSSI_RESET_VALUE;
    
    [self performSelector:@selector(onGetAlfaSample) withObject:nil afterDelay:SECONDS_BETWEEN_RSSI_SAMPLES];
}

@end