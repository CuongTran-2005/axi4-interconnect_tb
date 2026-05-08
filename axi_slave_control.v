module axi_slave_control #(
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7
)(
    input                           ACLK_i,
    input                           ARESETn_i,

    // Giao diện người dùng (User Interface)
    input  [RAM_ADDR_WIDTH-1:0]                    s_address_memory,
    input                           s_READ_EN,
    input  [DATA_WIDTH-1:0]                    s_DATA_MEMORY_i, 
    input                           s_WRITE_EN,
    output [DATA_WIDTH-1:0]                    s_DATA_MEMORY_o,

    // Tín hiệu RAM của riêng khối Control (nối vào MUX)
    output [RAM_ADDR_WIDTH-1:0]                    ctrl_ram_address,
    output [DATA_WIDTH-1:0]         ctrl_ram_data_in,
    output                          ctrl_ram_wren,
    input  [DATA_WIDTH-1:0]         ram_data_out, // Dữ liệu từ RAM trả về

    // Điều khiển MUX
    output reg [1:0]                ram_mux_sel,

    // Giao tiếp với AXI Slave Read
    output                          r_ram_access,
    input                           r_req,
    input                           r_busy,

    // Giao tiếp với AXI Slave Write
    output                          w_ram_access,
    input                           w_req,
    input                           w_busy
);

    // Định nghĩa các trạng thái phân xử
    localparam ST_IDLE   = 2'b00;
    localparam ST_DIRECT = 2'b01; // Ưu tiên 1: User truy cập trực tiếp
    localparam ST_AXIW   = 2'b10; // Ưu tiên 2: AXI Write
    localparam ST_AXIR   = 2'b11; // Ưu tiên 3: AXI Read

    reg [1:0] state_c, next_state_c;

    wire direct_req = s_READ_EN | s_WRITE_EN;

    // FSM chuyển trạng thái
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) state_c <= ST_IDLE;
        else            state_c <= next_state_c;
    end

    always @(*) begin
        next_state_c = state_c;
        case (state_c)
            ST_IDLE: begin
                if (direct_req)      next_state_c = ST_DIRECT;
                else if (w_req)      next_state_c = ST_AXIW;
                else if (r_req)      next_state_c = ST_AXIR;
            end
            
            ST_DIRECT: if (!direct_req) next_state_c = ST_IDLE;
            
            ST_AXIW:   if (!w_req && !w_busy) next_state_c = ST_IDLE;
            
            ST_AXIR:   if (!r_req && !r_busy) next_state_c = ST_IDLE;
            
            default: next_state_c = ST_IDLE;
        endcase
    end

    // Output logic cho MUX và Access
    always @(*) begin
        ram_mux_sel = 2'b00;
        case (state_c)
            ST_DIRECT: ram_mux_sel = 2'b01;
            ST_AXIW:   ram_mux_sel = 2'b10;
            ST_AXIR:   ram_mux_sel = 2'b11;
        endcase
    end

    assign w_ram_access = (state_c == ST_AXIW);
    assign r_ram_access = (state_c == ST_AXIR);

    // Map tín hiệu User sang format RAM 32-bit
    assign ctrl_ram_address = s_address_memory;
    assign ctrl_ram_data_in = s_DATA_MEMORY_i;
    assign ctrl_ram_wren    = s_WRITE_EN;
    assign s_DATA_MEMORY_o  = ram_data_out;

endmodule