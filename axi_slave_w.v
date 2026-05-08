module axi_slave_w #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7,

    localparam  WORD_SIZE = DATA_WIDTH / 8
)(
    input                       ACLK_i,
    input                       ARESETn_i,

    //==================== ACCESS (To Control) ===================//
    input                       w_ram_access,
    output                      w_req,
    output                      w_busy,

    //================== RAM (To MUX) =========================//
    output [RAM_ADDR_WIDTH-1:0] ram_address,
    output [DATA_WIDTH-1:0]     ram_data_in,
    output                      ram_wren,
    output [DATA_WIDTH/8-1:0]   ram_strobe,
    input  [DATA_WIDTH-1:0]     ram_data_out, // Không dùng trong write

    //================ WRITE ADDRESS CHANNEL ==================//
    input                       s_AWVALID_i,
    input  [ID_WIDTH-1:0]       s_AWID_i,
    input  [ADDR_WIDTH-1:0]     s_AWADDR_i,
    input  [7:0]                s_AWLEN_i,
    input  [1:0]                s_AWBURST_i,
    input  [2:0]                s_AWSIZE_i,
    output                      s_AWREADY_o,

    //================ WRITE DATA CHANNEL =====================//
    input                       s_WVALID_i,
    input  [DATA_WIDTH-1:0]     s_WDATA_i,
    input  [DATA_WIDTH/8-1:0]   s_WSTRB_i,   // ĐÃ BỔ SUNG
    input                       s_WLAST_i,
    output                      s_WREADY_o,

    //================ WRITE RESPONSE CHANNEL =================//
    output                      s_BVALID_o,
    output [ID_WIDTH-1:0]       s_BID_o,
    output [1:0]                s_BRESP_o,
    input                       s_BREADY_i
);

    //================ FSM STATES =================//
    localparam IDLE  = 3'd0;
    localparam WAIT  = 3'd1; // Đợi quyền truy cập RAM
    localparam WDATA = 3'd2;
    localparam BRESP = 3'd3;

    reg [2:0] state_w, next_state_w;

    // Registers lưu trữ thông tin Transaction
    reg [6:0]          addr_w;
    reg [7:0]          burst_cnt_w;
    reg [7:0]          len_w;
    reg [ID_WIDTH-1:0] id_w;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) state_w <= IDLE;
        else            state_w <= next_state_w;
    end

    always @(*) begin
        next_state_w = state_w;
        case (state_w)
            IDLE:  if (s_AWVALID_i) next_state_w = WAIT;
            WAIT:  if (w_ram_access) next_state_w = WDATA;
            WDATA: if (s_WVALID_i && s_WREADY_o && s_WLAST_i) next_state_w = BRESP;
            BRESP: if (s_BREADY_i) next_state_w = IDLE;
            default: next_state_w = IDLE;
        endcase
    end

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            addr_w      <= 0;
            burst_cnt_w <= 0;
            len_w       <= 0;
            id_w        <= 0;
        end else begin
            if (state_w == IDLE && s_AWVALID_i) begin
                // Lưu địa chỉ (dịch 2 bit vì đánh địa chỉ theo word 32-bit)
                addr_w <= s_AWADDR_i[8:2]; 
                len_w  <= s_AWLEN_i;
                id_w   <= s_AWID_i;
                burst_cnt_w <= 0;
            end 
            else if (state_w == WDATA && s_WVALID_i && s_WREADY_o) begin
                addr_w <= addr_w + WORD_SIZE; // Mặc định là INCR burst
                burst_cnt_w <= burst_cnt_w + 1;
            end
        end
    end

    //================ OUTPUT LOGIC =================//
    // Control
    assign w_req  = (state_w == WAIT);
    assign w_busy = (state_w != IDLE);

    // RAM
    assign ram_wren    = (state_w == WDATA && s_WVALID_i);
    assign ram_address = addr_w;
    assign ram_data_in = s_WDATA_i;
    assign ram_strobe  = (state_w == WDATA)?{(DATA_WIDTH/8){1'b1}}:0;

    // AXI
    assign s_AWREADY_o = (state_w == IDLE);
    assign s_WREADY_o  = (state_w == WDATA);
    
    assign s_BVALID_o  = (state_w == BRESP);
    assign s_BID_o     = id_w;
    assign s_BRESP_o   = 2'b00; // OKAY response

endmodule