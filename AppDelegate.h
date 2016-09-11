/*
* AppDelegate.h; Bluetooth to OSC
*
* @author: Jack Clark
* @version: 1.0
*
* @line length limit: 120
*/

/* import Cocoa */
#import <Cocoa/Cocoa.h>
/* import IOBluetooth */
#import <IOBluetooth/IOBluetooth.h>
/* import VVOSC */
#import <VVOSC/VVOSC.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

/* Declare properties for 'CBCentralManager', 'CBPeripheral', 'OSCManager' and 'OSCOutPort' */
@property (nonatomic, retain) CBCentralManager *manager;
@property (nonatomic, retain) CBPeripheral *peripheral;
@property (nonatomic, retain) OSCManager *oscManager;
@property (nonatomic, retain) OSCOutPort *outPort;

/* Declare boolean properties for the two UI buttons and for when a peripheral device is connected */
@property (nonatomic) BOOL sendDataPressed;
@property (nonatomic) BOOL isConnected;
@property (nonatomic) BOOL isSending;

/* Declare a property for an unsigned 16-bit integer */
@property (nonatomic) uint16_t heartRate;

/* Declare three NSStrings; these will be used to hold information from to UI */
@property (nonatomic, retain) NSString *oscIPString;
@property (nonatomic, retain) NSString *oscPortString;
@property (nonatomic, retain) NSMutableString *logString;

/* Declare three NSMutableArrays; these will hold discovered peripherals and their advertisements */
@property(nonatomic, retain) NSMutableArray *discoveredDevices;
@property(nonatomic, retain) NSMutableArray *discoveredServices;
@property(nonatomic, retain) NSMutableArray *discoveredCharacteristics;

/* Declare properties for keeping track of the currently selected service and characteristic*/
@property (nonatomic, retain) CBService *selectedService;
@property (nonatomic, retain) CBCharacteristic *selectedCharacteristic;

/* Declare properties for UI Elements; IBOutlet is used to connect the UI controller, making the button accessible */
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPopUpButton *devicesPopUp;
@property (assign) IBOutlet NSButton *connectButton;
@property (assign) IBOutlet NSPopUpButton *servicesPopUp;
@property (assign) IBOutlet NSPopUpButton *characteristicsPopUp;
@property (assign) IBOutlet NSTextField *oscIPTextField;
@property (assign) IBOutlet NSTextField *oscPortTextField;
@property (assign) IBOutlet NSButton *sendDataButton;
@property (assign) IBOutlet NSTextView *logTextView;

/* Create four Interface Builder Actions. These allow for methods that are triggered by user-interface objects */
-(IBAction)connectButtonPressed:(id)sender;
-(IBAction)servicePopUpListener:(id)sender;
-(IBAction)characteristicsPopUpListener:(id)sender;
-(IBAction)sendDataPressed:(id)sender;

@end