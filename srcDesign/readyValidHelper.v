// to see preprocessor output, use 
// iverilog -E readyValidHelper.v; cat a.out
`define readyValidWire(wireName, nBits) wire ``wireName``Ready; wire ``wireName``Valid; wire [nBits-1:0] wireName``Data;

`define readyValidInput(wireName, portName) .``portName``Ready_o(``wireName``Ready), ``.``portName``Valid_i(``wireName``Valid), ``.``portName``Data_i(``wireName``Data)``
`define readyValidOutput(wireName, portName) .``portName``Ready_i(``wireName``Ready), ``.``portName``Valid_o(``wireName``Valid), ``.``portName``Data_o(``wireName``Data)``


`define readyValidInputPortlistNonANSI1(portName) portName``Ready_o, portName``Valid_i, portName``Data_i
`define readyValidInputPortlistNonANSI2(portName, nBits) output wire ``portName``Ready_o; input wire ``portName``Valid_i; input wire [nBits-1:0] portName``Data_i;
`define readyValidInputPortlistANSI(portName, nBits) output wire ``portName``Ready_o, input wire ``portName``Valid_i, input wire [nBits-1:0] portName``Data_i;

`define readyValidOutputPortlistNonANSI1(portName) portName``Ready_i, portName``Valid_o, portName``Data_o
`define readyValidOutputPortlistNonANSI2(portName, nBits) input wire ``portName``Ready_i; output wire ``portName``Valid_o; output wire [nBits-1:0] portName``Data_o;
`define readyValidOutputPortlistANSI(portName, nBits) input wire ``portName``Ready_i, output wire ``portName``Valid_o, output wire [nBits-1:0] portName``Data_o

`ifdef SIM_READYVALIDHELPER
`default_nettype none
module myRvSourceNonANSI(clk_i, `readyValidOutputPortlistNonANSI1(myNonAnsiPort));
   parameter NBITS=32;
   input wire clk_i;   
   `readyValidOutputPortlistNonANSI2(myNonAnsiPort, NBITS)
   reg [NBITS-1:0] valCount = 0;
   reg [3:0]	   timeCount = 0;
   
   reg [31:0]	   data;
   reg		   valid = 1'b0;
   assign myNonAnsiPortValid_o = valid;
   assign myNonAnsiPortData_o = valid ? data : 32'bx;
   wire	      fetch = myNonAnsiPortValid_o & myNonAnsiPortReady_i;
   
   // arbitrary gate on data availability
   wire	      load = !{timeCount[3], timeCount[1]};
   always @(posedge clk_i) begin
      timeCount <= timeCount + 1;      
      
      if (fetch) 
	valid <= 1'b0;
      
      if (load & (!valid | fetch)) begin
	 valid <= 1'b1;
	 data <= valCount;
	 valCount <= valCount + 32'd1;
      end
   end
endmodule

module myRvSourceANSI(input wire clk_i, `readyValidOutputPortlistANSI(myAnsiPort, 32));
   parameter NBITS=32;   
`readyValidWire(myWire, 32)
   assign myAnsiPortValid_o = myWireValid;
   assign myAnsiPortData_o = myWireData;
   assign myWireReady = myAnsiPortReady_i;
   
   myRvSourceNonANSI #(.NBITS(NBITS)) iSrc (`readyValidOutput(myWire, myNonAnsiPort));
endmodule

module myRvSinkNonANSI(clk_i, `readyValidInputPortlistNonANSI1(myNonAnsiPort));
   parameter NBITS=32;
   input wire clk_i;
   
   `readyValidInputPortlistNonANSI2(myNonAnsiPort, NBITS)
   assign myNonAnsiPortReady_o = 1'b1;
   
   always @(posedge clk_i)
     if (myNonAnsiPortReady_o & myNonAnsiPortValid_i)
       $display("%08d", myNonAnsiPortData_i);   
endmodule

module top();   
   reg clk = 1'b0;
   localparam NBITS=32;
   
   always begin 
      #5 clk <= 1'b1;
      #5 clk <= 1'b0;
   end
   
   initial #10000 $finish();   
   initial $dumpfile("a.vcd");
   initial $dumpvars(0, top);
   
   `readyValidWire(myWire1, 32);
   assign myWire1Ready = 1'b1;
   
   myRvSourceNonANSI #(.NBITS(NBITS)) iSrc1 (.clk_i(clk), `readyValidOutput(myWire1, myNonAnsiPort)); 
endmodule
`endif
