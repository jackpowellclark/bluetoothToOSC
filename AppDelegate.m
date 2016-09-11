/*
 * AppDelegate.m; Bluetooth to OSC
 * An application to allow for sending of a received Bluetooth Low Energy characteristic to an Open Sound Control port.
 *
 * @author: Jack Clark
 * @version: 1.0
 *
 * @line length limit: 120
 */

/* Import the applications header file and the supporting CBUUID file */
#import "AppDelegate.h"
#import "CBUUID+StringExtraction.h"

@implementation AppDelegate;

/* Generate getter and setter methods for 'heartRate' */
@synthesize heartRate;

#pragma mark - Launch and Terminate methods
/* Invoked when the application has launched */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /* Set the origin and size of the app's window frame rectangle; display it */
    [self.window setFrame:NSMakeRect(10, 10, 438, 393) display:YES];
    /* Set the minimum size to which the app's window frame can be sized */
    [self.window setMinSize:NSMakeSize(438, 393)];
    /* Set the maximum size to which the app's window frame can be sized */
    [self.window setMaxSize:NSMakeSize(438, 393)];
    /* Set the app's post window as not editiable */
    [self.logTextView setEditable:NO];

    /* Initialse a CBCentralManager with self as its delegate */
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    /* Create an 'OSC Manager' */
    self.oscManager = [[OSCManager alloc] init];
    /* Set self as it's delegate */
    [self.oscManager setDelegate:self];
    /* Initialse the string held in the post window as a 'MutableString' i.e. a string which can be edited */
    self.logString = [[NSMutableString alloc] init];
    /* Initialse the array for holding discovered peripherals */
    self.discoveredDevices = [[NSMutableArray alloc] init];
    /* Initialse the array for holding discovered services */
    self.discoveredServices = [[NSMutableArray alloc] init];
    /* Initialse the array for holding discovered characteristics */
    self.discoveredCharacteristics = [[NSMutableArray alloc] init];
    /* Initialse 'heartRate' to 0 */
    self.heartRate = 0;

    /* Invoke the method 'startScan' */
    [self startScan];
}

/* Invoked when the application is terminated */
-(void)applicationWillTerminate:(NSNotification *)notification {
    /* Invoke 'disconnectUI' */
    [self disconnectUI];
    /* Tell CBCentralManager to cancel any connect it may have */
    [self.manager cancelPeripheralConnection:self.peripheral];
}

#pragma mark - User defined methods
/* A method that starts scanning for peripheral devices */
-(void) startScan {
    /* Have the CBCentralManager scan for ALL peripheral devices that are broadcasting */
    [self.manager scanForPeripheralsWithServices:nil options:nil];

    /* Helpful log message */
    [self addLogText:@"Scanning for peripheral devices..."];
}

/* A method that when invoked, connects to a heart rate monitor! */
-(void) connectToPeripheral {
    /* Stop scanning */
    [self.manager stopScan];
    /* Set 'peripheral' to be that currently selected */
    self.peripheral = [self.discoveredDevices objectAtIndex:self.devicesPopUp.indexOfSelectedItem];
    /* Connect CBCentralManager to 'peripheral' */
    [self.manager connectPeripheral:self.peripheral options:nil];

    /* Helpful log message */
    [self addLogText:@"Connected to peripheral device!"];
}

/* A method for 'disconnecting' the UI; essentially this wipes all data held by UI elements */
-(void)disconnectUI {
    [self.devicesPopUp removeAllItems];
    self.peripheral = nil;
    [self.discoveredDevices removeAllObjects];
    [self.connectButton setTitle:@"Connect"];
    [self.servicesPopUp removeAllItems];
    self.selectedService = nil;
    [self.discoveredServices removeAllObjects];
    [self.characteristicsPopUp removeAllItems];
    [self.discoveredCharacteristics removeAllObjects];

    /* Invoke the method 'startScan' essentially restarting the application */
    [self startScan];
}

/* A method for updating the text in the log window */
-(void)addLogText:(NSString *)text {
    [self.logString appendFormat:@"%@\n", text];
    [self.logTextView setString:self.logString];
    [self.logTextView scrollToEndOfDocument:nil];
}

/* A method for clearing the text in the log window */
-(void)clearLog {
    self.logString = [NSMutableString string];
    [self.logTextView setString:self.logString];
}

#pragma mark - CBCentralManager delegate methods
/* Invoked whenever the central manager's state is updated */
/* N.B. This is required method; for this assignment it is not necessary however */
-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    /* Commented out; there is no need to perform the check on self for capability */
    //[self isLECapableHardware];
}

/* Invoked when the CBCentralManager discovers a peripheral */
-(void) centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)aPeripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    /* Helpful log message */
    [self addLogText:@"A peripheral was discovered and added to 'Peripherals'..."];

    /* IF the peripheral is not unnamed... */
    if (aPeripheral.name != nil) {
        /* Add the peripheral to both the UI and an array of discovered peripherals */
        [self.devicesPopUp addItemWithTitle:aPeripheral.name];
        [self.discoveredDevices addObject:aPeripheral];
    }
}

