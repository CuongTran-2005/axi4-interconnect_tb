module axi_master_r #(
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,    //toi da tuy vao so luong device va memory cua tung device
    parameter DATA_WIDTH = 32,     //toi da 1024
    parameter RAM_ADDR_WIDTH = 7
)(

    input                       ACLK_i,
    input                       ARESETn_i,
//==================== ACCESS ===================//
    input                       r_ram_access,
    output                      r_req,
	output 						r_busy,

//==================== CONTROL COMMAND ===================//

	input                       ReadTrans_EN_i,
    input  [RAM_ADDR_WIDTH-1:0] r_set_addr_memory,   //chon dia chi lua gia tri tu slave tra ve
    input  [ADDR_WIDTH-1:0]     set_ARADDR_i,
    input  [1:0]                set_ARBURST_i,
    input  [7:0]                set_ARLEN_i,
    input  [2:0]                set_ARSIZE_i,

//================== RAM  ==================//
 
    output wire  [RAM_ADDR_WIDTH-1:0] 	ram_address,
    output wire  [DATA_WIDTH-1:0] 		ram_data_in,
    output  							ram_wren,
    input    	[DATA_WIDTH-1:0]		ram_data_out,
    output      [DATA_WIDTH/8-1:0]      ram_strobe, 
 
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
 //================ REG R =================//
    reg [RAM_ADDR_WIDTH-1:0] mem_ptr_r;
    reg [7:0] burst_cnt_r;
    reg [2:0] state_r, next_state_r;
    
    wire [31:0] beat_size_r;
    
    reg  [ADDR_WIDTH-1:0]     reg_set_ARADDR_i;
    reg  [1:0]                reg_set_ARBURST_i;
    reg  [7:0]                reg_set_ARLEN_i;
    reg  [2:0]                reg_set_ARSIZE_i;

    assign beat_size_r = (1 << reg_set_ARSIZE_i) ;
integer i;
localparam 	    IDLE  = 3'd0,
                AR    = 3'd1,
                RDATA = 3'd2,
                WAIT  = 3'd3;
//================ STATE_R =================//
always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_r <= IDLE;
        else state_r <= next_state_r;
		  
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
            if (m_ARREADY_i && r_ram_access) next_state_r = RDATA;
            else 
			if (m_ARREADY_i && !r_ram_access) next_state_r = WAIT;
			else next_state_r = AR;
		
		WAIT:	
            if (r_ram_access) next_state_r = RDATA;
            else next_state_r = WAIT;
				
        RDATA:
            if (m_RVALID_i && m_RREADY_o && m_RLAST_i)
                next_state_r = IDLE;
            else
            if (!r_ram_access)
                next_state_r = WAIT;
            else 
            if (m_RVALID_i && m_RREADY_o && !m_RLAST_i)
                next_state_r = RDATA;
            else next_state_r = RDATA;

        default: next_state_r = IDLE;
        endcase
    end
	 //================ POINTER + BURST READ =================//
always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            mem_ptr_r <= 0;
            burst_cnt_r <= 0;
        end else begin
            case(state_r)
            IDLE: begin
                if (next_state_r == AR) begin
                    mem_ptr_r <= r_set_addr_memory;         //chon dia chi muon nhan du lieu tu slave
                    burst_cnt_r <= 0;							//dem so burst
                    reg_set_ARADDR_i <= set_ARADDR_i;
                    reg_set_ARBURST_i <= set_ARBURST_i;
                    reg_set_ARLEN_i <= set_ARLEN_i;
                    reg_set_ARSIZE_i <=set_ARSIZE_i;
                end
            end
            AR: begin
            end
				
            RDATA:
                if (m_RVALID_i && r_ram_access) begin
                    
                    //mem[mem_ptr_r + i] <= m_RDATA_i[i*8 +: 8];
                    //ram_address <= mem_ptr_r;
                    //ram_data_in <= m_RDATA_i;
                    //mem[mem_ptr_r] <= m_RDATA_i;
                    mem_ptr_r <= mem_ptr_r + beat_size_r;
                    burst_cnt_r <= burst_cnt_r + 1;
                end

            default: ;
            endcase
        end
    end
	 	 //================ OUTPUT =================//
//CONTROL
    assign r_busy = (state_r == RDATA)?1'b1:1'b0;
    assign r_req = (state_r == WAIT)?1'b1:1'b0;
//RAM
	assign ram_wren = (state_r == RDATA && r_ram_access) ? 0:1;
    assign ram_address = (state_r == RDATA)?mem_ptr_r:0;
    assign ram_data_in = (state_r == RDATA)?m_RDATA_i:0;
    assign ram_strobe = {(DATA_WIDTH/8){1'b1}};
// READ ADDRESS
    assign m_ARVALID_o = (state_r == AR)?1'b1:1'b0;
    assign m_ARADDR_o  = reg_set_ARADDR_i;
    assign m_ARBURST_o = reg_set_ARBURST_i;
    assign m_ARLEN_o   = reg_set_ARLEN_i;
    assign m_ARSIZE_o  = reg_set_ARSIZE_i;
    assign m_ARID_o    = 0;

    // READ DATA
    assign m_RREADY_o = (state_r == RDATA) && r_ram_access;
endmodule