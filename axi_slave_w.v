module axi_slave_w#(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
	input                       ACLK_i,
    input                       ARESETn_i,
//==================== ACCESS ===================//
	input  w_ram_access,
//================== RAM  ==================//
 
	 output reg    [6:0] 				ram_address,
	 output reg [DATA_WIDTH:0] 		ram_data_in,
	 output  								ram_wren,
	 input    	[DATA_WIDTH-1:0]		ram_data_out,
	 // WRITE ADDRESS
    input                       s_AWVALID_i,
    input  [ID_WIDTH-1:0]       s_AWID_i,
    input  [ADDR_WIDTH-1:0]     s_AWADDR_i,
    input  [7:0]                s_AWLEN_i,
	 input  [1:0]                s_AWBURST_i,
	 input  [2:0]                s_AWSIZE_i,
    output                      s_AWREADY_o,

    // WRITE DATA
    input                       s_WVALID_i,
    input  [DATA_WIDTH-1:0]     s_WDATA_i,
    input                       s_WLAST_i,
    output                      s_WREADY_o,

    // WRITE RESP
    output                      s_BVALID_o,
    output [ID_WIDTH-1:0]       s_BID_o,
    output [1:0]                s_BRESP_o,
    input                       s_BREADY_i
);

//================ REG W=================//
	 //=======================================//
	 
	 reg [4:0] addr_w;   
	 reg [7:0] burst_cnt_w;
	 reg [ID_WIDTH-1:0] saved_id_w;
	 reg [2:0] state_w, next_state_w;
	 
	 reg  [ADDR_WIDTH-1:0]     reg_s_AWADDR_i;
	 reg  [1:0]                reg_s_AWBURST_i;
    reg  [7:0]                reg_s_AWLEN_i;
    reg  [2:0]                reg_s_AWSIZE_i;
	 
	 	//BURST W signed
	 wire [31:0] beat_size_w  = (1 << reg_s_AWSIZE_i);     // số byte mỗi beat
	 wire [31:0] burst_len_w  = reg_s_AWLEN_i + 1;         // số beat
	 wire [31:0] boundary_w   = burst_len_w * beat_size_w; // kích thước block
	 wire [31:0] mask_w       = boundary_w - 1;
	 wire [31:0] wrap_base_w  = reg_s_AWADDR_i & ~mask_w;    //  AWADDR ban đầu
	 wire [31:0] offset_w     = addr_w & mask_w;
	 wire [31:0] next_offset_w= (offset_w + beat_size_w) & mask_w;
	 //================PARAMETER STATE =================//
	 localparam IDLE  = 3'd0,
               WAIT  = 3'd1,
               AW    = 3'd3,
               WDATA = 3'd4,
               BRESP = 3'd5;

    integer i;

	 //================ STATE W =================//
	 //==========================================// 
	 
	 always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_w <= IDLE;
        else state_w <= next_state_w;
	 //================ NEXT STATE W =================//
	 //===============================================//
	 
	 always @(*) begin
        case(state_w)
        IDLE:
            if (s_AWVALID_i) next_state_w = AW;
            else next_state_w = IDLE;

        AW:
            if (s_AWVALID_i && s_AWREADY_o) next_state_w = WDATA;
            else next_state_w = AW;

        WDATA:
            if (s_WVALID_i && s_WREADY_o && s_WLAST_i)
                next_state_w = BRESP;
            else
                next_state_w = WDATA;

        BRESP:
            if (s_BVALID_o && s_BREADY_i)
                next_state_w = IDLE;
            else
                next_state_w = BRESP;

        default: next_state_w = IDLE;
        endcase
    end
//================ ADDRESS / BURST W =================//
	 //====================================================//
	 
	 always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            addr_w <= 0;
            burst_cnt_w <= 0;
        end
        else begin
            case(state_w)

            AW: begin
                if (s_AWVALID_i && s_AWREADY_o) begin
                    addr_w <= s_AWADDR_i;   
                    burst_cnt_w <= 0;
                    saved_id_w <= s_AWID_i;
						  
						  reg_s_AWADDR_i <= s_AWADDR_i;
						  reg_s_AWBURST_i <=s_AWBURST_i;
						  reg_s_AWLEN_i <= s_AWLEN_i;
						  reg_s_AWSIZE_i <= s_AWSIZE_i;
                end
            end

            WDATA: begin
                if (s_WVALID_i && s_WREADY_o) begin
						 case (reg_s_AWBURST_i)   //addr se thay doi tuy vao arbusrt
									00 :	addr_w <= addr_w;
									01 :  addr_w <= addr_w + beat_size_w;
									10 : 	addr_w <= wrap_base_w | next_offset_w;   //wrap_base da clear phan dau cua block, next_offset da clear vi tri ben trong block nen or lai la add
									11 : ;
						 default: addr_w <= addr_w;           
						 endcase
						 
						 ram_address <= addr_w;
						 ram_data_in <= s_WDATA_i;
                    //mem[mem_ptr_r] <= m_RDATA_i;
                    addr_w <= addr_w + beat_size_w;
						 //mem[addr_w] <= s_WDATA_i;
						 burst_cnt_w <= burst_cnt_w + 1;
				    end
            end

            default: ;
            endcase
        end
    end
	 //=========================================//
    //================ OUTPUT =================//
	 //=========================================//
	 //RAM
	 assign ram_wren = (state_w == WDATA && w_ram_access) ? 0:1; //nen bat theo xung clock
	 
	 //CONTROL
	 assign w_busy = (state_w == WDATA);
	
	// WRITE ADDRESS
    assign s_AWREADY_o = (state_w == AW);

    // WRITE DATA
    assign s_WREADY_o = (state_w == WDATA);

    // WRITE RESP
    assign s_BVALID_o = (state_w == BRESP);
    assign s_BRESP_o  = 2'b00;
    assign s_BID_o    = saved_id_w;

endmodule