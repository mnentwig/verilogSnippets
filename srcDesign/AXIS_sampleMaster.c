// drop this into a "standalone hello world" Vitis project's source folder

#include "xaxidma.h"
#include "xparameters.h"
#include "assert.h"
#include <stdio.h>
#include <stdlib.h> // malloc

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

const unsigned startBit = 1u << 31; // MSB in AXIS master ctrl register asserts "valid" until counter is reached.

void runTest(XAxiDma* iDma, unsigned nWords){

  // AXIS master ctrl register
  volatile uint32_t* ctrlReg = (volatile uint32_t*)(XPAR_AXIS_SAMPLEMASTER_0_BASEADDR);

  // set power-up state, "valid" deasserted
  // This assignment should have no effect as it equals the power-up / expected state
  *ctrlReg = 0;

  const unsigned nBytes = nWords * sizeof(uint32_t);
  assert(nBytes < (1 << 26)); // maximum possible width of lenght register in DMA block (note: default is much smaller)
  uint32_t* txPtr = (uint32_t*)malloc(nBytes); assert(txPtr && "please edit linker file and assign sufficient heap space");
  uint32_t* rxPtr = (uint32_t*)malloc(nBytes); assert(rxPtr);

  for (unsigned ix = 0; ix < nWords; ++ix){
    *(txPtr+ix) = ix; // data to be transmitted
    *(rxPtr+ix) = ~ix; // fill Rx buffer with incorrect (that is, expected result inverted) data
  }

  // === prepare DMA ===
  Xil_DCacheFlushRange((UINTPTR)txPtr, nBytes);
  Xil_DCacheFlushRange((UINTPTR)rxPtr, nBytes);
  unsigned s;
  s = XAxiDma_SimpleTransfer(iDma, (UINTPTR) rxPtr, nBytes, XAXIDMA_DEVICE_TO_DMA); assert(s == XST_SUCCESS);
  s = XAxiDma_SimpleTransfer(iDma, (UINTPTR) txPtr, nBytes, XAXIDMA_DMA_TO_DEVICE); assert(s == XST_SUCCESS);

  // === start the AXIS stream ===
  const unsigned finalValidWord = nWords-1; // LSBs of
  *ctrlReg = startBit | finalValidWord;

  // === wait for completion ===
  for (;;) {
    //		printf("to CPU, busy:%u from cpu busy:%u\t%08x\t%08x\t%08x\n", (unsigned)XAxiDma_Busy(iDma, XAXIDMA_DEVICE_TO_DMA), (unsigned)XAxiDma_Busy(iDma, XAXIDMA_DMA_TO_DEVICE), (unsigned)(*ctrlReg), (unsigned)(*(ctrlReg+1)), (unsigned)(*(ctrlReg+2)));
    if (!(XAxiDma_Busy(iDma, XAXIDMA_DEVICE_TO_DMA)) &&
	!(XAxiDma_Busy(iDma, XAXIDMA_DMA_TO_DEVICE))) {
      break;
    }
  }
  *ctrlReg = 0;

  // === DMA bypasses cache, must disregard stale cache contents ===
  Xil_DCacheInvalidateRange((UINTPTR)rxPtr, nBytes);

  // === compare ===
  for (unsigned ix = 0; ix < nWords; ++ix){
    //printf("expected: %u\treceived: %u\n", ix, (unsigned)*(rxPtr+ix));
    assert(*(rxPtr+ix) == ix);
  }
  free(txPtr);
  free(rxPtr);
}

int main(){

  // === set up ===
  XAxiDma iDma;
  XAxiDma_Config *CfgPtr;
  CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID); assert(CfgPtr);
  int s;
  s = XAxiDma_CfgInitialize(&iDma, CfgPtr); assert(s == XST_SUCCESS);
  assert(!XAxiDma_HasSg(&iDma) && "got SG DMA RTL");

  // not using interrupts so don't emit them (from example - is this necessary?)
  XAxiDma_IntrDisable(&iDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
  XAxiDma_IntrDisable(&iDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

  for (;;){
    float nWords = 1;
    while (nWords < (float)(1<<(26-2))){
      runTest(&iDma, (unsigned)nWords);
      nWords *= 1.01;
      nWords += 1;
      printf("size %u OK\n", (unsigned)nWords);
    }
  }
}
