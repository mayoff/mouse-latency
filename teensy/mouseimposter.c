

#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/power.h>
#include <util/delay.h>

#include <LUFA/Drivers/USB/USB.h>
#include <LUFA/Drivers/USB/Core/Events.h>

////////////////////////////////////////////////////////////////
// Non-USB hardware setup

static void disableWatchdog(void) {
    MCUSR &= ~(1 << WDRF);
    wdt_disable();
}

static void hardwareInit(void) {
    disableWatchdog();
    clock_prescale_set(clock_div_1);
}

////////////////////////////////////////////////////////////////
// LEDs

typedef struct {
    volatile uint8_t *directionPort;
    volatile uint8_t *valuePort;
    uint8_t bit;
} OutputBit;

static OutputBit const kOrangeLED = { &DDRD, &PORTD, _BV(6) }; // Teensy board built-in
static OutputBit const kRedLED = { &DDRB, &PORTB, _BV(6) };    // added via breadboard
static OutputBit const kGreenLED = { &DDRB, &PORTB, _BV(4) };  // added via breadboard
static OutputBit const kBlueLED = { &DDRB, &PORTB, _BV(5) };   // added via breadboard

static void initOutputBit(OutputBit const *const bit) __attribute__((always_inline));
static void initOutputBit(OutputBit const *const bit) {
    *bit->directionPort |= bit->bit;
    *bit->valuePort &= ~bit->bit;
}

static void setOutputBit(OutputBit const *const bit, uint8_t value) __attribute__((always_inline));
static void setOutputBit(OutputBit const *const bit, uint8_t value) {
    if (value)
        *bit->valuePort |= bit->bit;
    else
        *bit->valuePort &= ~bit->bit;
}

static void initLEDs(void) {
    initOutputBit(&kOrangeLED);
    initOutputBit(&kRedLED);
    initOutputBit(&kGreenLED);
    initOutputBit(&kBlueLED);
}

////////////////////////////////////////////////////////////////
// Descriptors

typedef enum {
    kLanguageDescriptorIndex = 0,
    kManufacturerDescriptorIndex,
    kProductDescriptorIndex
} StringDescriptorIndex;

typedef enum {
    kMouseInterfaceNumber = 0,
    kInterfaceCount
} InterfaceNumber;

typedef enum {
    kDefaultControlPipeEndpointAddress = 0,
    kMouseEndpointAddress
} EndpointAddress;

#define kMouseEndpointSize 8

