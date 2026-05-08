module axi_master_control #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,    
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7     
)(
    input                           ACLK_i,
    input                           ARESETn_i,

    //================ CONTROL RAM NOI (Giao diện người dùng) ================//
    input  [RAM_ADDR_WIDTH-1:0]     m_address_memory,
    input                           m_READ_EN,
    input  [DATA_WIDTH-1:0]         m_DATA_MEMORY_i, 
    input                           m_WRITE_EN,
    output [DATA_WIDTH-1:0]         m_DATA_MEMORY_o,

    //================ TÍN HIỆU RAM CỦA RIÊNG KHỐI CONTROL ===================//
    // Các tín hiệu này sẽ được nối vào 1 cổng của MUX bên ngoài
    output [RAM_ADDR_WIDTH-1:0]     ctrl_ram_address,
    output [DATA_WIDTH-1:0]         ctrl_ram_data_in,
    output                          ctrl_ram_wren,
    input  [DATA_WIDTH-1:0]         ram_data_out, // Từ RAM dội về

    //================ TÍN HIỆU ĐIỀU KHIỂN MUX NGOÀI =========================//
    output reg [1:0]                ram_mux_sel,

    //================ GIAO TIẾP AXI READ ====================================//
    output                          r_ram_access,
    input                           r_req,
    input                           r_busy,

    //================ GIAO TIẾP AXI WRITE ===================================//
    output                          w_ram_access,
    input                           w_req,
    input                           w_busy
);

    //================ PARAMETER STATES =================//
    localparam ST_IDLE   = 2'd0;
    localparam ST_DIRECT = 2'd1;
    localparam ST_AXIW   = 2'd2;
    localparam ST_AXIR   = 2'd3;

    reg [1:0] state_c, next_state_c;

    // Yêu cầu truy cập trực tiếp từ Control
    wire direct_req = m_READ_EN | m_WRITE_EN;

    //================ FSM STATE REGISTER =================//
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) state_c <= ST_IDLE;
        else state_c <= next_state_c;
    end

    //================ FSM NEXT STATE LOGIC ===============//
    always @(*) begin
        next_state_c = state_c; 
        
        case (state_c)
            ST_IDLE: begin
                // Phân xử ưu tiên: 1. Direct -> 2. AXI Write -> 3. AXI Read
                if (direct_req)      next_state_c = ST_DIRECT;
                else if (w_req)      next_state_c = ST_AXIW;
                else if (r_req)      next_state_c = ST_AXIR;
            end
            
            ST_DIRECT: begin
                if (!direct_req)     next_state_c = ST_IDLE;
            end
            
            ST_AXIW: begin
                if (!w_req && !w_busy) next_state_c = ST_IDLE;
            end
            
            ST_AXIR: begin
                if (!r_req && !r_busy) next_state_c = ST_IDLE;
            end
            
            default: next_state_c = ST_IDLE;
        endcase
    end

    //================ CONTROL OUTPUTS =================//
    
    // 1. Cấp quyền truy cập cho các Master
    assign w_ram_access = (state_c == ST_AXIW);
    assign r_ram_access = (state_c == ST_AXIR);

    // 2. Tín hiệu RAM của riêng khối Control (xuất ra để đưa vào MUX)
    assign ctrl_ram_address = m_address_memory;
    assign ctrl_ram_data_in = m_DATA_MEMORY_i;
    assign ctrl_ram_wren    = m_WRITE_EN;
    assign m_DATA_MEMORY_o  = ram_data_out;

    // 3. Tín hiệu điều khiển MUX ngoài (Dựa vào trạng thái hiện tại)
    always @(*) begin
        case (state_c)
            ST_DIRECT: ram_mux_sel = 2'b01; // Chọn kênh Control
            ST_AXIW:   ram_mux_sel = 2'b10; // Chọn kênh AXI Write
            ST_AXIR:   ram_mux_sel = 2'b11; // Chọn kênh AXI Read
            default:   ram_mux_sel = 2'b00; // Trạng thái nghỉ (Idle)
        endcase
    end

endmodule