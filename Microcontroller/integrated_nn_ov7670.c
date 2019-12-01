// rkharris@g.hmc.edu
//
// receive a classification from the FPGA neural net
 

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

#define DONE_PIN  30
#define RESET_PIN	8

#define LED_PIN PIO_PA0

#define NUM_SEGMENTS 7
#define CAT_A_PIN PIO_PA19
#define CAT_B_PIN PIO_PA20
#define CAT_C_PIN PIO_PA21
#define CAT_D_PIN PIO_PA22
#define CAT_E_PIN PIO_PA23
#define CAT_F_PIN PIO_PA24
#define CAT_G_PIN PIO_PA25


////////////////////////////////////////////////
// Function Prototypes
////////////////////////////////////////////////

void reset(void);
void seven_segment_init(void);
void get_classification(char*);
char find_max_of_classification(char*);
void reset_segments(void);
void write_segments(char*);
void display_digit(char);

////////////////////////////////////////////////
// Main
////////////////////////////////////////////////

int main(void) {
  char classification[30]; // 2 bytes per node, 15 nodes

  samInit();
  pioInit();
  spiInit(MCK_FREQ/244000, 0, 1);
  // "clock divide" = master clock frequency / desired baud rate
  // the phase for the SPI clock is 1 and the polarity is 0
	tcInit();
	tcDelayInit();
	
  pioPinMode(DONE_PIN, PIO_INPUT);
	pioPinMode(RESET_PIN, PIO_OUTPUT);
	
	seven_segment_init();
	
	pioPinMode(LED_PIN, PIO_OUTPUT);
	pioDigitalWrite(LED_PIN, PIO_LOW);
	
	reset();
	
  // recieve classification from FPGA
	
  get_classification(classification);
	char newDigit = find_max_of_classification(classification);
	display_digit(newDigit);
	
	while(1); 
}

////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////

void reset(void) {
  pioDigitalWrite(RESET_PIN, 1);
  pioDigitalWrite(RESET_PIN, 0);	
}

void get_classification(char *classification) {
  int i;

  while (!pioDigitalRead(DONE_PIN));

  for(i = 0; i < 30; i++) {
    classification[i] = spiSendReceive(0);
  }
}

char find_max_of_classification(char *classification) {
	int sum = 0;
	int new_max = 0;
	int index_of_new_max;
	for (int i = 0; i < 10; i++) {
		sum = (classification[2*i] << 8) + classification[2*i+1];
		if (sum > new_max) {
			new_max = sum;
			index_of_new_max = i;
		}
	}
	return index_of_new_max + '0'; // convert to char
}

// seven segment functions

void seven_segment_init(void) {
	pioPinMode(CAT_A_PIN, PIO_OUTPUT);
	pioPinMode(CAT_B_PIN, PIO_OUTPUT);
	pioPinMode(CAT_C_PIN, PIO_OUTPUT);
	pioPinMode(CAT_D_PIN, PIO_OUTPUT);
	pioPinMode(CAT_E_PIN, PIO_OUTPUT);
	pioPinMode(CAT_F_PIN, PIO_OUTPUT);
	pioPinMode(CAT_G_PIN, PIO_OUTPUT);
}

void reset_segments(void) {
	pioDigitalWrite(CAT_A_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_B_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_C_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_D_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_E_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_F_PIN, PIO_HIGH);
	pioDigitalWrite(CAT_G_PIN, PIO_HIGH);
}

void write_segments(char * segments) {
	pioDigitalWrite(CAT_A_PIN, (int)(segments[6]-'0'));
	pioDigitalWrite(CAT_B_PIN, (int)(segments[5]-'0'));
	pioDigitalWrite(CAT_C_PIN, (int)(segments[4]-'0'));
	pioDigitalWrite(CAT_D_PIN, (int)(segments[3]-'0'));
	pioDigitalWrite(CAT_E_PIN, (int)(segments[2]-'0'));
	pioDigitalWrite(CAT_F_PIN, (int)(segments[1]-'0'));
	pioDigitalWrite(CAT_G_PIN, (int)(segments[0]-'0'));	
}

void display_digit(char digit) {
	
	// make array to hold segments
	char segments[8]; // 8 for 7 segments + null char
	
	// pull outputs high to start
	reset_segments();
	
	switch(digit) {
		case '0':
			strcpy(segments, "1000000");
			break;
		case '1':
			strcpy(segments, "1111001");
			break;
		case '2':
			strcpy(segments, "0100100");
			break;
		case '3':
			strcpy(segments, "0110000");
			break;
		case '4':
			strcpy(segments, "0011001");
			break;
		case '5':
			strcpy(segments, "0010010");
			break;
		case '6':
			strcpy(segments, "0000010");
			break;
		case '7':
			strcpy(segments, "1111000");
			break;
		case '8':
			strcpy(segments, "0000000");
			break;
		case '9':
			strcpy(segments, "0011000");
			break;
		case 'A':
			strcpy(segments, "0001000");
			break;
		case 'B':
			strcpy(segments, "0000011");
			break;
		case 'C':
			strcpy(segments, "1000110");
			break;
		case 'D':
			strcpy(segments, "0100001");
			break;
		case 'E':
			strcpy(segments, "0000110");
			break;
		case 'F':
			strcpy(segments, "0001110");
			break;
		default:
			strcpy(segments, "1111111");
			break;
	}
	write_segments(segments);
}

