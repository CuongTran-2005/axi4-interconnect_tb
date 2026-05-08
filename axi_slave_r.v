module axi_slave_r #(
parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32,    //toi da tuy vao so luong device va memory cua tung device
    parameter DATA_WIDTH = 32     //toi da 1024
)(
	input                       ACLK_i,
    input                       ARESETn_i,

//================== REQUEST RAM  ==================//
  output 								r_request,        //request to control
 output 							  		r_busy,
 input  									r_ram_access,
 
 output     [6:0] 					ram_address,
 output reg [DATA_WIDTH:0] 		ram_data_in,
 output  								ram_wren,
 input    	[DATA_WIDTH-1:0]		ram_data_out,
 output 		[DATA_WIDTH/8-1:0]  	strobe,   //chua giai quyet strobe
  //================ READ ADDRESS ==================//
 // READ ADDRESS
    input                       s_ARVALID_i,
    input  [ID_WIDTH-1:0]       s_ARID_i,
    input  [ADDR_WIDTH-1:0]     s_ARADDR_i,
    input  [7:0]                s_ARLEN_i,
	 input  [1:0]					  s_ARBURST_i,
	 input  [2:0]                s_ARSIZE_i,    
    output                      s_ARREADY_o,
 //================ READ DATA =====================//
    // READ DATA
    output                      s_RVALID_o,
    output                      s_RLAST_o,
    output [ID_WIDTH-1:0]       s_RID_o,
    output [DATA_WIDTH-1:0]     s_RDATA_o,
    output [1:0]                s_RRESP_o,
    input                       s_RREADY_i

);


 //================ REG R=================//
	 
    reg [4:0] mem_ptr_r;
    reg [7:0] burst_cnt_r;
    reg [ID_WIDTH-1:0] saved_id_r;  //chua dung
    reg [2:0] state_r, next_state_r;
	 
	 reg  [ADDR_WIDTH-1:0]     reg_s_ARADDR_i;
    reg  [1:0]                reg_s_ARBURST_i;
    reg  [7:0]                reg_s_ARLEN_i;
    reg  [2:0]                reg_s_ARSIZE_i;
	 
		//BURST R signed
	 wire [7:0] beat_size_r  = (1 << reg_s_ARSIZE_i);     // số byte mỗi beat
	 wire [7:0] burst_len_r  = reg_s_ARLEN_i + 1;         // số beat
	 wire [15:0] boundary_r   = burst_len_r * beat_size_r; // kích thước block
	 wire [ADDR_WIDTH-1:0] mask_r       = boundary_r - 1;
	 wire [ADDR_WIDTH-1:0] wrap_base_r  = reg_s_ARADDR_i & ~mask_r;    //  ARADDR ban đầu
	 wire [ADDR_WIDTH-1:0] offset_r     = mem_ptr_r & mask_r;
	 wire [31:0] next_offset_r= (offset_r + beat_size_r) & mask_r;  //dia chi tiep theo
	 
	 
	 integer i;
	localparam 		IDLE  = 3'd0,
						AR    = 3'd1,
						RDATA = 3'd2,
						WAIT  = 3'd3;
		
	//================ STATE R =================//
	 //==========================================//
	 
    always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_r <= IDLE;
        else state_r <= next_state_r;
	
	//================ NEXT STATE R =================//
	 //===============================================//
    
    always @(*) begin
        case(state_r)
        IDLE:
            if (s_ARVALID_i) next_state_r = AR;
            else next_state_r = IDLE;

        AR:
            if (s_ARVALID_i && s_ARREADY_o && r_ram_access) next_state_r = RDATA;
				else
				if (s_ARVALID_i && s_ARREADY_o && r_ram_access) next_state_r = WAIT;
            else next_state_r = AR;
		  
		  WAIT:	
				if (r_ram_access) next_state_r = RDATA;
				else next_state_r = WAIT;
		  
        RDATA:
            if (s_RVALID_o && s_RREADY_i && s_RLAST_o)
                next_state_r = IDLE;
            else
				if (!r_ram_access) next_state_r = WAIT;
				else
				if (s_RVALID_o && s_RREADY_i && !s_RLAST_o)
					next_state_r = RDATA;
				else next_state_r = RDATA;

        default: next_state_r = IDLE;
        endcase
    end
	 
	 //================ ADDRESS / BURST R =================//
	 //====================================================//
	 
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            mem_ptr_r <= 0;
            burst_cnt_r <= 0;
        end
        else begin
            case(state_r)

            AR: begin
                if (s_ARVALID_i && s_ARREADY_o) begin
                    mem_ptr_r <= s_ARADDR_i; 
                    burst_cnt_r <= 0;
                    saved_id_r <= s_ARID_i;
						  
						  reg_s_ARADDR_i <=s_ARADDR_i;
						  reg_s_ARBURST_i <=s_ARBURST_i;
						  reg_s_ARLEN_i <= s_ARLEN_i;
						  reg_s_ARSIZE_i <= s_ARSIZE_i;
						  
                end
            end

            RDATA: begin
                if (s_RVALID_o && s_RREADY_i) begin
							case (reg_s_ARBURST_i)   //addr se thay doi tuy vao arbusrt
								00 :	mem_ptr_r <= mem_ptr_r;
								01 :  mem_ptr_r <= mem_ptr_r + beat_size_r;
								10 : 	mem_ptr_r <= wrap_base_r | next_offset_r;   //wrap_base da clear phan dau cua block, next_offset da clear vi tri ben trong block nen or lai la add
								11 : ;
					 		default: mem_ptr_r <= mem_ptr_r;           
							endcase
							/*for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
								 if (i < beat_size_r)
									  s_RDATA_o[i*8 +: 8] <= mem[addr_r + i];
							end*/
					 		burst_cnt_r <= burst_cnt_r + 1;
					 end
            end

            default: ;
            endcase
        end
    end

	 //================ OUTPUT =================//
	 //=========================================//
	 //CONTROL
   assign r_busy = (state_r == RDATA);
	assign r_request = (state_r == WAIT || state_r == RDATA);
	 //RAM
	 assign ram_address =mem_ptr_r;
	 assign ram_wren = (state_r == RDATA && r_ram_access) ? 1:0;
	 
    // READ ADDRESS
    assign s_ARREADY_o = (state_r == AR);

    // READ DATA
    assign s_RVALID_o = (state_r == RDATA);
	 assign s_RDATA_o = ram_data_out;
		  				
					
endmodule