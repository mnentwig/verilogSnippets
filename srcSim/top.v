`default_nettype none
`include "asyncFifo.v"
`define fail(msg) begin $error(msg); $finish(); end

   module pn24(i_clk, o_out);
   input wire 		i_clk;
   output reg [23:0] 	o_out = 24'h1;
   
   always @(posedge i_clk) begin
      o_out <= o_out >> 1;
      o_out[23] <= o_out[0];
      o_out[22] <= o_out[23] ^ o_out[0];
      o_out[21] <= o_out[22] ^ o_out[0];
      o_out[16] <= o_out[17] ^ o_out[0];
   end   
endmodule

module top();
   reg clk = 0;   
   always begin
      #5 clk <= 1;
      #5 clk <= 0;
   end
   initial #100000 $finish();
   initial $dumpfile("a.vcd");
   initial $dumpvars(0, top);

   wire [23:0] rng;   
   pn24 iRng(.i_clk(clk), .o_out(rng));

   localparam  neverEmpty = 1'b0; // option: sink always accepts
   localparam  neverFull = 1'b0; // option: source always has data
   localparam  sourcePlus = 1'b0; // option: source at double capacity
   localparam  sinkPlus = 1'b1; // option: sink at double capacity
         
   reg [31:0]  source = 32'd0;
   wire	       sourceValid = rng[18] | (rng[19] & sourcePlus)| neverEmpty; // a random bit
   wire	       fifoInReady;
   always @(posedge clk) begin
      if (sourceValid & fifoInReady)
	source <= source + 32'd1;      
   end
   
   wire	       fifoOutValid;   
   wire	       sinkReady = rng[6] | (rng[7] & sinkPlus)| neverFull; // a random bit   
   wire [31:0] fifoOut;
   reg [31:0]  sinkRef = 32'd0;
   
   reg	       gotIncorrectResult;
   reg	       gotCorrectResult;
   
   always @(posedge clk) begin
      gotCorrectResult <= 1'b0;
      gotIncorrectResult <= 1'b0;
      
      if (fifoOutValid & sinkReady) begin
	 gotCorrectResult <= (fifoOut == sinkRef);
	 gotIncorrectResult <= (fifoOut != sinkRef);
	 if (fifoOut != sinkRef) 
	   $error("data mismatch");
	 sinkRef <= sinkRef + 32'd1;	 
      end

      if (neverEmpty & !fifoOutValid & (source > 32'd10)) `fail("FIFO should not be empty!");
      if (neverFull & !fifoInReady) `fail("FIFO should not be full!");      
   end

   wire [31:0] outputRegData;
   wire	       outputRegValid;
   wire	       outputRegReady;
   asyncFifo #(.NDATABITS(32)) iFifo
     (.clkW_i(clk), .readyW_o(fifoInReady), .dataW_i(sourceValid ? source : 32'dx), .validW_i(sourceValid), 
//      .clkR_i(clk), .dataR_o(fifoOut), .validR_o(fifoOutValid), .readyR_i(sinkReady));
      .clkR_i(clk), .dataR_o(outputRegData), .validR_o(outputRegValid), .readyR_i(outputRegReady));

   asyncFifoOutputRegister#(.NBITS(32)) iOutReg
     (.clk_i(clk),
      .inData_i(outputRegData), .inValid_i(outputRegValid), .inReady_o(outputRegReady), 
      .outData_o(fifoOut), .outValid_o(fifoOutValid), .outReady_i(sinkReady));
   
endmodule
