`default_nettype none
`include "axiMaster.v"
`include "axiToReadyValid.v"
`include "rvReg.v"
`define fail(msg) begin $error(msg); $finish(); end

module simTop();
   reg clk = 0;   
   always begin
      #5 clk <= 1;
      #5 clk <= 0;
   end
   initial $dumpfile("a.vcd");
   initial $dumpvars(0, simTop);
   
   reg axi_resetn = 1;
   wire [3:0] axi_awaddr;
   wire	      axi_awvalid;
   wire	      axi_awready;
   wire [31:0] axi_wdata;
   wire	       axi_wvalid;
   wire	       axi_wready;
   
   wire	       axi_bready;
   wire	       axi_bvalid;
   wire [1:0]  axi_bresp;
   
   wire [3:0]  axi_araddr;
   wire	       axi_arvalid;
   wire	       axi_arready;
   wire [31:0] axi_rdata;
   wire	       axi_rvalid;
   wire	       axi_rready;
   wire [1:0]  axi_rresp;
   
   wire [31:0] userA_wData;      
   wire	       userA_wValid;
   wire	       userA_wReady;
   
   wire [31:0] userA_rData;
   wire	       userA_rValid;
   wire	       userA_rReady;
   
   wire [31:0] userB_wData;      
   wire	       userB_wValid;
   wire	       userB_wReady;
   
   wire [31:0] userB_rData;
   wire	       userB_rValid;
   wire	       userB_rReady;
   
   reg	       startW = 1'b0;
   reg [3:0]   addrW;
   reg [31:0]  dataW;
   wire	       strobeW;
   wire [1:0]  respW;   

   reg	       startR = 1'b0;
   reg [3:0]   addrR;
   wire	       strobeR;
   wire [31:0] dataR;
   wire [1:0]  respR;   
   
   axilMasterWrite iAxilMW 
     (.clk(clk),
      .rst(1'b0),
      .M00_AXI_awaddr(axi_awaddr),
      .M00_AXI_awprot(),
      .M00_AXI_awvalid(axi_awvalid),
      .M00_AXI_awready(axi_awready),
      .M00_AXI_wdata(axi_wdata),
      .M00_AXI_wstrb(),
      .M00_AXI_wvalid(axi_wvalid),
      .M00_AXI_wready(axi_wready),
      .M00_AXI_bresp(axi_bresp),
      .M00_AXI_bvalid(axi_bvalid),
      .M00_AXI_bready(axi_bready),
      
      .start_i(startW),
      .addr_i(addrW),
      .data_i(dataW),
      .doneStrobe_o(strobeW),
      .respCode_o(respW));

   axilMasterRead iAxilMR 
     (.clk(clk),
      .rst(1'b0),
      
      .M00_AXI_araddr(axi_araddr), 
      .M00_AXI_arprot(), 
      .M00_AXI_arvalid(axi_arvalid), 
      .M00_AXI_arready(axi_arready),
      .M00_AXI_rdata(axi_rdata),
      .M00_AXI_rresp(axi_rresp),
      .M00_AXI_rvalid(axi_rvalid),
      .M00_AXI_rready(axi_rready),
      .start_i(startR), 
      .addr_i(addrR), 
      .doneStrobe_o(strobeR),
      .receiveData_o(dataR),
      .respCode_o(respR));
   
   axiToReadyValid dut
     (.S00_AXI_aclk(clk), .S00_AXI_aresetn(axi_resetn),
      .S00_AXI_awaddr(axi_awaddr), 
      .S00_AXI_awvalid(axi_awvalid),
      .S00_AXI_awready(axi_awready),
      .S00_AXI_wdata(axi_wdata),
      .S00_AXI_wvalid(axi_wvalid), 
      .S00_AXI_wready(axi_wready),

      .S00_AXI_bready(axi_bready),
      .S00_AXI_bvalid(axi_bvalid),
      .S00_AXI_bresp(axi_bresp),

      .S00_AXI_arvalid(axi_arvalid),
      .S00_AXI_arready(axi_arready),
      .S00_AXI_araddr(axi_araddr),

      .S00_AXI_rvalid(axi_rvalid), 
      .S00_AXI_rready(axi_rready),
      .S00_AXI_rresp(axi_rresp),
      .S00_AXI_rdata(axi_rdata),
      
      .A_wvalid_o(userA_wValid),
      .A_wready_i(userA_wReady),
      .A_wdata_o(userA_wData),
      .A_werror_i(1'b0),

      .A_rready_o(userA_rReady),
      .A_rvalid_i(userA_rValid),
      .A_rdata_i(userA_rData),
      .A_rerror_i(1'b0),
      
      .B_wvalid_o(userB_wValid),
      .B_wready_i(userB_wReady),
      .B_wdata_o(userB_wData),
      .B_werror_i(1'b0),

      .B_rready_o(userB_rReady),
      .B_rvalid_i(userB_rValid),
      .B_rdata_i(userB_rData),
      .B_rerror_i(1'b0));

   rvReg userA
     (.clk(clk), 
      .wv_i(userA_wValid), .wr_o(userA_wReady), .wd_i(userA_wData),
      .rv_o(userA_rValid), .rr_i(userA_rReady), .rd_o(userA_rData));
   
   reg [31:0]  counter = 32'd0;
   initial #100000 begin
      if (counter != 100) `fail("final simulation state not reached - stuck?");
      $display("all OK, finishing");      
      $finish();
   end
   always @(posedge clk) begin
      counter <= counter + 32'd1;
      startW <= 1'b0;     
      addrW <= 4'dx;
      dataW <= 32'dx;
      startR <= 1'b0;
      addrR <= 4'dx;      
      case (counter)
	10: begin
	   startW <= 1'b1;	   
	   addrW <= 4'd0;
	   dataW <= 32'hdeadbeef;	   
	end
	11: begin
	   if (strobeW) begin
	      if (respW != 2'd0) `fail("unexpected write status");	      
	   end else begin
	      counter <= counter;	      
	   end
	end
	20: begin
	   startR <= 1'b1;
	   addrR <= 4'd0;      
	end
	21: begin
	   if (strobeR) begin
	      if (respR != 2'd0) `fail("unexpected read status");
	      if (dataR != 32'hdeadbeef)`fail("unexpected read data");
	   end else begin
	      counter <= counter;
	   end
	end
	100: counter <= counter; // stop here for final check	 
      endcase      
   end   
endmodule
