module axi_master_if #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,    //toi da tuy vao so luong device va memory cua tung device
    parameter DATA_WIDTH = 32     //toi da 1024
)(
    input                       ACLK_i,
    input                       ARESETn_i,

    //================ Control ======================//
	 //Tin hieu doc va ghi vao RAM noi
    input  [9:0]                m_address_memory,
    input                       m_READ_EN,
    input  [7:0]     			  m_DATA_MEMORY_i, //sua
    input                       m_WRITE_EN,
    output [7:0]      			  m_DATA_MEMORY_o, //sua
    //Transaction READ
    input                       ReadTrans_EN_i,
    input  [4:0]                r_set_addr_memory,   //chon dia chi lua gia tri tu slave tra ve
    input  [ADDR_WIDTH-1:0]     set_ARADDR_i,
    input  [1:0]                set_ARBURST_i,
    input  [7:0]                set_ARLEN_i,
    input  [2:0]                set_ARSIZE_i,
	 //Transaction WRITE	
    input                       WriteTrans_EN_i,	
	 input  [4:0]                w_set_addr_memory,  // chon dia chi muon gui cho slave
	 input  [ADDR_WIDTH-1:0]     set_AWADDR_i,
    input  [1:0]                set_AWBURST_i,
    input  [7:0]                set_AWLEN_i,
    input  [2:0]                set_AWSIZE_i,
	   
    //================ WRITE ADDRESS =================//
    output 		                 m_AWVALID_o,
    output [ID_WIDTH-1:0]       m_AWID_o,
    output [ADDR_WIDTH-1:0]     m_AWADDR_o,
    output [1:0]                m_AWBURST_o,
    output [7:0]                m_AWLEN_o,
    output [2:0]                m_AWSIZE_o,
    input                       m_AWREADY_i,

    //================ WRITE DATA ====================//
    output                      m_WVALID_o,
    output [DATA_WIDTH-1:0]     m_WDATA_o,
    output                      m_WLAST_o,
    input                       m_WREADY_i,

    //================ WRITE RESP ====================//
    input                       m_BVALID_i,
    input  [ID_WIDTH-1:0]       m_BID_i,
    input  [1:0]                m_BRESP_i,
    output                      m_BREADY_o,

    //================ READ ADDRESS ==================//
    output                      m_ARVALID_o,
    output [ID_WIDTH-1:0]       m_ARID_o,
    output [ADDR_WIDTH-1:0]     m_ARADDR_o,
    output [1:0]                m_ARBURST_o,
    output [7:0]                m_ARLEN_o,
    output [2:0]                m_ARSIZE_o,
    input                       m_ARREADY_i,

    //================ READ DATA =====================//
    input                       m_RVALID_i,
    input                       m_RLAST_i,
    input  [ID_WIDTH-1:0]       m_RID_i,
    input  [DATA_WIDTH-1:0]     m_RDATA_i,
    input  [1:0]                m_RRESP_i,
    output                      m_RREADY_o
);

    //================ MEMORY =================//
	 //doc du lieu memory tu master de kiem tra xem co du lieu hay khong
    reg [7:0] mem [0:1023];

    assign m_DATA_MEMORY_o = (m_READ_EN) ? mem[m_address_memory] : 0;
    always @(posedge ACLK_i)
        if (m_WRITE_EN && state_r == IDLE && state_w == IDLE)
            mem[m_address_memory] <= m_DATA_MEMORY_i;

    //================ REG R =================//
    reg [4:0] mem_ptr_r;
    reg [7:0] burst_cnt_r;
    reg [2:0] state_r, next_state_r;
	 
	 wire [31:0] beat_size_r  = (1 << set_ARSIZE_i); 
	 
    reg  [ADDR_WIDTH-1:0]     reg_set_ARADDR_i;
    reg  [1:0]                reg_set_ARBURST_i;
    reg  [7:0]                reg_set_ARLEN_i;
    reg  [2:0]                reg_set_ARSIZE_i;
	 
	 //================ REG W =================//
	  
	  reg [4:0] mem_ptr_w;
	  reg [7:0] burst_cnt_w;
	  reg [2:0] state_w, next_state_w;
	  
	  wire [31:0] beat_size_w  = (1 << set_AWSIZE_i); 
	  
	  reg  [ADDR_WIDTH-1:0]     reg_set_AWADDR_i;
	  reg  [1:0]                reg_set_AWBURST_i;
     reg  [7:0]                reg_set_AWLEN_i;
     reg  [2:0]                reg_set_AWSIZE_i;
	 
	  
	 //================ PARAMETER STATE =================//
	 integer i;
    localparam IDLE  = 3'd0,
               AR    = 3'd1,
               RDATA = 3'd2,
               AW    = 3'd3,
               WDATA = 3'd4,
               BRESP = 3'd5;

    //================ STATE_R =================//
	 
    always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_r <= IDLE;
        else state_r <= next_state_r;
		  
	 //================ STATE_W =================//
	 
	 always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_w <= IDLE;
        else state_w <= next_state_w;

    //================ NEXT STATE_R =================//
	  always @(*) begin
        case(state_r)
        IDLE:
            if (ReadTrans_EN_i) 
				begin
					next_state_r = AR;
				end
            else next_state_r = IDLE;

        AR:
            if (m_ARVALID_o && m_ARREADY_i) next_state_r = RDATA;
            else next_state_r = AR;

        RDATA:
            if (m_RVALID_i && m_RREADY_o && m_RLAST_i)
                next_state_r = IDLE;
            else
                next_state_r = RDATA;


        default: next_state_r = IDLE;
        endcase
    end
	 
	 //================ NEXT STATE_W =================//
    always @(*) begin
        case(state_w)
        IDLE:
            if (WriteTrans_EN_i) next_state_w = AW;
            else next_state_w = IDLE;

        AW:
            if (m_AWVALID_o && m_AWREADY_i) next_state_w = WDATA;
            else next_state_w = AW;

        WDATA:
            if (m_WVALID_o && m_WREADY_i && m_WLAST_o)
                next_state_w = BRESP;
            else
                next_state_w = WDATA;

        BRESP:
            if (m_BVALID_i && m_BREADY_o)
                next_state_w = IDLE;
            else
                next_state_w = BRESP;

        default: next_state_w = IDLE;
        endcase
    end

    //================ POINTER + BURST READ =================//
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            mem_ptr_r <= 0;
            burst_cnt_r <= 0;
        end else begin
            case(state_r)
            AR:
                if (m_ARVALID_o && m_ARREADY_i) begin
                    mem_ptr_r <= r_set_addr_memory;         //chon dia chi muon nhan du lieu tu slave
                    burst_cnt_r <= 0;							//dem so burst
						  reg_set_ARADDR_i <= set_ARADDR_i;
						  reg_set_ARBURST_i <= set_ARBURST_i;
						  reg_set_ARLEN_i <= set_ARLEN_i;
						  reg_set_ARSIZE_i <=set_ARSIZE_i;
                end

            RDATA:
                if (m_RVALID_i && m_RREADY_o && !m_WRITE_EN) begin
						  for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
							  if (i < beat_size_r)
									mem[mem_ptr_r + i] <= m_RDATA_i[i*8 +: 8];
						  end
                    //mem[mem_ptr_r] <= m_RDATA_i;
                    mem_ptr_r <= mem_ptr_r + beat_size_r;
                    burst_cnt_r <= burst_cnt_r + 1;
                end

            default: ;
            endcase
        end
    end
	 
	 //================ POINTER + BURST WRITE =================//
	 always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            mem_ptr_w <= 0;
            burst_cnt_w <= 0;
        end else begin
            case(state_w)
            AW:
                if (m_AWVALID_o && m_AWREADY_i) begin
                    mem_ptr_w <= w_set_addr_memory;
                    burst_cnt_w <= 0;
						  reg_set_AWADDR_i <= set_AWADDR_i;
						  reg_set_AWBURST_i <= set_AWBURST_i;
						  reg_set_AWLEN_i <= set_AWLEN_i;
						  reg_set_AWSIZE_i <=set_AWSIZE_i;
                end

            WDATA:
                if (m_WVALID_o && m_WREADY_i) begin
                    mem_ptr_w <= mem_ptr_w + beat_size_w;
                    burst_cnt_w <= burst_cnt_w + 1;
                end

            default: ;
            endcase
        end
    end
	 

    //================ OUTPUT =================//

    // READ ADDRESS
    assign m_ARVALID_o = (state_r == AR);
    assign m_ARADDR_o  = reg_set_ARADDR_i;
    assign m_ARBURST_o = reg_set_ARBURST_i;
    assign m_ARLEN_o   = reg_set_ARLEN_i;
    assign m_ARSIZE_o  = reg_set_ARSIZE_i;
    assign m_ARID_o    = 0;

    // READ DATA
    assign m_RREADY_o = (state_r == RDATA);

    // WRITE ADDRESS
    assign m_AWVALID_o = (state_w == AW) ; // set lai awvalid
    assign m_AWADDR_o  = reg_set_AWADDR_i;
    assign m_AWBURST_o = reg_set_AWBURST_i;
    assign m_AWLEN_o   = reg_set_AWLEN_i;
    assign m_AWSIZE_o  = reg_set_AWSIZE_i;
    assign m_AWID_o    = 0;

    // WRITE DATA
    assign m_WVALID_o = (state_w == WDATA);
	 genvar j;
	 generate
		  for (j = 0; j < DATA_WIDTH/8; j = j + 1) begin : GEN_RDATA
			  assign m_WDATA_o [j*8 +: 8] = mem[mem_ptr_w + j];
		  end 
	 endgenerate
	 
    //assign m_WDATA_o  = mem[mem_ptr_w];    //mem o dau
    assign m_WLAST_o  = (burst_cnt_w == reg_set_AWLEN_i);

    // WRITE RESP
    assign m_BREADY_o = (state_w == BRESP);

endmodule