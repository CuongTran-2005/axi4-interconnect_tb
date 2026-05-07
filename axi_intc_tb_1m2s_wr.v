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


// master device control signals

reg     [4:0]       m_address_memory;
reg                 m_READ_EN;
reg     [32-1:0]    m_DATA_MEMORY_i; 
reg                 m_WRITE_EN;
wire    [32-1:0]    m_DATA_MEMORY_o; 

reg                 ReadTrans_EN_i;
reg     [4:0]       r_set_addr_memory;
reg     [32-1:0]    set_ARADDR_i;
reg     [1:0]       set_ARBURST_i;
reg     [7:0]       set_ARLEN_i; 
reg     [2:0]       set_ARSIZE_i;

reg                 WriteTrans_EN_i;
reg  [4:0]                w_set_addr_memory;  // chon dia chi muon gui cho slave
reg  [32-1:0]     set_AWADDR_i;
reg  [1:0]                set_AWBURST_i;
reg  [7:0]                set_AWLEN_i;
reg  [2:0]                set_AWSIZE_i;

// slave0 control signals
reg [5:0] s0_address_memory;
reg [32-1:0] s0_DATA_MEMORY_i;
reg s0_WRITE_EN;

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


    // ket noi 1 master 2 slaves vao interconnect

    axi_master_if #(
        .ID_WIDTH(5),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    )
    master0
    (
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),

        // outputs
        .m_ARVALID_o(m_ARVALID_i),
        .m_AWVALID_o(m_AWVALID_i),
        .m_BREADY_o(m_BREADY_i),
        .m_RREADY_o(m_RREADY_i),
        .m_WLAST_o(m_WLAST_i),
        .m_WVALID_o(m_WVALID_i),
        .m_AWID_o(m_AWID_i),
        .m_AWADDR_o(m_AWADDR_i),
        .m_AWBURST_o(m_AWBURST_i),
        .m_AWLEN_o(m_AWLEN_i),
        .m_AWSIZE_o(m_AWSIZE_i),
        .m_WDATA_o(m_WDATA_i),
        .m_ARID_o(m_ARID_i),
        .m_ARADDR_o(m_ARADDR_i),
        .m_ARBURST_o(m_ARBURST_i),
        .m_ARLEN_o(m_ARLEN_i),
        .m_ARSIZE_o(m_ARSIZE_i),

        // inputs
        .m_ARREADY_i(m_ARREADY_o),
        .m_AWREADY_i(m_AWREADY_o),
        .m_BVALID_i(m_BVALID_o),
        .m_RLAST_i(m_RLAST_o),
        .m_RVALID_i(m_RVALID_o),
        .m_WREADY_i(m_WREADY_o),
        .m_BID_i(m_BID_o),
        .m_BRESP_i(m_BRESP_o),
        .m_RID_i(m_RID_o),
        .m_RDATA_i(m_RDATA_o),
        .m_RRESP_i(m_RRESP_o),

        // control
        .m_address_memory(m_address_memory),
        .m_READ_EN(m_READ_EN),
        .m_DATA_MEMORY_i(m_DATA_MEMORY_i),
        .m_DATA_MEMORY_o(m_DATA_MEMORY_o),
        .m_WRITE_EN(m_WRITE_EN),
        .ReadTrans_EN_i(ReadTrans_EN_i),
        .r_set_addr_memory(r_set_addr_memory),
        .set_ARADDR_i(set_ARADDR_i),
        .set_ARBURST_i(set_ARBURST_i),
        .set_ARLEN_i(set_ARLEN_i),
        .set_ARSIZE_i(set_ARSIZE_i),
        .WriteTrans_EN_i(WriteTrans_EN_i),
        .w_set_addr_memory(w_set_addr_memory),
        .set_AWADDR_i(set_AWADDR_i),
        .set_AWBURST_i(set_AWBURST_i),
        .set_AWLEN_i(set_AWLEN_i),
        .set_AWSIZE_i(set_AWSIZE_i)
    );

    axi_slave_if #(.ID_WIDTH(5), .ADDR_WIDTH(32), .DATA_WIDTH(32))
    slave0(
        // control 
        .s_address_memory(s0_address_memory),
        .s_DATA_MEMORY_i(s0_DATA_MEMORY_i),
        .s_WRITE_EN(s0_WRITE_EN),

        // outputs
        .s_AWREADY_o(s_AWREADY_i[0]),
        .s_WREADY_o(s_WREADY_i[0]),
        .s_BID_o(s_BID_i[4:0]),
        .s_BRESP_o(s_BRESP_i[1:0]),
        .s_BVALID_o(s_BVALID_i[0]),
        .s_ARREADY_o(s_ARREADY_i[0]),
        .s_RID_o(s_RID_i[0]),
        .s_RDATA_o(s_RDATA_i[31:0]),
        .s_RRESP_o(s_RRESP_i[1:0]),
        .s_RLAST_o(s_RLAST_i[0]),
        .s_RVALID_o(s_RVALID_i[0]),

        // inputs 
        .ARESETn_i(ARESETn_i),
        .ACLK_i(ACLK_i),
        .s_AWID_i(s_AWID_o[4:0]),
        .s_AWADDR_i(s_AWADDR_o[31:0]),
        .s_AWLEN_i(s_AWLEN_o[2:0]),
        .s_AWVALID_i(s_AWVALID_o[0]),
        .s_WDATA_i(s_WDATA_o[31:0]),
        .s_WLAST_i(s_WLAST_o[0]),
        .s_WVALID_i(s_WVALID_o[0]),
        .s_BREADY_i(s_BREADY_o[0]),
        .s_ARID_i(s_ARID_o[4:0]),
        .s_ARADDR_i(s_ARADDR_o[31:0]),
        .s_ARLEN_i(s_ARLEN_o[2:0]),
        .s_ARVALID_i(s_ARVALID_o[0]),
        .s_RREADY_i(s_RREADY_o[0])
    );

    axi_slave_if #(.ID_WIDTH(5), .ADDR_WIDTH(32), .DATA_WIDTH(32))
    slave1(
        // outputs
        .s_AWREADY_o(s_AWREADY_i[1]),
        .s_WREADY_o(s_WREADY_i[1]),
        .s_BID_o(s_BID_i[9:5]),
        .s_BRESP_o(s_BRESP_i[3:2]),
        .s_BVALID_o(s_BVALID_i[1]),
        .s_ARREADY_o(s_ARREADY_i[1]),
        .s_RID_o(s_RID_i[1]),
        .s_RDATA_o(s_RDATA_i[63:32]),
        .s_RRESP_o(s_RRESP_i[3:2]),
        .s_RLAST_o(s_RLAST_i[1]),
        .s_RVALID_o(s_RVALID_i[1]),

        // inputs 
        .ARESETn_i(ARESETn_i),
        .ACLK_i(ACLK_i),
        .s_AWID_i(s_AWID_o[9:5]),
        .s_AWADDR_i(s_AWADDR_o[63:32]),
        .s_AWLEN_i(s_AWLEN_o[5:3]),
        .s_AWVALID_i(s_AWVALID_o[1]),
        .s_WDATA_i(s_WDATA_o[63:32]),
        .s_WLAST_i(s_WLAST_o[1]),
        .s_WVALID_i(s_WVALID_o[1]),
        .s_BREADY_i(s_BREADY_o[1]),
        .s_ARID_i(s_ARID_o[9:5]),
        .s_ARADDR_i(s_ARADDR_o[63:32]),
        .s_ARLEN_i(s_ARLEN_o[5:3]),
        .s_ARVALID_i(s_ARVALID_o[1]),
        .s_RREADY_i(s_RREADY_o[1])
    );

    initial begin
        // ==========================================
        // KHỞI TẠO TÍN HIỆU ĐẦU VÀO = 0
        // ==========================================
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

        // nap 4 word vao master0
        for (i = 0 ;i < 4;i = i + 1) begin
            @(negedge ACLK_i);
            m_address_memory <= i;
            m_DATA_MEMORY_i <= i;
            m_WRITE_EN  <= 1'b1;
        end 
        @(posedge ACLK_i);
        m_WRITE_EN <= 1'b0;

        // doc 4 word tu ram noi cua master0
        for (i = 0 ;i < 4;i = i + 1) begin
            @(negedge ACLK_i);
            m_address_memory <= i;
            m_READ_EN  <= 1'b1;
        end 
        @(posedge ACLK_i);
        m_READ_EN <= 1'b0; 

        // truyen 4 word tu master0 den slave0
        @(negedge ACLK_i);
        w_set_addr_memory <= 0;
        set_AWADDR_i <= 0;
        set_AWBURST_i <= 1;
        set_AWLEN_i <= 3;
        set_AWSIZE_i <= 3'b010;
        WriteTrans_EN_i <= 1;
        @(negedge ACLK_i);
        WriteTrans_EN_i <= 0; 

        // doc 4 word tu slave0 den master0
        #1000;

        @(negedge ACLK_i);
        ReadTrans_EN_i <= 1'b1;
        r_set_addr_memory <= 0;
        set_ARADDR_i <= 0;
        set_ARBURST_i <= 1;
        set_ARLEN_i <= 3; 
        set_ARSIZE_i <= 3'b101;
        @(negedge ACLK_i);
        ReadTrans_EN_i <= 1'b0;

        // 4. doi mo phong chay mot thoi gian de xem waveform
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
