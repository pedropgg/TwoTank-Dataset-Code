// Two-tank DAQ firmware -- RECONSTRUCTED reference implementation.
//
// The original firmware used during the 2025 experiments is not available. This sketch
// implements the serial protocol expected by MATLAB_Control/DAQ_Read.m and DAQ_Write.m,
// so the MATLAB scripts can be run against the plant. Pin assignments and PWM frequency
// are assumptions; check them against the signal-conditioning PCB before use.
//
// Protocol (115200 bps, 8N1):
//   0x88 (136)          -> replies two lines "<ch0>\n<ch1>\n", 8-bit ADC readings 0-255
//                          of analog inputs A0 (tank level, 0-5 V after conditioning) and A1.
//   0x41 (65) <b0> <b1> -> sets PWM duty b0 on pin 9 (pump VFD command, filtered to 0-10 V)
//                          and b1 on pin 10 (auxiliary output, unused in the experiments).

const uint8_t CMD_READ = 136;
const uint8_t CMD_WRITE = 65;
const int analogIn0 = A0;
const int analogIn1 = A1;
const int pwmOut0 = 9;
const int pwmOut1 = 10;
const unsigned long byteTimeoutMs = 50;

// Wait for one byte; returns -1 on timeout so a truncated command is discarded.
int readByteWithTimeout()
{
	unsigned long start = millis();
	while (!Serial.available()) {
		if (millis() - start > byteTimeoutMs) {
			return -1;
		}
	}
	return Serial.read();
}

void setup()
{
	Serial.begin(115200);
	// Timer1 drives pins 9 and 10; prescaler 1 gives ~31.37 kHz PWM, easier to RC-filter.
	TCCR1B = TCCR1B & B11111000 | B00000001;
	pinMode(pwmOut0, OUTPUT);
	pinMode(pwmOut1, OUTPUT);
	analogWrite(pwmOut0, 0);
	analogWrite(pwmOut1, 0);
}

void loop()
{
	if (!Serial.available()) {
		return;
	}
	uint8_t command = Serial.read();

	if (command == CMD_READ) {
		Serial.println(analogRead(analogIn0) >> 2); // 10-bit ADC -> 8 bits, as scaled by DAQ_Read.m
		Serial.println(analogRead(analogIn1) >> 2);
	} else if (command == CMD_WRITE) {
		int duty0 = readByteWithTimeout();
		int duty1 = readByteWithTimeout();
		if (duty0 >= 0 && duty1 >= 0) {
			analogWrite(pwmOut0, duty0);
			analogWrite(pwmOut1, duty1);
		}
	}
}