#define MakeStringDescriptor(Name, Value) \
    static USB_Descriptor_String_t const PROGMEM Name = { \
        .Header = { .Size = sizeof(L##Value), .Type = DTYPE_String }, \
        .UnicodeString = L##Value \
    } \
    // End of macro

static uint16_t getDeviceDescriptor(void const **const outDescriptor) {
    static USB_StdDescriptor_Device_t const PROGMEM kDeviceDescriptor = {
        .bLength = sizeof kDeviceDescriptor,
        .bDescriptorType = DTYPE_Device,
        .bcdUSB = VERSION_BCD(2.0),
        .bDeviceClass = 0,
        .bDeviceSubClass = 0,
        .bDeviceProtocol = 0,
        .bMaxPacketSize0 = FIXED_CONTROL_ENDPOINT_SIZE,
        .idVendor = CPU_TO_LE16(0xFFFF),
        .idProduct = CPU_TO_LE16(0x0001),
        .bcdDevice = VERSION_BCD(1.0),
        .iManufacturer = kManufacturerDescriptorIndex,
        .iProduct = kProductDescriptorIndex,
        .iSerialNumber = 0,
        .bNumConfigurations = 1
    };

    setOutputBit(&kRedLED, 1);

    *outDescriptor = &kDeviceDescriptor;
    return sizeof kDeviceDescriptor;
}

static uint16_t getLanguageDescriptor(void const **const outDescriptor) {
    static USB_StdDescriptor_String_t const PROGMEM kDescriptor = {
        .bLength = 4,
        .bDescriptorType = DTYPE_String,
        .bString = { LANGUAGE_ID_ENG }
    };
    *outDescriptor = &kDescriptor;
    return pgm_read_byte(&kDescriptor.bLength);
}

static uint16_t getManufacturerDescriptor(void const **const outDescriptor) {
    MakeStringDescriptor(kDescriptor, "Rob Mayoff");
    *outDescriptor = &kDescriptor;
    return pgm_read_byte(&kDescriptor.Header.Size);
}

static uint16_t getProductDescriptor(void const **const outDescriptor) {
    MakeStringDescriptor(kDescriptor, "Mouse Imposter");
    *outDescriptor = &kDescriptor;
    return pgm_read_byte(&kDescriptor.Header.Size);
}

static uint8_t const PROGMEM kMouseReportDescriptor[] = {
    HID_RI_USAGE_PAGE(8, 1), // 1 = Generic Desktop
    HID_RI_USAGE(8, 2), // 2 = Mouse
    HID_RI_COLLECTION(8, 1), // 1 = Application
        HID_RI_USAGE(8, 1), // 1 = Pointer
        HID_RI_COLLECTION(8, 0), // 0 = Physical
            HID_RI_USAGE_PAGE(8, 9), // 9 = Buttons
            HID_RI_USAGE_MINIMUM(8, 1), // 1 = first button number
            HID_RI_USAGE_MAXIMUM(8, 3), // 3 = last button number
            HID_RI_LOGICAL_MINIMUM(8, 0), // 0 = application value for bit value 0
            HID_RI_LOGICAL_MAXIMUM(8, 1), // 1 = application value for bit value 1
            HID_RI_REPORT_COUNT(8, 3), // 3 = number of buttons
            HID_RI_REPORT_SIZE(8, 1), // 1 = bits reported per button
            HID_RI_INPUT(8, HID_IOF_DATA | HID_IOF_VARIABLE | HID_IOF_ABSOLUTE), // Define the button fields
            HID_RI_REPORT_COUNT(8, 1), // 1 = number of padding fields
            HID_RI_REPORT_SIZE(8, 5), // 5 = number of bits in padding field
            HID_RI_INPUT(8, HID_IOF_CONSTANT), // Define the padding field
            HID_RI_USAGE_PAGE(8, 1), // 1 = Generic Desktop
            HID_RI_USAGE(8, 0x30), // 0x30 = X axis
            HID_RI_USAGE(8, 0x31), // 0x31 = Y axis,
            HID_RI_LOGICAL_MINIMUM(8, -127), // -127 = minimum report value
            HID_RI_LOGICAL_MAXIMUM(8, 127), // 127 = maximum report value
            HID_RI_REPORT_SIZE(8, 8), // 8 = bits per axis
            HID_RI_REPORT_COUNT(8, 2), // 2 = number of axes
            HID_RI_INPUT(8, HID_IOF_DATA | HID_IOF_VARIABLE | HID_IOF_RELATIVE), // Define the axis fields
        HID_RI_END_COLLECTION(0),
    HID_RI_END_COLLECTION(0)
};

static struct {
    USB_StdDescriptor_Configuration_Header_t configuration;
    USB_StdDescriptor_Interface_t mouseInterface;
    USB_HID_StdDescriptor_HID_t mouseHID;
    USB_StdDescriptor_Endpoint_t mouseEndpointIN;
} const PROGMEM kConfigurationDescriptor = {

    .configuration = {
        .bLength = sizeof kConfigurationDescriptor.configuration,
        .bDescriptorType = DTYPE_Configuration,
        .wTotalLength = sizeof kConfigurationDescriptor,
        .bNumInterfaces = 1,
        .bConfigurationValue = 1,
        .iConfiguration = 0,
        // USB_CONFIG_ATTR_RESERVED = Bus Powered
        .bmAttributes = USB_CONFIG_ATTR_RESERVED,
        .bMaxPower = USB_CONFIG_POWER_MA(100)
    },

    .mouseInterface = {
        .bLength = sizeof kConfigurationDescriptor.mouseInterface,
        .bDescriptorType = DTYPE_Interface,
        .bInterfaceNumber = kMouseInterfaceNumber,
        .bAlternateSetting = 0,
        .bNumEndpoints = 1,
        .bInterfaceClass = HID_CSCP_HIDClass,
        .bInterfaceSubClass = HID_CSCP_BootSubclass,
        .bInterfaceProtocol = HID_CSCP_MouseBootProtocol,
        .iInterface = 0
    },

    .mouseHID = {
        .bLength = sizeof kConfigurationDescriptor.mouseHID,
        .bDescriptorType = HID_DTYPE_HID,
        .bcdHID = VERSION_BCD(1.11),
        .bCountryCode = 0,
        .bNumDescriptors = 1,
        .bDescriptorType2 = HID_DTYPE_Report,
        .wDescriptorLength = sizeof kMouseReportDescriptor
    },

    .mouseEndpointIN = {
        .bLength = sizeof kConfigurationDescriptor.mouseEndpointIN,
        .bDescriptorType = DTYPE_Endpoint,
        .bEndpointAddress = kMouseEndpointAddress | ENDPOINT_DIR_IN,
        .bmAttributes = EP_TYPE_INTERRUPT,
        .wMaxPacketSize = kMouseEndpointSize,
        .bInterval = 1
    }

};

static uint16_t getConfigurationDescriptor(void const **const outDescriptor) {
    setOutputBit(&kBlueLED, 1);
    *outDescriptor = &kConfigurationDescriptor;
    return sizeof kConfigurationDescriptor;
}

static uint16_t getMouseHIDDescriptor(void const **const outDescriptor) {
    *outDescriptor = &kConfigurationDescriptor.mouseHID;
    return sizeof kConfigurationDescriptor.mouseHID;
}

static uint16_t getMouseReportDescriptor(void const **const outDescriptor) {
    *outDescriptor = kMouseReportDescriptor;
    return sizeof kMouseReportDescriptor;
}

uint16_t CALLBACK_USB_GetDescriptor(uint16_t const wValue, uint8_t wIndex, void const **const outDescriptor) {
    uint8_t const type = wValue >> 8;
    uint8_t const index = wValue & 0xff;

    switch (type) {
        case DTYPE_Device:
            return getDeviceDescriptor(outDescriptor);

        case DTYPE_Configuration:
            return getConfigurationDescriptor(outDescriptor);

        case HID_DTYPE_HID:
            return getMouseHIDDescriptor(outDescriptor);

        case HID_DTYPE_Report:
            return getMouseReportDescriptor(outDescriptor);

        case DTYPE_String: {
            switch (index) {
                case kLanguageDescriptorIndex: return getLanguageDescriptor(outDescriptor);
                case kManufacturerDescriptorIndex: return getManufacturerDescriptor(outDescriptor);
                case kProductDescriptorIndex: return getProductDescriptor(outDescriptor);
                default: return NO_DESCRIPTOR;
            }
        }

        default: return NO_DESCRIPTOR;
    }
}

////////////////////////////////////////////////////////////////

static uint8_t mousePriorReportBuffer[3];

static USB_ClassInfo_HID_Device_t mouseHIDInterface = {
    .Config = {
        .InterfaceNumber = kMouseInterfaceNumber,
        .ReportINEndpointNumber = kMouseEndpointAddress,
        .ReportINEndpointSize = kMouseEndpointSize,
        .ReportINEndpointDoubleBank = false,
        .PrevReportINBuffer = mousePriorReportBuffer,
        .PrevReportINBufferSize = sizeof mousePriorReportBuffer
    }
};

static bool shouldSendMouseEvent;
static uint8_t xDelta = 10;

void EVENT_USB_Device_ConfigurationChanged(void) {
    HID_Device_ConfigureEndpoints(&mouseHIDInterface);
    USB_Device_EnableSOFEvents();
}

bool CALLBACK_HID_Device_CreateHIDReport(USB_ClassInfo_HID_Device_t *const info, uint8_t *const reportID, uint8_t const reportType, void *reportData, uint16_t *const reportSize) {
    setOutputBit(&kGreenLED, 0);
    if (shouldSendMouseEvent) {
        shouldSendMouseEvent = false;
        USB_MouseReport_Data_t *report = reportData;
        report->Button = 0;
        report->X = xDelta;
        xDelta = -xDelta;
        report->Y = 0;
        *reportSize = sizeof *report;
        return true;
    } else {
        *reportSize = 0;
        return false;
    }
}

void EVENT_USB_Device_ControlRequest(void) {
    HID_Device_ProcessControlRequest(&mouseHIDInterface);
}

void CALLBACK_HID_Device_ProcessHIDReport(USB_ClassInfo_HID_Device_t *const info, uint8_t const reportID, uint8_t const reportType, void const *reportData, uint16_t const reportSize) {
    setOutputBit(&kGreenLED, 1);
    shouldSendMouseEvent = true;
}

int main(void) {
    hardwareInit();
    initLEDs();
    setOutputBit(&kOrangeLED, 1);

    sei();

    USB_Init();

    while (1) {
        HID_Device_USBTask(&mouseHIDInterface);
        USB_USBTask();
    }
}

