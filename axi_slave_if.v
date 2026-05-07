module axi_slave_if #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                       ACLK_i,
    input                       ARESETn_i,
	 //CONTROL
/*	 input [5:0] s_address_memory,
	 input [DATA_WIDTH-1:0] s_DATA_MEMORY_i,
	 input s_WRITE_EN,
*/
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
    input                       s_BREADY_i,

    // READ ADDRESS
    input                       s_ARVALID_i,
    input  [ID_WIDTH-1:0]       s_ARID_i,
    input  [ADDR_WIDTH-1:0]     s_ARADDR_i,
    input  [7:0]                s_ARLEN_i,
	 input  [1:0]					  s_ARBURST_i,
	 input  [2:0]                s_ARSIZE_i,    //chua lam viec voi tk size
    output                      s_ARREADY_o,

    // READ DATA
    output                      s_RVALID_o,
    output                      s_RLAST_o,
    output [ID_WIDTH-1:0]       s_RID_o,
    output [DATA_WIDTH-1:0]     s_RDATA_o,
    output [1:0]                s_RRESP_o,
    input                       s_RREADY_i
);
	 //=========================================//
    //================ MEMORY =================//
	 //=========================================//
    reg [7:0] mem [0:1024];
		
/*	 always @(posedge ACLK_i)
        if (s_WRITE_EN)
            mem[s_address_memory] <= s_DATA_MEMORY_i;	
*/	 
	 //=======================================//
    //================ REG R=================//
	 //=======================================//
	 
    reg [4:0] addr_r;
    reg [7:0] burst_cnt_r;
    reg [ID_WIDTH-1:0] saved_id_r;
    reg [2:0] state_r, next_state_r;
	 
		//BURST R signed
	 wire [31:0] beat_size_r  = (1 << s_ARSIZE_i);     // số byte mỗi beat
	 wire [31:0] burst_len_r  = s_ARLEN_i + 1;         // số beat
	 wire [31:0] boundary_r   = burst_len_r * beat_size_r; // kích thước block
	 wire [31:0] mask_r       = boundary_r - 1;
	 wire [31:0] wrap_base_r  = s_ARADDR_i & ~mask_r;    //  ARADDR ban đầu
	 wire [31:0] offset_r     = addr_r & mask_r;
	 wire [31:0] next_offset_r= (offset_r + beat_size_r) & mask_r;
	 
	 
	 //=======================================//
	 //================ REG W=================//
	 //=======================================//
	 
	 reg [4:0] addr_w;   
	 reg [7:0] burst_cnt_w;
	 reg [ID_WIDTH-1:0] saved_id_w;
	 reg [2:0] state_w, next_state_w;
	 
	 	//BURST W signed
	 wire [31:0] beat_size_w  = (1 << s_AWSIZE_i);     // số byte mỗi beat
	 wire [31:0] burst_len_w  = s_AWLEN_i + 1;         // số beat
	 wire [31:0] boundary_w   = burst_len_w * beat_size_w; // kích thước block
	 wire [31:0] mask_w       = boundary_w - 1;
	 wire [31:0] wrap_base_w  = s_AWADDR_i & ~mask_w;    //  AWADDR ban đầu
	 wire [31:0] offset_w     = addr_w & mask_w;
	 wire [31:0] next_offset_w= (offset_w + beat_size_w) & mask_w;
	 
	 //=================================================//
	 //================PARAMETER STATE =================//
	 //=================================================//
	 
    localparam IDLE  = 3'd0,
               AR    = 3'd1,
               RDATA = 3'd2,
               AW    = 3'd3,
               WDATA = 3'd4,
               BRESP = 3'd5;

    integer i;

    //================ RESET + MEMORY =================//
  /*  always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
  //          for (i=0;i<32;i=i+1)
    //            mem[i] <= 0;
            addr <= 0;
            burst_cnt <= 0;
     //       saved_id <= 0;
        end
    end*/
		
	 //==========================================//	
    //================ STATE R =================//
	 //==========================================//
	 
    always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_r <= IDLE;
        else state_r <= next_state_r;

	 //==========================================//
	 //================ STATE W =================//
	 //==========================================// 
	 
	 always @(posedge ACLK_i or negedge ARESETn_i)
        if (!ARESETn_i) state_w <= IDLE;
        else state_w <= next_state_w;
		  
	 //===============================================//
    //================ NEXT STATE R =================//
	 //===============================================//
    
    always @(*) begin
        case(state_r)
        IDLE:
            if (s_ARVALID_i) next_state_r = AR;
            else next_state_r = IDLE;

        AR:
            if (s_ARVALID_i && s_ARREADY_o) next_state_r = RDATA;
            else next_state_r = AR;

        RDATA:
            if (s_RVALID_o && s_RREADY_i && s_RLAST_o)
                next_state_r = IDLE;
            else
                next_state_r = RDATA;

        default: next_state_r = IDLE;
        endcase
    end
	 
	 //===============================================//
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
	 
	 //====================================================//
    //================ ADDRESS / BURST R =================//
	 //====================================================//
	 
    always @(posedge ACLK_i or negedge ARESETn_i) begin
        if (!ARESETn_i) begin
            addr_r <= 0;
            burst_cnt_r <= 0;
        end
        else begin
            case(state_r)

            AR: begin
                if (s_ARVALID_i && s_ARREADY_o) begin
                    addr_r <= s_ARADDR_i; 
                    burst_cnt_r <= 0;
                    saved_id_r <= s_ARID_i;
                end
            end

            RDATA: begin
                if (s_RVALID_o && s_RREADY_i) begin
							case (s_ARBURST_i)   //addr se thay doi tuy vao arbusrt
								00 :	addr_r <= addr_r;
								01 :  addr_r <= addr_r + beat_size_r;
								10 : 	addr_r <= wrap_base_r | next_offset_r;   //wrap_base da clear phan dau cua block, next_offset da clear vi tri ben trong block nen or lai la add
								11 : ;
					 		default: addr_r <= addr_r;           
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

	 //====================================================//
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
                end
            end

            WDATA: begin
                if (s_WVALID_i && s_WREADY_o) begin
						 case (s_AWBURST_i)   //addr se thay doi tuy vao arbusrt
									00 :	addr_w <= addr_w;
									01 :  addr_w <= addr_w + beat_size_w;
									10 : 	addr_w <= wrap_base_w | next_offset_w;   //wrap_base da clear phan dau cua block, next_offset da clear vi tri ben trong block nen or lai la add
									11 : ;
						 default: addr_w <= addr_w;           
						 endcase
						 for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
							  if (i < beat_size_w)
									mem[addr_w + i] <= s_WDATA_i[i*8 +: 8];
						 end
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
	 
    // READ ADDRESS
    assign s_ARREADY_o = (state_r == AR);

    // READ DATA
    assign s_RVALID_o = (state_r == RDATA);
	 genvar j;

	 generate
		  for (j = 0; j < DATA_WIDTH/8; j = j + 1) begin : GEN_RDATA
			  assign s_RDATA_o [j*8 +: 8] = mem[addr_r + j];
		  end 
	 endgenerate
    //assign s_RDATA_o  = mem[addr_r];
    assign s_RID_o    = saved_id_r;
    assign s_RLAST_o  = (burst_cnt_r == s_ARLEN_i);
    assign s_RRESP_o  = 2'b00;

    // WRITE ADDRESS
    assign s_AWREADY_o = (state_w == AW);

    // WRITE DATA
    assign s_WREADY_o = (state_w == WDATA);

    // WRITE RESP
    assign s_BVALID_o = (state_w == BRESP);
    assign s_BRESP_o  = 2'b00;
    assign s_BID_o    = saved_id_w;

endmodule