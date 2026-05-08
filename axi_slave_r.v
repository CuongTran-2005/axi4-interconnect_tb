module axi_slave_r #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7,

    localparam WORD_SIZE = DATA_WIDTH / 8
)(
    input                       ACLK_i,
    input                       ARESETn_i,

    //==================== ACCESS (To Control) ===================//
    input                       r_ram_access,
    output                      r_req,
    output                      r_busy,

    //================== RAM (To MUX) =========================//
    output [RAM_ADDR_WIDTH-1:0]                ram_address,
    output [DATA_WIDTH-1:0]     ram_data_in, // Không dùng cho read
    output                      ram_wren,    // Luôn bằng 0 cho read
    output [DATA_WIDTH/8-1:0]   ram_strobe,  // Luôn bằng 0 cho read
    input  [DATA_WIDTH-1:0]     ram_data_out,

    //================ READ ADDRESS CHANNEL ===================//
    input                       s_ARVALID_i,
    input  [ID_WIDTH-1:0]       s_ARID_i,
    input  [ADDR_WIDTH-1:0]     s_ARADDR_i,
    input  [7:0]                s_ARLEN_i,
    input  [1:0]                s_ARBURST_i,
    input  [2:0]                s_ARSIZE_i,    
    output                      s_ARREADY_o,

    //================ READ DATA CHANNEL ======================//
    output                      s_RVALID_o,
    output                      s_RLAST_o,
    output [ID_WIDTH-1:0]       s_RID_o,
    output [DATA_WIDTH-1:0]     s_RDATA_o,
    output [1:0]                s_RRESP_o,
    input                       s_RREADY_i
);

    //================ FSM STATES =================//
    localparam IDLE  = 2'd0;
    localparam WAIT  = 2'd1; // Đợi quyền truy cập RAM
    localparam RDATA = 2'd2;

    reg [1:0] state_r, next_state_r;

    // Registers lưu trữ thông tin Transaction
    reg [6:0]          addr_r;
    reg [7:0]          burst_cnt_r;
    reg [7:0]          len_r;
    reg [ID_WIDTH-1:0] id_r;

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) state_r <= IDLE;
        else            state_r <= next_state_r;
    end

    always @(*) begin
        next_state_r = state_r;
        case (state_r)
            IDLE:  if (s_ARVALID_i) next_state_r = WAIT;
            WAIT:  if (r_ram_access) next_state_r = RDATA;
            RDATA: if (s_RVALID_o && s_RREADY_i && s_RLAST_o) next_state_r = IDLE;
            default: next_state_r = IDLE;
        endcase
    end

    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            addr_r      <= 0;
            burst_cnt_r <= 0;
            len_r       <= 0;
            id_r        <= 0;
        end else begin
            if (state_r == IDLE && s_ARVALID_i) begin
                addr_r <= s_ARADDR_i[8:2]; // Lấy Word-address
                len_r  <= s_ARLEN_i;
                id_r   <= s_ARID_i;
                burst_cnt_r <= 0;
            end 
            else if (state_r == RDATA && s_RVALID_o && s_RREADY_i) begin
                addr_r <= addr_r + WORD_SIZE;
                burst_cnt_r <= burst_cnt_r + 1;
            end
        end
    end

    //================ OUTPUT LOGIC =================//
    // Control
    assign r_req  = (state_r == WAIT);
    assign r_busy = (state_r != IDLE);

    // RAM (Read only)
    assign ram_wren    = 1'b0;
    assign ram_data_in = {DATA_WIDTH{1'b0}};
    assign ram_strobe  = {(DATA_WIDTH/8){1'b0}};
    
    // RAM đọc dữ liệu ra bằng địa chỉ hiện tại
    assign ram_address = addr_r;

    // AXI
    assign s_ARREADY_o = (state_r == IDLE);
    
    assign s_RVALID_o  = (state_r == RDATA);
    assign s_RDATA_o   = ram_data_out;
    assign s_RID_o     = id_r;
    assign s_RRESP_o   = 2'b00; // OKAY response
    assign s_RLAST_o   = (burst_cnt_r == len_r);

endmodule