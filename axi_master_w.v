module axi_master_w #( 
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7
)(
    input                       ACLK_i,
    input                       ARESETn_i,
	 
    //==================== ACCESS ===================//
    input                       w_ram_access,
    output                      w_req,
    output 	                    w_busy,

    //==================== CONTROL COMMAND ===================//
    input                       WriteTrans_EN_i,	
    input  [RAM_ADDR_WIDTH-1:0] w_set_addr_memory,  
    input  [ADDR_WIDTH-1:0]     set_AWADDR_i,
    input  [1:0]                set_AWBURST_i,
    input  [7:0]                set_AWLEN_i,
    input  [2:0]                set_AWSIZE_i,

    //================== RAM  ==================//
    output [RAM_ADDR_WIDTH-1:0] ram_address,
    output [DATA_WIDTH-1:0] 	ram_data_in,
    output  					ram_wren,
    input  [DATA_WIDTH-1:0]		ram_data_out,
    output [DATA_WIDTH/8-1:0]   ram_strobe,   
    
    //================ WRITE ADDRESS =================//
    output 		                m_AWVALID_o,
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
    output                      m_BREADY_o
);

    //================ REG W =================//
    reg [RAM_ADDR_WIDTH-1:0] mem_ptr_w;
    reg [7:0] burst_cnt_w;
    reg [2:0] state_w, next_state_w;
    
    reg [ADDR_WIDTH-1:0] reg_set_AWADDR_i;
    reg [1:0]            reg_set_AWBURST_i;
    reg [7:0]            reg_set_AWLEN_i;
    reg [2:0]            reg_set_AWSIZE_i;
    
    //================ PARAMETER STATE =================//
    localparam IDLE     = 3'd0,
               WAIT     = 3'd1,
               AW       = 3'd2,
               WDATA    = 3'd3,
               BRESP    = 3'd4;


    localparam  AxBURST_FIXED   = 2'b00,
                AxBURST_INCR    = 2'b01,
                AxBURST_WARP    = 2'b10;

    localparam WORD_SIZE = DATA_WIDTH / 8;

    //================ STATE_W =================//
    always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_w <= IDLE;
        else state_w <= next_state_w;
		  
	//================ NEXT STATE_W =================//
    always @(*) begin
        case(state_w)
            IDLE:
                if (WriteTrans_EN_i) next_state_w = AW;
                else next_state_w = IDLE;

            AW:
                if (m_AWVALID_o && m_AWREADY_i && w_ram_access) next_state_w = WDATA;
                else if (m_AWVALID_o && m_AWREADY_i && !w_ram_access) next_state_w = WAIT;
                else next_state_w = AW;
                
            WAIT:	
                if (w_ram_access) next_state_w = WDATA;
                else next_state_w = WAIT;

            WDATA:
                if (m_WVALID_o && m_WREADY_i && m_WLAST_o) next_state_w = BRESP;
                else if (!w_ram_access) next_state_w = WAIT;
                else next_state_w = WDATA; // Giữ nguyên ở WDATA nếu chưa truyền xong hoặc đang chờ WREADY

            BRESP:
                if (m_BVALID_i && m_BREADY_o) next_state_w = IDLE;
                else next_state_w = BRESP;
                
            default: next_state_w = IDLE;
        endcase
    end
    
    //================ POINTER + BURST WRITE =================//
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            mem_ptr_w <= 0;
            burst_cnt_w <= 0;
            reg_set_AWADDR_i <= 0;
            reg_set_AWBURST_i <= 0;
            reg_set_AWLEN_i <= 0;
            reg_set_AWSIZE_i <= 0;
        end else begin
            case(state_w)
                IDLE:
                    if (next_state_w == AW) begin
                        // Latch toàn bộ các giá trị điều khiển trước khi vào AW
                        mem_ptr_w <= w_set_addr_memory;
                        burst_cnt_w <= 0;
                        reg_set_AWADDR_i <= set_AWADDR_i;
                        reg_set_AWBURST_i <= set_AWBURST_i;
                        reg_set_AWLEN_i <= set_AWLEN_i;
                        reg_set_AWSIZE_i <= set_AWSIZE_i;
                    end
                    
                WDATA:
                    if (m_WVALID_o && m_WREADY_i && w_ram_access) begin
                        // Cập nhật con trỏ mỗi khi có 1 beat thành công
                        if (reg_set_AWBURST_i == AxBURST_INCR) begin
                            mem_ptr_w <= mem_ptr_w + WORD_SIZE;
                        end
                        burst_cnt_w <= burst_cnt_w + 1;
                    end
                    
                default: ;
            endcase
        end
    end

    //================ OUTPUT =================//
    
    // CONTROL
    assign w_busy = (state_w != IDLE); // Busy khi FSM rời khỏi IDLE
    assign w_req  = (state_w == WAIT); // Yêu cầu RAM khi đang ở WAIT

    // RAM (Master Read từ RAM để bắn dữ liệu qua AXI)
    assign ram_wren    = 1'b0; // Không Write vào RAM trong module này
    assign ram_address = mem_ptr_w; 
    assign ram_data_in = {DATA_WIDTH{1'b0}}; 
    assign ram_strobe      = {(DATA_WIDTH/8){1'b1}}; // Tạm đặt full byte enable

    // WRITE ADDRESS (AW)
    assign m_AWVALID_o = (state_w == AW);
    assign m_AWADDR_o  = reg_set_AWADDR_i;
    assign m_AWBURST_o = reg_set_AWBURST_i;
    assign m_AWLEN_o   = reg_set_AWLEN_i;
    assign m_AWSIZE_o  = reg_set_AWSIZE_i;
    assign m_AWID_o    = 0;

    // WRITE DATA (W)
    assign m_WVALID_o = (state_w == WDATA) && w_ram_access; 
    assign m_WDATA_o  = ram_data_out; 
    assign m_WLAST_o  = (burst_cnt_w == reg_set_AWLEN_i);

    // WRITE RESP (B)
    assign m_BREADY_o = (state_w == BRESP);
endmodule