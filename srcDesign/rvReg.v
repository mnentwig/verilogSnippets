// simple register with ready-/valid protocol
module rvReg
  #(parameter INITVAL = 32'd0,
    parameter DATA_WIDTH = 32)
   (clk, 
    wv_i, wr_o, wd_i,
    rv_o, rr_i, rd_o);
   input wire clk;

   input wire wv_i;
   output wire wr_o;
   input wire [DATA_WIDTH-1:0] wd_i;
   
   input wire		       rr_i;
   output wire		       rv_o;
   output wire [DATA_WIDTH-1:0] rd_o;
   
   assign wr_o = 1'b1;
   assign rv_o = 1'b1;
   assign rd_o = mem;
   
   reg [DATA_WIDTH-1:0]	mem;
   always @(posedge clk)
     if (wr_o & wv_i)
       mem <= wd_i;   
endmodule
