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

#define DONE_PIN    30
#define RESET_PIN	8

#define LED_PIN PIO_PA0


////////////////////////////////////////////////
// Function Prototypes
////////////////////////////////////////////////

void get_classification(char*);

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
	
	pioPinMode(LED_PIN, PIO_OUTPUT);
	pioDigitalWrite(LED_PIN, PIO_LOW);
	
  pioDigitalWrite(RESET_PIN, 1);
  pioDigitalWrite(RESET_PIN, 0);
	
  // recieve classification from FPGA
  get_classification(classification);
	
	while(1); 
}

////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////

void get_classification(char *classification) {
  int i;

  while (!pioDigitalRead(DONE_PIN));

  for(i = 0; i < 30; i++) {
    classification[i] = spiSendReceive(0);
  }
}