/* Invoked when a connection is successfully made with a peripheral */
-(void) centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)aPeripheral {
    /* Helpful print statement */
    [self addLogText:[NSString stringWithFormat:@"Peripheral device: %@ is connected", aPeripheral.name]];
    /* Set the delegate of 'aPeripheral' to be self */
    [aPeripheral setDelegate:self];
    /* Discover the available services that the connected peripheral is broadcasting */
    [aPeripheral discoverServices:nil];
}

/* Invoked when CBCentralManager disconnects from a peripheral */
-(void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                error:(NSError *)error {
    /* Set the boolean 'isConnected' to NO */
    self.isConnected = NO;
    /* Invoke 'disconnectUI */
    [self disconnectUI];
    /* Create an alert to inform users a peripheral has disconnected */
    NSAlert *alert = [NSAlert alertWithMessageText:@"Device Disconnected" defaultButton:@"Close" alternateButton:nil
                                       otherButton:nil informativeTextWithFormat:@"The device has disconnected"];
    /* Throw the alert */
    [alert runModal];
}

/* Invoked upon completion of a -[discoverServices:] request */
-(void) peripheral:(CBPeripheral *)aPeripheral
didDiscoverServices:(NSError *)error {
    /* For all discovered services of a peripheral... */
    for (CBService *aService in aPeripheral.services) {
        /* If the currently selected service is nil (i.e. a user has not selected one yet)... */
        if (self.selectedService == nil) {
            /* Set 'selectedService' */
            self.selectedService = aService;
            /* Discover the characteristics for 'aService' */
            [self.peripheral discoverCharacteristics:nil forService:aService];
        }

        /* Add 'aService' to both the UI and an array of discovered services */
        /* N.B. There is not proved CBUUID method that can represent a service as a String. Due to this an extension
         method is used - 'StringExtraction'. See 'CBUUID+StringExtraction.h' for more info */
        [self.servicesPopUp addItemWithTitle:[(CBUUID *)[aService UUID] representativeString]];
        [self.discoveredServices addObject:aService];
    }
}

/* Invoked upon completion of a -[discoverCharacteristics:forService:] request */
-(void) peripheral:(CBPeripheral *)aPeripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    /* For all discovered characteristics of a service... */
    for (CBCharacteristic *aCharacteristic in service.characteristics) {
        /* If the currently selected characteristic is nil (i.e. a user has not selected one yet)... */
        if (self.selectedCharacteristic == nil) {
            /* Set 'selectedCharacteristic' */
            self.selectedCharacteristic = aCharacteristic;
            /* Turn on notifications for the selected characteristic */
            [self.peripheral setNotifyValue:YES forCharacteristic:self.selectedCharacteristic];
        }

        /* Add 'aCharacteristic' to both the UI and an array of discovered characteristics */
        /* N.B. There is not proved CBUUID method that can represent a service as a String. Due to this an extension
         method is used - 'StringExtraction'. See 'CBUUID+StringExtraction.h' for more info */
        [self.characteristicsPopUp addItemWithTitle:[aCharacteristic.UUID representativeString]];
        [self.discoveredCharacteristics addObject:aCharacteristic];
    }
}

/* Invoked upon the reception of a notification */
-(void) peripheral:(CBPeripheral *)aPeripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    /* if there was an error given back... */
    /* N.B. this was not used before as from experience this is the most likely to throw errors */
    if (error) {
        /* Helpful log message */
        [self addLogText:@"The selected characteristic returned an error"];
    }

    /* N.B. At this stage, characteristic data will be coming into this application; however this data can come in an
     incredible array of different forms. For this purpose of this project, it is heart rate data that is of
     interest and thus a method designed to specifically parse heart rate data is invoked. See: 'https://developer.
     bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.
     heart_rate_measurement.xml' for more information on the returned form of Bluetooth heart rate monitors. */
    /* Invoke 'parseHRMData' with the received characteristic */
    [self parseHRMData:characteristic.value];
}

/* A method that when invoked, parses incoming heart rate data and updates the global variable 'heartRate'. The actual
 parsing in thie method has changed little from that given in Apple's 'HeartRateMonitor/HeartRateMonitorAppDelegate.m'
 example (see top of file) */
