// rkharris@g.hmc.edu
//
// Send 10 pixel bytes to ATSAM over SPI
 

////////////////////////////////////////////////
// #includes
////////////////////////////////////////////////

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "SAM4S4B_lab7/SAM4S4B.h"

////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////

#define DONE_PIN    30
#define RESET_PIN	8

#define LED_PIN PIO_PA0
#define BUFF_LEN 32

/////////////////////////////////////////////////////////////////
// Provided Constants and Functions
/////////////////////////////////////////////////////////////////

//Defining the web page in two chunks: everything before the current time, and everything after the current time
char* webpageStart = "<!DOCTYPE html><html><head><title>E155 Web Server Demo Webpage</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>E155 Web Server Demo Webpage</h1>";
char* ledStr = "<p>LED Control:</p><form action=\"ledon\"><input type=\"submit\" value=\"Turn the LED on!\"></form>\
	<form action=\"ledoff\"><input type=\"submit\" value=\"Turn the LED off!\"></form>";
char* webpageEnd   = "</body></html>";

// Sends a null terminated string of arbitrary length
void sendString(char* str) {
	char* ptr = str;
	while (*ptr) uartTx(*ptr++);
}

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

int updateLEDStatus(char request[])
{
	int led_status = 0;
	// The request has been received. now process to determine whether to turn the LED on or off
	if (inString(request, "ledoff")==1) {
		pioDigitalWrite(LED_PIN, PIO_LOW);
		led_status = 0;
	}
	else if (inString(request, "ledon")==1) {
		pioDigitalWrite(LED_PIN, PIO_HIGH);
		led_status = 1;
	}

	return led_status;
}


////////////////////////////////////////////////
// Function Prototypes
////////////////////////////////////////////////

void get_pixels(char*);

////////////////////////////////////////////////
// Main
////////////////////////////////////////////////

int main(void) {
  char pixels[256];// = {3, 3};// = {100,100,100,100,100,100,100,100,100,100};

  samInit();
  pioInit();
  spiInit(MCK_FREQ/244000, 0, 1);
  // "clock divide" = master clock frequency / desired baud rate
  // the phase for the SPI clock is 1 and the polarity is 0
	tcInit();
	tcDelayInit();
	
  pioPinMode(DONE_PIN, PIO_INPUT);
	pioPinMode(RESET_PIN, PIO_OUTPUT);
	
	pioPinMode(LED_PIN, PIO_OUTPUT);
	pioDigitalWrite(LED_PIN, PIO_LOW);
	
	uartInit(4,20);
	
  pioDigitalWrite(RESET_PIN, 1);
  pioDigitalWrite(RESET_PIN, 0);
	
  // recieve pixels from FPGA
  get_pixels(pixels);
	
	while(1) {
		/* Wait for ESP8266 to send a request.
	Requests take the form of '/REQ:<tag>\n', with TAG begin <= 10 characters.
	Therefore the request[] array must be able to contain 18 characters.
	*/
	
	// Receive web request from the ESP
	char request[BUFF_LEN] = "                  "; // initialize to known value
	int charIndex = 0;
	
	// Keep going until you get end of line character
	while(inString(request, "\n") == -1)
	{
		// Wait for a complete request to be transmitted before processing
		while(!uartRxReady());
		request[charIndex++] = uartRx();
	}
	
	// Update string with current LED state
	
	int led_status = updateLEDStatus(request);

	char ledStatusStr[20];
	if (led_status == 1)
		sprintf(ledStatusStr,"LED is on!");
	else if (led_status == 0)
		sprintf(ledStatusStr,"LED is off!");

	// finally, transmit the webpage over UART
	sendString(webpageStart); // webpage header code
	sendString(ledStr); // button for controlling LED

	sendString("<h2>LED Status</h2>");


	sendString("<p>");
	sendString(ledStatusStr);
	sendString("</p>");
	
	sendString("<p>");
	int c;
	char num[5];
	int i;
	for (i=0; i<16; i++) {
		c = (int) pixels[i];
		if (i==15) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=16; i<32; i++) {
		c = (int) pixels[i];
		if (i==31) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=32; i<48; i++) {
		c = (int) pixels[i];
		if (i==47) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=48; i<64; i++) {
		c = (int) pixels[i];
		if (i==63) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=64; i<80; i++) {
		c = (int) pixels[i];
		if (i==79) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=80; i<96; i++) {
		c = (int) pixels[i];
		if (i==95) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=96; i<112; i++) {
		c = (int) pixels[i];
		if (i==111) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=112; i<128; i++) {
		c = (int) pixels[i];
		if (i==127) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=128; i<144; i++) {
		c = (int) pixels[i];
		if (i==143) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=144; i<160; i++) {
		c = (int) pixels[i];
		if (i==159) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=160; i<176; i++) {
		c = (int) pixels[i];
		if (i==175) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=176; i<192; i++) {
		c = (int) pixels[i];
		if (i==191) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=192; i<208; i++) {
		c = (int) pixels[i];
		if (i==207) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=208; i<224; i++) {
		c = (int) pixels[i];
		if (i==223) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=224; i<240; i++) {
		c = (int) pixels[i];
		if (i==239) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	for (i=240; i<256; i++) {
		c = (int) pixels[i];
		if (i==255) {
			sprintf(num, "%d", c);
		}
		else {
			sprintf(num, "%d,", c);
		}
		sendString(num);
	}
	sendString("</p>");
	
	
	sendString(webpageEnd);
	};
}

////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////

void get_pixels(char *pixels) {
  int i;

  while (!pioDigitalRead(DONE_PIN));

  for(i = 0; i < 256; i++) {
    pixels[i] = spiSendReceive(0);
  }
}
