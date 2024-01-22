`default_nettype none
`include "axiToReadyValid.v"
`include "rvReg.v"
`define fail(msg) begin $error(msg); $finish(); end

module simTop();
   reg clk = 0;   
   always begin
      #5 clk <= 1;
      #5 clk <= 0;
   end
   initial #100000 $finish();
   initial $dumpfile("a.vcd");
   initial $dumpvars(0, simTop);

   reg axi_resetn = 1;
   reg [3:0] axi_awaddr;
   reg	      axi_awvalid;
   wire	      axi_awready;
   reg [31:0] axi_wdata;
   reg	      axi_wvalid;
   wire	      axi_wready;
   
   reg	      axi_bready;
   wire	      axi_bvalid;
   wire [1:0] axi_bresp;

   reg [3:0]  axi_araddr;
   reg	      axi_arvalid;
   wire	      axi_arready;
   reg [31:0] axi_rdata;
   reg	      axi_rvalid;
   reg	      axi_rready;
   wire [1:0] axi_rresp;
   
   wire [31:0] userA_wData;      
   wire	       userA_wValid;
   reg	       userA_wReady = 0;

   reg [31:0]  userA_rData;
   reg	       userA_rValid = 0;
   wire	       userA_rReady;

   wire [31:0] userB_wData;      
   wire	       userB_wValid;
   wire	       userB_wReady;
   
   wire [31:0] userB_rData;
   reg	       userB_rValid;
   wire	       userB_rReady;
   
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

   rvReg userB
     (.clk(clk), 
      .wv_i(userB_wValid), .wr_o(userB_wReady), .wd_i(userB_wData),
      .rv_o(userB_rValid), .rr_i(userB_rReady), .rd_o(userB_rData));
   
   reg [31:0]  counter = 32'd0;
   always @(posedge clk) begin
      counter <= counter + 32'd1;
      axi_awvalid <= 0;
      axi_awaddr <= 32'dx;
      axi_wvalid <= 0;
      axi_wdata <= 32'dx;
      axi_wvalid <= 0;
      axi_bready <= 0;

      axi_arvalid <= 0;
      axi_araddr <= 32'dx;
      axi_rready <= 0;

      userA_wReady <= 0;
      userA_rValid <= 0;
      userA_rData <= 32'bx;      
            
      case (counter)
	10: begin
	   axi_awaddr <= 0;
	   axi_awvalid <= 1;	   
	end
	11: 
	  if (!(axi_awvalid & axi_awready)) begin
	     // hold
	     axi_awaddr <= axi_awaddr;
	     axi_awvalid <= axi_awvalid;
	     counter <= counter;
	  end
	
	15: begin
	   // write on AXI bus
  	   axi_wvalid <= 1;
	   axi_wdata <= 32'hdeadbeef;	      
	end

	16: begin
  	   axi_wvalid <= axi_wvalid;
	   axi_wdata <= axi_wdata;
	   if (!userA_wValid) `fail("expected userA_wValid");
	   if (userA_wData != 32'hdeadbeef) `fail("userA unexpected write value");	   	   
	   userA_wReady <= 1;
	end

	23: begin
	   axi_bready <= 1;
	   if (!axi_bvalid) `fail("expected axi_bvalid");
 	   if (axi_bresp != 2'd0) `fail("expected bresp==OKAY");
	end
	25: begin
	   if (axi_bvalid) `fail("not expected axi_bvalid");
	end

	30: begin
	   axi_araddr <= 0;
	   axi_arvalid <= 1;	   
	end

	35: begin
	   if (!userA_rReady) `fail("expecting userA_rReady");
	   userA_rValid <= 1;
	   userA_rData <= 32'h12345678;	   
	end

	40: begin
	   if (!axi_rvalid) `fail("expected axi_rvalid");
	   if (axi_rresp != 2'd0) `fail("expected rresp==OKAY");
	   if (axi_rdata != 32'h12345678)`fail("incorrect readback data");
	   axi_rready <= 1;	   
	end
	
	42: begin
	   if (axi_rvalid) `fail("not expected axi_rvalid");
	end

	// write to port B
	50: begin
	   axi_awaddr <= 4;
	   axi_awvalid <= 1;	   
	end
	51: 
	  if (!(axi_awvalid & axi_awready)) begin
	     // hold
	     axi_awaddr <= axi_awaddr;
	     axi_awvalid <= axi_awvalid;
	     counter <= counter;
	  end
	55: begin
	   // write on AXI bus
  	   axi_wvalid <= 1;
	   axi_wdata <= 32'h10203040;	      
	end

	60: begin
	   axi_bready <= 1;
	   if (!axi_bvalid) `fail("expected axi_bvalid");
 	   if (axi_bresp != 2'd0) `fail("expected bresp==OKAY");
	end
	62: begin
	   if (axi_bvalid) `fail("not expected axi_bvalid");
	end

	70: begin
	   axi_araddr <= 4;
	   axi_arvalid <= 1;	   
	end

	75: begin
	   if (!axi_rvalid) `fail("expected axi_rvalid");
	   if (axi_rresp != 2'd0) `fail("expected rresp==OKAY");
	   if (axi_rdata != 32'h10203040)`fail("incorrect readback data");
	   axi_rready <= 1;
	end
	
	77: begin
	   if (axi_rvalid) `fail("not expected axi_rvalid");
	end
      endcase      
   end   
endmodule
