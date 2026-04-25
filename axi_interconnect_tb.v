`timescale 1ns/1ps
module axi_interconnect_tb ();



// ==========================================
// KHAI BÁO TÍN HIỆU ĐẦU VÀO (INPUT -> reg)
// ==========================================

// Global Signals
reg ACLK_i;
reg ARESETn_i;

// Master Interface Inputs (m_..._i)
reg        m_ARVALID_i;
reg        m_AWVALID_i;
reg        m_BREADY_i;
reg        m_RREADY_i;
reg        m_WLAST_i;
reg        m_WVALID_i;
reg [4:0]  m_AWID_i;
reg [31:0] m_AWADDR_i;
reg [1:0]  m_AWBURST_i;
reg [2:0]  m_AWLEN_i;
reg [2:0]  m_AWSIZE_i;
reg [31:0] m_WDATA_i;
reg [4:0]  m_ARID_i;
reg [31:0] m_ARADDR_i;
reg [1:0]  m_ARBURST_i;
reg [2:0]  m_ARLEN_i;
reg [2:0]  m_ARSIZE_i;

// Slave Interface Inputs (s_..._i)
reg [1:0]  s_AWREADY_i;
reg [1:0]  s_WREADY_i;
reg [9:0]  s_BID_i;
reg [3:0]  s_BRESP_i;
reg [1:0]  s_BVALID_i;
reg [1:0]  s_ARREADY_i;
reg [9:0]  s_RID_i;
reg [63:0] s_RDATA_i;
reg [3:0]  s_RRESP_i;
reg [1:0]  s_RLAST_i;
reg [1:0]  s_RVALID_i;

// ==========================================
// KHAI BÁO TÍN HIỆU ĐẦU RA (OUTPUT -> wire)
// ==========================================

// Master Interface Outputs (m_..._o)
wire        m_ARREADY_o;
wire        m_AWREADY_o;
wire        m_BVALID_o;
wire        m_RLAST_o;
wire        m_RVALID_o;
wire        m_WREADY_o;
wire [4:0]  m_BID_o;
wire [1:0]  m_BRESP_o;
wire [4:0]  m_RID_o;
wire [31:0] m_RDATA_o;
wire [1:0]  m_RRESP_o;

// Slave Interface Outputs (s_..._o)
wire [9:0]  s_AWID_o;
wire [63:0] s_AWADDR_o;
wire [3:0]  s_AWBURST_o;
wire [5:0]  s_AWLEN_o;
wire [5:0]  s_AWSIZE_o;
wire [1:0]  s_AWVALID_o;
wire [63:0] s_WDATA_o;
wire [1:0]  s_WLAST_o;
wire [1:0]  s_WVALID_o;
wire [1:0]  s_BREADY_o;
wire [9:0]  s_ARID_o;
wire [63:0] s_ARADDR_o;
wire [3:0]  s_ARBURST_o;
wire [5:0]  s_ARLEN_o;
wire [5:0]  s_ARSIZE_o;
wire [1:0]  s_ARVALID_o;
wire [1:0]  s_RREADY_o;

    axi_interconnect #(
        .MST_AMT(1),
        .SLV_AMT(2)
    ) dut ( 
        // Global
    .ACLK_i         (ACLK_i),
    .ARESETn_i      (ARESETn_i),
    
    // Master Inputs
    .m_ARVALID_i    (m_ARVALID_i),
    .m_AWVALID_i    (m_AWVALID_i),
    .m_BREADY_i     (m_BREADY_i),
    .m_RREADY_i     (m_RREADY_i),
    .m_WLAST_i      (m_WLAST_i),
    .m_WVALID_i     (m_WVALID_i),
    .m_AWID_i       (m_AWID_i),
    .m_AWADDR_i     (m_AWADDR_i),
    .m_AWBURST_i    (m_AWBURST_i),
    .m_AWLEN_i      (m_AWLEN_i),
    .m_AWSIZE_i     (m_AWSIZE_i),
    .m_WDATA_i      (m_WDATA_i),
    .m_ARID_i       (m_ARID_i),
    .m_ARADDR_i     (m_ARADDR_i),
    .m_ARBURST_i    (m_ARBURST_i),
    .m_ARLEN_i      (m_ARLEN_i),
    .m_ARSIZE_i     (m_ARSIZE_i),

    // Slave Inputs
    .s_AWREADY_i    (s_AWREADY_i),
    .s_WREADY_i     (s_WREADY_i),
    .s_BID_i        (s_BID_i),
    .s_BRESP_i      (s_BRESP_i),
    .s_BVALID_i     (s_BVALID_i),
    .s_ARREADY_i    (s_ARREADY_i),
    .s_RID_i        (s_RID_i),
    .s_RDATA_i      (s_RDATA_i),
    .s_RRESP_i      (s_RRESP_i),
    .s_RLAST_i      (s_RLAST_i),
    .s_RVALID_i     (s_RVALID_i),

    // Master Outputs
    .m_ARREADY_o    (m_ARREADY_o),
    .m_AWREADY_o    (m_AWREADY_o),
    .m_BVALID_o     (m_BVALID_o),
    .m_RLAST_o      (m_RLAST_o),
    .m_RVALID_o     (m_RVALID_o),
    .m_WREADY_o     (m_WREADY_o),
    .m_BID_o        (m_BID_o),
    .m_BRESP_o      (m_BRESP_o),
    .m_RID_o        (m_RID_o),
    .m_RDATA_o      (m_RDATA_o),
    .m_RRESP_o      (m_RRESP_o),

    // Slave Outputs
    .s_AWID_o       (s_AWID_o),
    .s_AWADDR_o     (s_AWADDR_o),
    .s_AWBURST_o    (s_AWBURST_o),
    .s_AWLEN_o      (s_AWLEN_o),
    .s_AWSIZE_o     (s_AWSIZE_o),
    .s_AWVALID_o    (s_AWVALID_o),
    .s_WDATA_o      (s_WDATA_o),
    .s_WLAST_o      (s_WLAST_o),
    .s_WVALID_o     (s_WVALID_o),
    .s_BREADY_o     (s_BREADY_o),
    .s_ARID_o       (s_ARID_o),
    .s_ARADDR_o     (s_ARADDR_o),
    .s_ARBURST_o    (s_ARBURST_o),
    .s_ARLEN_o      (s_ARLEN_o),
    .s_ARSIZE_o     (s_ARSIZE_o),
    .s_ARVALID_o    (s_ARVALID_o),
    .s_RREADY_o     (s_RREADY_o)
);

    initial begin
        // ==========================================
        // KHỞI TẠO TÍN HIỆU ĐẦU VÀO = 0
        // ==========================================

        // Master Interface Inputs (m_..._i)
        m_ARVALID_i = 1'b0;
        m_AWVALID_i = 1'b0;
        m_BREADY_i  = 1'b0;
        m_RREADY_i  = 1'b0;
        m_WLAST_i   = 1'b0;
        m_WVALID_i  = 1'b0;
        m_AWID_i    = 5'd0;
        m_AWADDR_i  = 32'd0;
        m_AWBURST_i = 2'd0;
        m_AWLEN_i   = 3'd0;
        m_AWSIZE_i  = 3'd0;
        m_WDATA_i   = 32'd0;
        m_ARID_i    = 5'd0;
        m_ARADDR_i  = 32'd0;
        m_ARBURST_i = 2'd0;
        m_ARLEN_i   = 3'd0;
        m_ARSIZE_i  = 3'd0;

        // Slave Interface Inputs (s_..._i)
        s_AWREADY_i = 2'd0;
        s_WREADY_i  = 2'd0;
        s_BID_i     = 10'd0;
        s_BRESP_i   = 4'd0;
        s_BVALID_i  = 2'd0;
        s_ARREADY_i = 2'd0;
        s_RID_i     = 10'd0;
        s_RDATA_i   = 64'd0;
        s_RRESP_i   = 4'd0;
        s_RLAST_i   = 2'd0;
        s_RVALID_i  = 2'd0;
    end

    always begin
        #10 ACLK_i <= ~ACLK_i;
    end

    integer i;
    // bat dau testbench
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, axi_interconnect_tb);
        ACLK_i = 1'b0;
        // system reset 
        ARESETn_i = 1'b0;
        #100;
        ARESETn_i = 1'b1;
        #100;

        fork

            // master
            begin 
                #100;
                // chuan bi data
                @(posedge ACLK_i);
                m_ARADDR_i <= 0; // slave 0
                m_ARSIZE_i <= 3'b101; // 32 bit 
                m_ARLEN_i <= 3;
                m_ARBURST_i <= 2'b01;
                m_ARVALID_i <= 1'b1; // bat tin hieu valid len 1
                wait(m_ARREADY_o == 1'b1); // doi slave ready nhan du lieu
                @(posedge ACLK_i);
                m_ARVALID_i <= 1'b0; // keo tin hieu valid xuong 0 sau khi slave nhan du lieu

                $display("Master sent address and control successfully! at %d", $time);

                wait (m_RVALID_o == 1'b1 ); // doi slave tra data ve
                @(posedge ACLK_i);
                m_RREADY_i <= 1'b1;
                i <= 0;
                while (i < 4) begin
                    @(posedge ACLK_i);
                    if (m_RVALID_o == 1'b1) begin
                        i = i + 1;
                    end
                end
                $display("Master successfully received 4 transfers from slave 0 at %d", $time);
                #40;

            end

            // slave 0
            begin
                wait(s_ARVALID_o[0] == 1'b1);
                @(posedge ACLK_i);
                s_ARREADY_i[0] <= 1'b1;

                $display("Slave 0 received address from master at %d", $time);

                @(posedge ACLK_i);
                s_ARREADY_i <= 1'b0;
                s_RDATA_i[31:0] <= 32'd1; 
                s_RRESP_i[1:0]  <= 2'b00; 
                s_RVALID_i[0] <= 1'b1;

                wait (s_RREADY_o[0] == 1'b1);
                @(posedge ACLK_i);
                s_RDATA_i[31:0] <= 32'd2;
                wait(s_RREADY_o[0] == 1'b1);
                @(posedge ACLK_i);
                s_RDATA_i[31:0] <= 32'd3;
                wait(s_RREADY_o[0] == 1'b1);
                @(posedge ACLK_i);
                s_RDATA_i[31:0] <= 32'd4;
                s_RLAST_i <= 1'b1;
                wait(s_RREADY_o[0] == 1'b1);
                @(posedge ACLK_i);
                s_RVALID_i <= 1'b0;
                $display("Slave 0 successfully sentt 4 transfers at %d", $time);
                #100;
            end
        join
        #1000;
        $finish;
    end

    // timeout
    initial begin
        #10000;
        $display("TIMEOUT!. The simulation has been forced to stop at %d", $time);
        $finish;
    end
endmodule