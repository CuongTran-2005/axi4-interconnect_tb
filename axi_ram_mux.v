module axi_ram_mux #(
    parameter DATA_WIDTH = 32,
    parameter RAM_ADDR_WIDTH = 7
)(
    //================ TÍN HIỆU ĐIỀU KHIỂN =================//
    input  [1:0]                    ram_mux_sel, // Tín hiệu chọn từ khối Control

    //================ TỪ KHỐI CONTROL (sel == 2'b01) ======//
    input  [RAM_ADDR_WIDTH-1:0]     ctrl_ram_address,
    input  [DATA_WIDTH-1:0]         ctrl_ram_data_in,
    input                           ctrl_ram_wren,
    input  [DATA_WIDTH/8-1:0]       ctrl_ram_strobe, // Bổ sung strobe cho Control

    //================ TỪ KHỐI AXI WRITE (sel == 2'b10) ====//
    input  [RAM_ADDR_WIDTH-1:0]     w_ram_address,
    input  [DATA_WIDTH-1:0]         w_ram_data_in,
    input                           w_ram_wren,
    input  [DATA_WIDTH/8-1:0]       w_strobe,        // Bổ sung strobe cho AXI Write

    //================ TỪ KHỐI AXI READ (sel == 2'b11) =====//
    input  [RAM_ADDR_WIDTH-1:0]     r_ram_address,
    input  [DATA_WIDTH-1:0]         r_ram_data_in,
    input                           r_ram_wren,
    input  [DATA_WIDTH/8-1:0]       r_strobe,        // Bổ sung strobe cho AXI Read

    //================ NGÕ RA KẾT NỐI VÀO RAM ==============//
    output reg [RAM_ADDR_WIDTH-1:0] ram_addr_o,
    output reg [DATA_WIDTH-1:0]     ram_data_i_o,
    output reg                      ram_wren_o,
    output reg [DATA_WIDTH/8-1:0]   ram_strobe_o     // Bổ sung strobe ra RAM
);

    //================ LOGIC CHỌN KÊNH (MULTIPLEXER) =======//
    always @(*) begin
        case(ram_mux_sel)
            // Kênh 1: Khối Control truy cập trực tiếp
            2'b01: begin
                ram_addr_o   = ctrl_ram_address;
                ram_data_i_o = ctrl_ram_data_in;
                ram_wren_o   = ctrl_ram_wren;
                ram_strobe_o = ctrl_ram_strobe;
            end
            
            // Kênh 2: Khối AXI Write truy cập
            2'b10: begin
                ram_addr_o   = w_ram_address;
                ram_data_i_o = w_ram_data_in;
                ram_wren_o   = w_ram_wren;
                ram_strobe_o = w_strobe;
            end
            
            // Kênh 3: Khối AXI Read truy cập
            2'b11: begin
                ram_addr_o   = r_ram_address;
                ram_data_i_o = r_ram_data_in;
                ram_wren_o   = r_ram_wren;
                ram_strobe_o = r_strobe;
            end
            
            // Trạng thái nghỉ (IDLE hoặc 2'b00)
            default: begin
                ram_addr_o   = ctrl_ram_address;
                ram_data_i_o = ctrl_ram_data_in;
                ram_wren_o   = ctrl_ram_wren;
                ram_strobe_o = ctrl_ram_strobe;
            end
        endcase
    end

endmodule