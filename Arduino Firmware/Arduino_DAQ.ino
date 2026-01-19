// Magnetic encoder readout for Pololu encoder
const int intPinA = 2; // Interrupt-capable pins on Arduino Uno: 2 and 3
const int intPinB = 3;
const int samplePeriodMs = 200;
const int maxSpeedRpm = 1500; // Expected max speed during no-load tests
const float pwmScale = 255.0f / maxSpeedRpm; // Map RPM to 0-255 PWM duty

unsigned long previousTimeMs = 0;
volatile int pulseCount = 0; // Volatile because it is updated inside ISRs
int speedRpm = 0;
float outputDuty = 0;
float dutyCurrent = 0;
float dutySum = 0;
const int filterLength = 8;
float dutyBuffer[filterLength] = {0};
const int pwmPin = 9; // PWM output to be filtered for analog use

// Timer1 drives PWM on pin 9; Timer0 stays free for millis(), delay(), etc.
void setup()
{
	Serial.begin(115200);
	TCCR1B = TCCR1B & B11111000 | B00000001; // Set PWM frequency to ~31.37 kHz

	pinMode(intPinA, INPUT_PULLUP);
	pinMode(intPinB, INPUT_PULLUP);
	attachInterrupt(digitalPinToInterrupt(intPinA), handleInterruptA, CHANGE);
	attachInterrupt(digitalPinToInterrupt(intPinB), handleInterruptB, CHANGE);
}

void loop()
{
	if (millis() - previousTimeMs >= samplePeriodMs) {
		noInterrupts();

		speedRpm = pulseCount * 15; // 15 counts per revolution from encoder
		if (speedRpm > maxSpeedRpm) {
			speedRpm = maxSpeedRpm;
		}

		dutyCurrent = speedRpm * pwmScale; // Map speed to PWM duty (0-255)

		// Simple moving average filter for duty command
		for (int i = 0; i < filterLength - 1; i++) {
			dutyBuffer[i] = dutyBuffer[i + 1];
		}
		dutyBuffer[filterLength - 1] = dutyCurrent;

		for (int i = 0; i < filterLength; i++) {
			dutySum += dutyBuffer[i];
		}

		outputDuty = float(dutySum / filterLength);
		analogWrite(pwmPin, outputDuty);

		pulseCount = 0;
		dutySum = 0;
		previousTimeMs = millis();
		interrupts();
	}
}

void handleInterruptB()
{
	pulseCount++;
}

void handleInterruptA()
{
	pulseCount++;
}