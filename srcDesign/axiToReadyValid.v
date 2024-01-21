// Purpose:
// Provides four ready-/valid style interfaces with read- and write channel at address 0x0, 0x4, 0x8, 0xC
// error port to signal invalid access e.g. read- or write only
module axiToReadyValid 
  #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
    )
   (
    // AXI side; generated via Vivado 'package IP' feature
    input wire					S00_AXI_aclk,
    input wire					S00_AXI_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]	S00_AXI_awaddr,
    input wire [2:0]				S00_AXI_awprot,
    input wire					S00_AXI_awvalid,
    output wire					S00_AXI_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]	S00_AXI_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0]	S00_AXI_wstrb,
    input wire					S00_AXI_wvalid,
    output wire					S00_AXI_wready,
    output wire [1:0]				S00_AXI_bresp,
    output wire					S00_AXI_bvalid,
    input wire					S00_AXI_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]	S00_AXI_araddr,
    input wire [2:0]				S00_AXI_arprot,
    input wire					S00_AXI_arvalid,
    output wire					S00_AXI_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]	S00_AXI_rdata,
    output wire [1:0]				S00_AXI_rresp,
    output wire					S00_AXI_rvalid,
    input wire					S00_AXI_rready,

    // User port A
    output wire					A_wvalid_o,
    input wire					A_wready_i,
    input wire					A_werror_i,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]	A_wdata_o,
    input wire					A_rvalid_i,
    output wire					A_rready_o,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]	A_rdata_i,
    input wire					A_rerror_i,

    // User port B
    output wire					B_wvalid_o,
    input wire					B_wready_i,
    input wire					B_werror_i,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]	B_wdata_o,
    input wire					B_rvalid_i,
    output wire					B_rready_o,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]	B_rdata_i,
    input wire					B_rerror_i,

    // User port C
    output wire					C_wvalid_o,
    input wire					C_wready_i,
    input wire					C_werror_i,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]	C_wdata_o,
    input wire					C_rvalid_i,
    output wire					C_rready_o,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]	C_rdata_i,
    input wire					C_rerror_i,

    // User port D
    output wire					D_wvalid_o,
    input wire					D_wready_i,
    input wire					D_werror_i,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]	D_wdata_o,
    input wire					D_rvalid_i,
    output wire					D_rready_o,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]	D_rdata_i,
    input wire					D_rerror_i
    );

   // === write address "channel" ===
   // - closes on reception of write address from AXI
   // - opens on completion of write transaction at user port
   assign S00_AXI_awready = !writeAddrValid;
   
   // === read address "channel" ===
   // - closes on reception of read address from AXI
   // - opens on completion of read transaction at user port
   assign S00_AXI_arready = !readChanOpen;
   
   // === write address ===
   // - becomes valid on receiving write address from AXI
   // - becomes invalid on completion of write transaction at user port
   reg						writeAddrValid = 1'b0;
   reg [1:0]					writeChanAddr;

   // === write path ===
   // requires both the write address (which comes first per the AXI protocol) and AXI data
   wire						writePathValid = writeAddrValid & S00_AXI_wvalid;
   
   assign A_wvalid_o = writePathValid & (writeChanAddr == 2'd0);
   assign B_wvalid_o = writePathValid & (writeChanAddr == 2'd1);
   assign C_wvalid_o = writePathValid & (writeChanAddr == 2'd2);
   assign D_wvalid_o = writePathValid & (writeChanAddr == 2'd3);
   
   assign A_wdata_o = S00_AXI_wdata + (A_wvalid_o ? VALID : INVALID);
   assign B_wdata_o = S00_AXI_wdata + (B_wvalid_o ? VALID : INVALID);   
   assign C_wdata_o = S00_AXI_wdata + (C_wvalid_o ? VALID : INVALID);   
   assign D_wdata_o = S00_AXI_wdata + (D_wvalid_o ? VALID : INVALID);   
   
   // === write response "channel" ===
   // - opens on completion of write transaction at user port
   // - closes on completion of "bresp" transaction at AXI port
   reg						writeRespOpen = 1'd0;
   reg [1:0]					bresp;
   assign S00_AXI_bvalid = writeRespOpen;   
   assign S00_AXI_bresp = bresp;

   // === read channel ===
   // - opens on receiving read address
   // - closes on completed read transaction at user port
   reg						readChanOpen = 1'b0;
   reg [1:0]					readChanAddr;

   // === read response "channel" ===
   // - opens on completion of read transaction at user port
   // - closes on completion of "rresp" transaction at AXI port
   reg						readRespValid = 1'd0;
   reg [1:0]					rresp;
   reg [31:0]					rdata;   
   assign S00_AXI_rvalid = readRespValid;   
   assign S00_AXI_rresp = rresp + (readRespValid ? VALID : INVALID);   
   assign S00_AXI_rdata = rdata + (readRespValid ? VALID : INVALID);   
   
   // disable all "x" for Vivado mod. integration
   // - adding 1'b0 changes nothing and gets optimized away (implementation)
   // - adding 1'bx invalidates all bits (simulation)
   localparam					VALID = 1'b0;
`ifdef SIM
   localparam					INVALID = 1'bx;
`else
   localparam					INVALID = 1'b0;
`endif
   
   
   assign A_rready_o = readChanOpen & (readChanAddr == 2'd0);
   assign B_rready_o = readChanOpen & (readChanAddr == 2'd1);
   assign C_rready_o = readChanOpen & (readChanAddr == 2'd2);
   assign D_rready_o = readChanOpen & (readChanAddr == 2'd3);

   wire						user_wvalid [0:3];
   assign user_wvalid[0] = A_wvalid_o;
   assign user_wvalid[1] = B_wvalid_o;
   assign user_wvalid[2] = C_wvalid_o;
   assign user_wvalid[3] = D_wvalid_o;
      
   wire						user_wready [0:3];
   assign user_wready[0] = A_wready_i;
   assign user_wready[1] = B_wready_i;
   assign user_wready[2] = C_wready_i;
   assign user_wready[3] = D_wready_i;
   assign S00_AXI_wready = writeAddrValid & user_wready[writeChanAddr];   
   
   wire						user_rvalid [0:3];
   assign user_rvalid[0] = A_rvalid_i;
   assign user_rvalid[1] = B_rvalid_i;
   assign user_rvalid[2] = C_rvalid_i;
   assign user_rvalid[3] = D_rvalid_i;
   
   wire						user_rready[0:3];
   assign user_rready[0] = A_rready_o;
   assign user_rready[1] = B_rready_o;
   assign user_rready[2] = C_rready_o;
   assign user_rready[3] = D_rready_o;
   
   // === bresp ===
   wire						user_errorWrite[0:3];
   assign user_errorWrite[0] = A_werror_i;
   assign user_errorWrite[1] = B_werror_i;
   assign user_errorWrite[2] = C_werror_i;
   assign user_errorWrite[3] = D_werror_i;
      
   // === rresp ===
   wire						user_errorRead[0:3];
   assign user_errorRead[0] = A_rerror_i;
   assign user_errorRead[1] = B_rerror_i;
   assign user_errorRead[2] = C_rerror_i;
   assign user_errorRead[3] = D_rerror_i;
   
   // === read data ===
   wire [C_S00_AXI_DATA_WIDTH-1 : 0]		user_dataRead[0:3];
   assign user_dataRead[0] = A_rdata_i;
   assign user_dataRead[1] = B_rdata_i;
   assign user_dataRead[2] = C_rdata_i;
   assign user_dataRead[3] = D_rdata_i;
   
   always @(posedge S00_AXI_aclk) begin
      // === write chan: start (axi, load address) ===
      if (S00_AXI_awready & S00_AXI_awvalid) begin
	 writeChanAddr <= S00_AXI_awaddr[3:2];
	 writeAddrValid <= 1'b1;	 
      end
      
      // === read chan: start (axi, load address) ===
      if (S00_AXI_arready & S00_AXI_arvalid) begin
	 readChanAddr <= S00_AXI_araddr[3:2];
	 readChanOpen <= 1'b1;	 
      end

      // === write chan: user signals completion ===
      if (user_wvalid[writeChanAddr] & user_wready[writeChanAddr]) begin
	 bresp <= user_errorWrite[writeChanAddr] ? /*SLVERR*/2'b10 : /*OKAY*/2'b00;
	 writeRespOpen <= 1'b1;
	 writeAddrValid <= 1'd0;	 
	 writeChanAddr <= 2'dx;	 
      end
      
      // === read chan: user signals completion ===
      if (user_rvalid[readChanAddr] & user_rready[readChanAddr]) begin
	 rresp <= user_errorRead[readChanAddr] ? /*SLVERR*/2'b10 : /*OKAY*/2'b00;
	 rdata <= user_dataRead[readChanAddr];
	 readRespValid <= 1'b1;
	 readChanOpen <= 1'd0;	 
	 readChanAddr <= 2'dx; 
      end
      
      // === write chan: axi collects response ===
      if (S00_AXI_bready & S00_AXI_bvalid) begin
	 writeRespOpen <= 1'b0;
	 bresp <= 2'dx;	 
      end

      // === read chan: axi collects response ===
      if (S00_AXI_rready & S00_AXI_rvalid) begin
	 readRespValid <= 1'b0;
	 rresp <= 2'dx;
      end

      // === reset ===
      if (!S00_AXI_aresetn) begin
	 writeRespOpen <= 1'd0;
	 bresp <= 2'dx;
	 readRespValid <= 1'd0;
	 rresp <= 2'dx;
	 writeAddrValid <= 1'd0;
	 writeChanAddr <= 2'dx;
	 readChanOpen <= 1'd0;
	 readChanAddr <= 2'dx;
      end
   end
endmodule
