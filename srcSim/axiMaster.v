`default_nettype none
`define fail(msg) begin $error(msg); $finish(); end
// Purpose:
// simple axi-lite master, mainly for simulation (read path)
module axilMasterRead
  #(
    parameter integer C_M00_AXI_DATA_WIDTH = 32,
    parameter integer C_M00_AXI_ADDR_WIDTH = 4
    )
   (clk, rst,
    M00_AXI_araddr, M00_AXI_arprot, M00_AXI_arvalid, M00_AXI_arready,
    M00_AXI_rdata, M00_AXI_rresp, M00_AXI_rvalid, M00_AXI_rready,
    start_i, addr_i, 
    doneStrobe_o, receiveData_o, respCode_o);
   
   input wire	      clk;
   input wire	      rst;
   
   output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] M00_AXI_araddr;
   output wire [2:0]			    M00_AXI_arprot;
   output wire				    M00_AXI_arvalid;
   input wire				    M00_AXI_arready;
   input wire [C_M00_AXI_DATA_WIDTH-1 : 0]  M00_AXI_rdata;
   input wire [1:0]			    M00_AXI_rresp;
   input wire				    M00_AXI_rvalid;
   output wire				    M00_AXI_rready;
   
   input wire				    start_i;
   input wire [C_M00_AXI_ADDR_WIDTH-1 : 0]  addr_i;
   output wire				    doneStrobe_o;
   output wire [C_M00_AXI_DATA_WIDTH-1 : 0] receiveData_o;
   output wire [1:0]			    respCode_o;
   
   reg [C_M00_AXI_ADDR_WIDTH-1 : 0]	    addr;
   reg [C_M00_AXI_DATA_WIDTH-1 : 0]	    data;
   reg [1:0]				    respCode;
   
   reg					    addrValid = 1'b0;
   reg					    responseReady = 1'b0;
   reg					    strobe = 1'b0;
   
   localparam				    INVALID = 1'bx;
   localparam				    VALID = 1'b0;   
   assign M00_AXI_araddr = addr + (addrValid ? VALID : INVALID);
   assign M00_AXI_arprot = 2'd0 + (addrValid ? VALID : INVALID);
   assign M00_AXI_arvalid = addrValid;
   
   assign M00_AXI_rready = responseReady;

   assign doneStrobe_o = strobe;   
   assign receiveData_o = data + (strobe ? VALID : INVALID);  
   assign respCode_o = respCode + (strobe ? VALID : INVALID); 
   
   always @(posedge clk) begin
      strobe <= 1'b0;
      
      if (start_i & (addrValid | responseReady))
	`fail("axi master (read): start while busy");
      if (addrValid & responseReady)
	`fail("axi master (read): inconsistent internal state");      
      
      if (start_i) begin
	 addr <= addr_i;
	 addrValid <= 1'b1;
      end

      if (M00_AXI_arvalid & M00_AXI_arready) begin
	 addrValid <= 1'b0;
	 responseReady <= 1'b1;	 
      end

      if (M00_AXI_rvalid & M00_AXI_rready) begin
	 responseReady <= 1'b0;
	 data <= M00_AXI_rdata;
	 respCode <= M00_AXI_rresp;
	 strobe <= 1'b1;
      end
      
      // === reset ===
      if (rst) begin
	 addr <= {C_M00_AXI_ADDR_WIDTH{1'bx}};
	 addrValid <= 1'b0;
	 responseReady <= 1'b0;
      end
   end   
endmodule

// Purpose:
// simple axi-lite master, mainly for simulation (write path)
module axilMasterWrite  
  #(
    parameter integer C_M00_AXI_DATA_WIDTH = 32,
    parameter integer C_M00_AXI_ADDR_WIDTH = 4
    )
   (clk, rst,
    M00_AXI_awaddr, M00_AXI_awprot, M00_AXI_awvalid, M00_AXI_awready,
    M00_AXI_wdata, M00_AXI_wstrb, M00_AXI_wvalid, M00_AXI_wready, 
    M00_AXI_bresp, M00_AXI_bvalid, M00_AXI_bready, 
    start_i, data_i, addr_i, 
    doneStrobe_o, respCode_o);
   
   // AXI side
   input wire	      clk;
   input wire	      rst;
   output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] M00_AXI_awaddr;
   output wire [2:0]			    M00_AXI_awprot;
   output wire				    M00_AXI_awvalid;
   input wire				    M00_AXI_awready;
   output wire [C_M00_AXI_DATA_WIDTH-1 : 0] M00_AXI_wdata;
   output wire [(C_M00_AXI_DATA_WIDTH/8)-1 : 0]	M00_AXI_wstrb;
   output wire					M00_AXI_wvalid;
   input wire					M00_AXI_wready;
   input wire [1:0]				M00_AXI_bresp;
   input wire					M00_AXI_bvalid;
   output wire					M00_AXI_bready;
   
   input wire					start_i;
   input wire [C_M00_AXI_DATA_WIDTH-1 : 0]	data_i;
   input wire [C_M00_AXI_ADDR_WIDTH-1 : 0]	addr_i;
   output wire					doneStrobe_o;
   output wire [1:0]				respCode_o;
   
   reg [C_M00_AXI_ADDR_WIDTH-1 : 0]		addr;
   reg [C_M00_AXI_DATA_WIDTH-1 : 0]		data;
   reg [1:0]					respCode;
   
   reg						addrValid = 1'b0;
   reg						dataValid = 1'b0;
   reg						responseReady = 1'b0;
   reg						strobe = 1'b0;
   
   localparam					INVALID = 1'bx;
   localparam					VALID = 1'b0;   
   
   assign M00_AXI_awaddr = addr + (addrValid ? VALID : INVALID);
   assign M00_AXI_awprot = 2'd0 + (addrValid ? VALID : INVALID);
   assign M00_AXI_awvalid = addrValid;

   assign M00_AXI_wdata = data + (dataValid ? VALID : INVALID);   
   assign M00_AXI_wstrb = 4'hF + (dataValid ? VALID : INVALID);   
   assign M00_AXI_wvalid = dataValid;
   
   assign M00_AXI_bready = responseReady;

   assign doneStrobe_o = strobe;   
   assign respCode_o = respCode + (strobe ? VALID : INVALID); 
   
   always @(posedge clk) begin
      strobe <= 1'b0;
      
      if (start_i & (addrValid | dataValid | responseReady))
	`fail("axi master (read): start while busy");
      if ({1'b0, addrValid} + {1'b0, dataValid} + {1'b0, responseReady} > 2'd1)
	`fail("axi master (read): inconsistent internal state");      
      
      if (start_i) begin
	 addr <= addr_i;
	 data <= data_i;	 
	 addrValid <= 1'b1;
      end

      if (M00_AXI_awvalid & M00_AXI_awready) begin
	 addrValid <= 1'b0;
	 dataValid <= 1'b1;
	 addr <= addr + INVALID;	 
      end
      
      if (M00_AXI_wvalid & M00_AXI_wready) begin
	 data <= data + INVALID;	 
	 dataValid <= 1'b0;	 
	 responseReady <= 1'b1;
      end
      
      if (M00_AXI_bvalid & M00_AXI_bready) begin
	 responseReady <= 1'b0;	 
	 respCode <= M00_AXI_bresp;
	 strobe <= 1'b1;
      end
      
      // === reset ===
      if (rst) begin
	 addr <= addr + INVALID;
	 data <= data + INVALID;	 
	 addrValid <= 1'b0;
	 responseReady <= 1'b0;
      end
   end   
endmodule
