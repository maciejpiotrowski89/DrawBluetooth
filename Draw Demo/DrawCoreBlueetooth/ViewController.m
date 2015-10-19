//
//  ViewController.m
//  DrawCoreBlueetooth
//
//  Created by Maciej Piotrowski on 04/10/14.
//  Copyright (c) 2014 Maciej Piotrowski All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"

NSString * const kDrawingService = @"DC81A43C-DB4F-439C-9D73-773BB1D39539";
NSString * const kDrawingCharacteristic = @"10493924-B9DB-4553-BBDC-864FA21FF118";
NSString * const kClearCMD = @"CLEAR";

@import CoreBluetooth;

@interface ViewController () <CBPeripheralManagerDelegate, CBPeripheralDelegate, CBCentralManagerDelegate>

@property (nonatomic,strong) CBPeripheralManager *peripheralManager;
@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCentralManager *centralManager;
@property (weak, nonatomic) IBOutlet DrawView *drawView;
@property (weak, nonatomic) IBOutlet UILabel *centralLabel;
@property (weak, nonatomic) IBOutlet UILabel *peripheralLabel;

@end

@implementation ViewController

#pragma mark - Initialization
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(nil != self) {
        self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
        self.centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil options:nil];
    }
    return self;
}

#pragma mark - View Controller

- (IBAction)clearButtonTapped:(id)sender {
    [self.drawView clearDrawnPoints];
    [self sendClear];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self drawPointFromTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self drawPointFromTouches:touches];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self endDrawingPoints];
}

- (void)drawPointFromTouches:(NSSet *)touches {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.drawView];
    [self.drawView drawPoint:point];
    [self sendPoint:point];
}

- (void)endDrawingPoints{
    [self.drawView endDrawingPoints];
    [self sendPoint:CGPointZero];
}

#pragma mark - Peripheral
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is on.");
        CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:kDrawingCharacteristic] properties:CBCharacteristicPropertyWriteWithoutResponse value:nil permissions:CBAttributePermissionsWriteable];
        CBMutableService *service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:kDrawingService] primary:YES];
        service.characteristics = @[characteristic];
        [self.peripheralManager addService:service];
    }
}

//adding service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Adding service error: %@.",error);
    } else {
        NSLog(@"Service added.");
        [peripheral startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:kDrawingService]]}];
    }
}

//advertising
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Advertising error: %@.",error);
    } else {
        NSLog(@"Advertising started.");
    }
}

//write request & DRAW
-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    CBATTRequest *request = [requests firstObject];
    NSData *data = request.value;
    NSString *string = [[NSString alloc]initWithData:data encoding:NSUnicodeStringEncoding];
    if ([string isEqualToString:kClearCMD]) {
        [self.drawView clearDrawnPoints];
    } else {
        CGPoint point = CGPointFromString(string);
        [self.drawView drawPoint:point];
    }
}

#pragma mark - Central
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) { //start searching
        NSLog(@"Central is on.");
        [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kDrawingService]] options:nil];
    }
}

//peripheral discovery
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Peripheral discovered: %@.", peripheral);
    [self.centralManager stopScan];
    self.peripheral = peripheral;
    [self.centralManager connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnConnectionKey: @YES, CBConnectPeripheralOptionNotifyOnDisconnectionKey: @YES}];
}

//disconnection
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Peripheral disconnected: %@.", peripheral);
    self.peripheralLabel.enabled = NO;
    self.peripheralLabel.text = @"disconnected";
    [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kDrawingService]] options:nil];
}

//connection
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Pieripheral connected: %@.", peripheral);
    self.peripheralLabel.enabled = YES;
    self.peripheralLabel.text = @"connected";
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:kDrawingService]]];
}

//service discovery
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Service Discovery error: %@",error);
    } else {
        NSLog(@"Services discovered: %@",peripheral.services);
        [self.peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kDrawingCharacteristic]] forService:[self.peripheral.services firstObject]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:kDrawingService]]];
}

//characteristics discovery
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Characteristics Discovery error: %@",error);
    } else {
        NSLog(@"Characteristics discovered: %@.", service.characteristics);
    }
}

//sending data
- (void)sendPoint:(CGPoint)point {
    NSString *stringPoint = NSStringFromCGPoint(point);
    NSData *data = [stringPoint dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO];
    [self sendData:data];
}

- (void)sendClear {
    NSString *clearCMD = kClearCMD;
    NSData *data = [clearCMD dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:NO];
    [self sendData:data];
}

- (void)sendData:(NSData *)data {
    if ([self canSendData]) {
        CBCharacteristic *characteristic = [self drawingCharacteristic];
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

- (CBCharacteristic *)drawingCharacteristic {
    return [self.peripheral.services[0] characteristics][0];
}

- (BOOL)canSendData {
    CBCharacteristic *characteristic = [self drawingCharacteristic];
    return (self.peripheral.state == CBPeripheralStateConnected && characteristic != nil);
}

@end