/* A method for parsing incoming heart rate data */
-(void) parseHRMData:(NSData *)data {
    /* Create a 8 byte for holding bytes being returned from a service */
    const uint8_t *reportData = [data bytes];
    /* Create a 16 byte that will hold the heart rate returned */
    uint16_t bpm = 0;

    /* IF the incoming data is in 8 byte format... */
    if ((reportData[0] & 0x01) == 0) {
        /* Get its first 2nd index; an integer */
        bpm = reportData[1];
    } /* ELSE the incoming data is in 16 byte format... */ else {
        /* Get its first 2nd index; an integer */
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    /* Set the global variable 'heartRate' to be that of the newly converted bpm */
    self.heartRate = bpm;

    /* N.B. as this method is invoked whenever a new characteristic value is received, a new OSCMessage must be created
     for each of these new values */
    /* Create a new OSC Message for sending with the specified address '/bluetoothLEtoOSC' */
    OSCMessage *newMsg = [OSCMessage createWithAddress:@"/heartRate"];
    /* Add 'bpm' to this message; as an integer */
    [newMsg addInt:bpm];
    /* Send the newly created message */
    [self.outPort sendThisMessage:newMsg];
    /* Helpful log message */
    [self addLogText:[NSString stringWithFormat:@"BMP: %hu", bpm]];
}

/* IBActions allow for allow for methods to be associated with actions in Interface Builder */
#pragma mark IBActions

/* Action; the connect button was pressed */
-(IBAction)connectButtonPressed:(id)sender {
    /* Reverse boolean 'isConnected' */
    self.isConnected = !self.isConnected;
    /* IF the connected state is connected... */
    /* N.B. this appears in reverse but is correct! */
    if (!self.isConnected) {
        /* Change 'connectButton' to read 'Disconnect' */
        [self.connectButton setTitle:@"Connect"];
        /* Cancel the CBCentralManager connection and invoke 'disconnectUI' */
        [self.manager cancelPeripheralConnection:self.peripheral];
        [self disconnectUI];
        /* ELSE the connected state is disconnected... */
    } else {
        /* IF there are currently no discovered devices... */
        if (self.discoveredDevices.count == 0) {
            /* Set isConnected to NO */
            self.isConnected = NO;
            /* Create and throw an alert */
            NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Close" alternateButton:nil
                                               otherButton:nil informativeTextWithFormat:@"No peripherals found."];
            [alert runModal];
        } else /* ELSE there peripherals are in discovered... */{
            /* Change 'connectButton' to read 'Disconnect' */
            [self.connectButton setTitle:@"Disconnect"];
            /* Invoke 'connectToPeripheral' */
            [self connectToPeripheral];
        }
    }
}

/* Action; the service pop up was used */
-(IBAction)servicePopUpListener:(NSPopUpButton *)sender {
    /* Set 'selectedService' to be that of the currently selected service */
    self.selectedService = [self.discoveredServices objectAtIndex:[sender indexOfSelectedItem]];
    /* IF 'selectedCharacteristic' is NOT nil... */
    if (self.selectedCharacteristic != nil) {
        /* Turn of all notification updates for the selectedCharacteristic */
        [self.peripheral setNotifyValue:NO forCharacteristic:self.selectedCharacteristic];
    }

    /* Set the selectedCharacteristic to nil */
    self.selectedCharacteristic = nil;
    /* Remove all the items from 'characteristicsPopUp' */
    [self.characteristicsPopUp removeAllItems];
    /* Discover all the characteristics for the newly selected service */
    [self.peripheral discoverCharacteristics:nil forService:self.selectedService];
}

/* Action; the characteristic pop up was used */
-(IBAction)characteristicsPopUpListener:(NSPopUpButton *)sender {
    /* IF 'selectedCharacteristic' is NOT nil... */
    if (self.selectedCharacteristic != nil) {
        /* Turn of all notification updates for the selectedCharacteristic */
        [self.peripheral setNotifyValue:NO forCharacteristic:self.selectedCharacteristic];
    }

    /* set the selectedCharacteristic to be the currently selected one */
    self.selectedCharacteristic  = [[self.selectedService characteristics] objectAtIndex:[sender indexOfSelectedItem]];
    /* Turn on all notification updates for the selectedCharacteristic */
    [self.peripheral setNotifyValue:YES forCharacteristic:self.selectedCharacteristic];
}

/* Action; the send data button was used */
-(IBAction)sendDataPressed:(id)sender {
    /* Reverse boolean 'isSending' */
    self.isSending = !self.isSending;
    /* IF 'isSending' is NOT nil... */
    if (!self.isSending) {
        /* set the 'outPort' to nil */
        /* N.B. this is bit of 'dirty trick' as technically the data is still being sent; just not to any port */
        self.outPort = nil;
        /* Change 'sendDataButton' to read 'Send Data' */
        [self.sendDataButton setTitle:@"Send Data"];
    } else /* ELSE 'isSending' is nil... */ {
        /* Change 'sendDataButton' to read 'Stop' */
        [self.sendDataButton setTitle:@"Stop"];
        /* Set the 'OSC IP' text field as non editable */
        [self.oscIPTextField setEditable:NO];
        /* Set the 'OSC Port' text field as non editable */
        [self.oscPortTextField setEditable:NO];
        /* Set both 'oscIPString' and 'oscPortString' to be that of the UI values */
        self.oscIPString = [self.oscIPTextField stringValue];
        self.oscPortString = [self.oscPortTextField stringValue];
        /* Finally, set up the 'outport' so that messages created are sent via OSC */
        self.outPort = [self.oscManager createNewOutputToAddress:self.oscIPString atPort:[self.oscPortString intValue]];

        /* Helpful log message */
        [self addLogText:@"Sending Data!"];
    }
}

@end