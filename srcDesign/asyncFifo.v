module binaryToGray(bin_i, gray_o);
   parameter NBITS = -1;
   input wire [NBITS-1:0] bin_i;
   output wire [NBITS-1:0] gray_o;
   assign gray_o = bin_i ^ (bin_i >> 1); 
endmodule

module grayToBinary(gray_i, bin_o);
   parameter NBITS = -1;
   input wire [NBITS-1:0] gray_i;
   output wire [NBITS-1:0] bin_o;
   generate
      genvar 		   ix;
      for (ix = 0; ix < NBITS; ix = ix + 1) begin
	 assign bin_o[ix] = ^gray_i[NBITS-1:ix];
      end
   endgenerate
endmodule

module grayCodedSynchronizer(clkOutputSide, a_i, b_o);
   parameter		  NBITS=-1;
   parameter		  INITVAL=-1;
   input wire		  clkOutputSide;
   input wire [NBITS-1:0] a_i;
   output wire [NBITS-1:0] b_o;
   
   wire [NBITS-1:0]	   aGray;
   binaryToGray #(.NBITS(NBITS)) b2g(.bin_i(a_i), .gray_o(aGray));
   (*ASYNC_REG="true"*)reg [NBITS-1:0] d1 = INITVAL;
   (*ASYNC_REG="true"*)reg [NBITS-1:0] d2 = INITVAL;
   
   always @(posedge clkOutputSide) begin
      d1 <= aGray;      
      d2 <= d1;      
   end

   grayToBinary #(.NBITS(NBITS)) g2b(.gray_i(d2), .bin_o(b_o));
endmodule

module asyncFifo(clkW_i, dataW_i, readyW_o, validW_i,
		 clkR_i, dataR_o, readyR_i, validR_o);
   // write port
   input wire clkW_i;
   input wire [NDATABITS-1:0] dataW_i;
   output wire		      readyW_o;
   input wire		      validW_i;
   
   // read port
   input wire		      clkR_i;
   output wire [NDATABITS-1:0] dataR_o;
   input wire		       readyR_i;
   output wire		       validR_o;

   // config
   parameter		       NDATABITS=32;
   parameter		       NADDRBITS=3;
   
   localparam		       ADDRZERO = (NADDRBITS+1)'(0);
   localparam		       ADDRONE = (NADDRBITS+1)'(1);
   
   reg [NADDRBITS:0]	       writePtr = ADDRZERO;
   reg [NADDRBITS:0]	       readPtr = ADDRZERO;
   reg [NDATABITS-1:0]	       mem[0:(1 << NADDRBITS)-1];
   
   always @(posedge clkW_i) begin
      if (readyW_o & validW_i) begin
	 mem[writePtr[NADDRBITS-1:0]] <= dataW_i;
	 writePtr <= writePtr + ADDRONE;
      end
   end
   
   always @(posedge clkR_i) begin
      if (readyR_i & validR_o) begin
	 readPtr <= readPtr + ADDRONE;	 
      end
   end

   wire [NADDRBITS:0] writePtrInClkR;   
   grayCodedSynchronizer #(.NBITS(NADDRBITS+1), .INITVAL(ADDRZERO)) cdcWp(.clkOutputSide(clkR_i), .a_i(writePtr), .b_o(writePtrInClkR));

   wire [NADDRBITS:0] readPtrInClkW;   
   grayCodedSynchronizer #(.NBITS(NADDRBITS+1), .INITVAL(ADDRZERO)) cdcRp(.clkOutputSide(clkW_i), .a_i(readPtr), .b_o(readPtrInClkW));
   
   wire		      full = {~writePtr[NADDRBITS], writePtr[NADDRBITS-1:0]} == readPtrInClkW;   
   wire		      empty = readPtr == writePtrInClkR;
   
   assign readyW_o = !full;
   assign validR_o = !empty;

   assign dataR_o = validR_o ? mem[readPtr[NADDRBITS-1:0]] : {NDATABITS{1'bx}}; // note: do not invalidate dataR_o on deasserted ready_i (downstream stage may use data-dependent logic)
endmodule

// place after asyncFifo to enable BRAM read channel hardware register for improved timing
// note: does NOT decouple the outReady_i => inReady_o combinational path to achieve 1 word / clock cycle throughput
module asyncFifoOutputRegister
  (clk_i, 
   inData_i, inReady_o, inValid_i,
   outData_o, outReady_i, outValid_o);

   parameter NBITS=32;   
   input wire clk_i;
   input wire [NBITS-1:0] inData_i;
   output wire		  inReady_o;
   input wire		  inValid_i;
   output wire [NBITS-1:0] outData_o;
   input wire		   outReady_i;
   output wire		   outValid_o;

   localparam		   INVDATA = {NBITS{1'dx}};   
   reg [NBITS-1:0]	   d = INVDATA;
   reg			   valid = 1'b0;

   assign inReady_o = !valid | (outValid_o & outReady_i);
   assign outValid_o = valid;
   assign outData_o = d;   
   always @(posedge clk_i) begin
      if (inValid_i & inReady_o) begin
	 d <= inData_i;
	 valid <= 1'b1;	 
      end else if (outValid_o & outReady_i) begin
	 d <= INVDATA;
	 valid <= 1'b0;
      end
   end
endmodule
