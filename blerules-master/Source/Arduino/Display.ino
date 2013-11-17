#include <DigitShield.h>
#include <SoftwareSerial.h>

SoftwareSerial bleShield(2, 3);

const int SPINNER_FORWARD = 1;
const int SPINNER_BACKWARD = -1;
const int SPINNER_OFF = -1;
const char END_INPUT = '\n';

int spinnerDirection = SPINNER_FORWARD;
int spinnerPos = 0;

String input = "";
boolean inputComplete = false;

void setup()
{
  randomSeed(analogRead(0));
  bleShield.begin(19200);
  DigitShield.begin();
  Serial.begin(19200);
}

void loop()
{
  if (spinnerPos != SPINNER_OFF)
  {
    advanceSpinner();
  }

  if (inputComplete)
  {
    spinnerPos = SPINNER_OFF;
    displayInput();
  }
  else
  {
    checkForInput();
  }

  writeRandomString();
}

void advanceSpinner()
{
  spinnerPos += spinnerDirection;

  if (spinnerPos < 1)
  {
    spinnerDirection = SPINNER_FORWARD;
  }
  else if (spinnerPos > 4)
  {
    spinnerDirection = SPINNER_BACKWARD;
  }
  else
  {
    for (int i = 1; i <= 4; i++)
    {
      boolean on = (i == spinnerPos);
      DigitShield.setDecimalPoint(i, on);
    }
  }

  if (spinnerPos == 1 || spinnerPos == 4)
  {
    delay(200);
  }
  else
  {
    delay(80);
  }
}

void checkForInput()
{
  while (!inputComplete && bleShield.available())
  {
    char c = bleShield.read();

    if (c == END_INPUT)
    {
      inputComplete = true;
    }
    else
    {
      input.concat(c);
    }
  }
}

void displayInput()
{
  for (int i = 1; i <= 4; i++)
  {
    DigitShield.setDecimalPoint(i, false);
  }

  int len = input.length() + 1;
  char buffer[len];
  input.toCharArray(buffer, len);
  int i = atoi(buffer);

  DigitShield.setValue(i);

  input = "";
  inputComplete = false;
}

int messageInterval = 3000;
int lastMessageId = -1;
unsigned long lastMessageSentAt = 0;
char *messages[] =
{
  "        MDC 2013",
  "       BLE Rules",
  "BLE pckts r smll",
  "Ain't no headset"
};

void writeRandomString()
{
  unsigned long currentTime = millis();

  if (currentTime - lastMessageSentAt > messageInterval)
  {
    int messageId = lastMessageId + 1;

    if (messageId > 3)
    {
      messageId = 0;
    }

    char *message = messages[messageId];
    bleShield.write(message);

    lastMessageId = messageId;
    lastMessageSentAt = currentTime;
  }
}
