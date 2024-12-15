`default_nettype none
module AXIS_sampleMaster
  #(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
    )
   (// AXI side; generated via Vivado 'package IP' feature
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

    // AXIS master port (clk from AXI slave)
    input wire					axis_aclk, // this must be identical to S00_AXI_aclk
    output wire [31:0]				axis_tdata,
    output wire [3:0]				axis_tkeep,
    output wire					axis_tlast,
    output wire					axis_tvalid,
    input wire					axis_tready);
   
   wire [31:0]					portA_writeData;
   wire						portA_writeValid;
   wire						portA_writeReady = 1'b1;
   
   localparam					regA_resetValue = 32'd0;
   reg [31:0]					regA = regA_resetValue;
   
   // === word counter ===
   // 0, 1, 2, (nWords-1), nWords
   // one extra bit for "done" state after sending 26-bit max. payload
   // initialize with large number => not "valid" at power-up
   reg [26:0]					ctr = ~27'd0;   
   
   axiToReadyValid iAxiToReadyValid
     (.S00_AXI_aclk(S00_AXI_aclk),
      .S00_AXI_aresetn(S00_AXI_aresetn),
      .S00_AXI_awaddr(S00_AXI_awaddr),
      .S00_AXI_awprot(S00_AXI_awprot),
      .S00_AXI_awvalid(S00_AXI_awvalid),
      .S00_AXI_awready(S00_AXI_awready),
      .S00_AXI_wdata(S00_AXI_wdata),
      .S00_AXI_wstrb(S00_AXI_wstrb),
      .S00_AXI_wvalid(S00_AXI_wvalid),
      .S00_AXI_wready(S00_AXI_wready),
      .S00_AXI_bresp(S00_AXI_bresp),
      .S00_AXI_bvalid(S00_AXI_bvalid),
      .S00_AXI_bready(S00_AXI_bready),
      .S00_AXI_araddr(S00_AXI_araddr),
      .S00_AXI_arprot(S00_AXI_arprot),
      .S00_AXI_arvalid(S00_AXI_arvalid),
      .S00_AXI_arready(S00_AXI_arready),
      .S00_AXI_rdata(S00_AXI_rdata),
      .S00_AXI_rresp(S00_AXI_rresp),
      .S00_AXI_rvalid(S00_AXI_rvalid),
      .S00_AXI_rready(S00_AXI_rready),

      // port A at ((char*)baseaddr + 0)
      .A_wvalid_o(portA_writeValid),
      .A_wready_i(portA_writeReady),
      .A_werror_i(1'b0),
      .A_wdata_o(portA_writeData),
      .A_rvalid_i(1'b1),
      .A_rready_o(),
      .A_rdata_i(regA),
      .A_rerror_i(1'b0),

      // port B at ((char*)baseaddr + 4)
      .B_wvalid_o(),
      .B_wdata_o(),
      .B_wready_i(1'b1),
      .B_werror_i(1'b0),
      .B_rvalid_i(1'b1),
      .B_rdata_i({5'd0, ctr}),
      .B_rerror_i(1'b0),

      // port C at ((char*)baseaddr + 8)
      .C_wvalid_o(),
      .C_wdata_o(),
      .C_wready_i(1'b1),
      .C_werror_i(1'b0),
      .C_rvalid_i(1'b1),
      .C_rdata_i(32'd0),
      .C_rerror_i(1'b0),
      
      // port C at ((char*)baseaddr + 0xC)
      .D_wvalid_o(),
      .D_wdata_o(),
      .D_wready_i(1'b1),
      .D_werror_i(1'b0),
      .D_rvalid_i(1'b1),
      .D_rdata_i(32'd0),
      .D_rerror_i(1'b0));
   
   wire						clk = S00_AXI_aclk;   
   always @(posedge clk) begin
      if (portA_writeValid & portA_writeReady)
	regA <= portA_writeData;
      if (!S00_AXI_aresetn) begin	 
	 regA <= regA_resetValue;
      end
   end
   
   wire ena = regA[31];
   wire [25:0] nWordsMinusOne = regA[25:0];
   assign axis_tvalid = ena && (ctr <= {1'b0, nWordsMinusOne});
   assign axis_tdata = {5'd0, ctr};
   assign axis_tlast = axis_tvalid && (ctr == {1'b0, nWordsMinusOne});
   assign axis_tkeep = axis_tvalid ? 4'hf : 4'h0;   
   always @(posedge axis_aclk) begin
      if (!ena)
	ctr <= 27'd0;	 
      else if (axis_tvalid & axis_tready) // stops 1 step after final value with deassertion of "valid"
	ctr <= ctr + 27'd1;
   end   
endmodule
