/*
 * HUB Memory & resources
 *
 *
 */
`include "acog_defs.v"  
module HUB(
	input wire 			clk_in,
	input wire 			reset_in,
	
	/* Cog 0 */
	input wire [4:0]	hub_op_0_in,			/* hub opcode */
	input wire [16:0] 	hub_mem_addr_0_in, /* Address */
	input wire [31:0] 	hub_mem_data_0_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_0_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_data_rdy_0_in, /* Read request */
	output wire			hub_mem_ack_0_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_0_o,	output wire			hub_cog_reset_0_o,		/* reset of cog 0 */
	/* Cog 1 */
	input wire [4:0]	hub_op_1_in,
	input wire [16:0] 	hub_mem_addr_1_in, /* Address */
	input wire [31:0] 	hub_mem_data_1_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_1_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_data_rdy_1_in, /* Read request */
	output wire			hub_mem_ack_1_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_1_o,
	output wire			hub_cog_reset_1_o,		/* reset of cog 0 */
	/* Cog 2 */
	input wire [4:0]	hub_op_2_in,
	input wire [16:0] 	hub_mem_addr_2_in, /* Address */
	input wire [31:0] 	hub_mem_data_2_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_2_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_data_rdy_2_in, /* Read request */
	output wire			hub_mem_ack_2_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_2_o,
	output wire			hub_cog_reset_2_o,		/* reset of cog 0 */
	/* Cog 3 */
	input wire [4:0]	hub_op_3_in,
	input wire [16:0] 	hub_mem_addr_3_in, /* Address */
	input wire [31:0] 	hub_mem_data_3_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_3_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_data_rdy_3_in, /* Read request */
	output wire			hub_mem_ack_3_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_3_o,
	output wire			hub_cog_reset_3_o 		/* reset of cog 3 */
	
	);
reg [2:0] hub_active_cog;
reg [2:0] hub_active_cog_delayed;
// memory
reg [14:0] hub_addr_left, hub_addr_right;
reg [31:0] hub_data_left_in, hub_data_right_in;
wire [31:0] hub_data_left_o, hub_data_right_o;
reg [`HUB_MAX_COGS-1:0] hub_writeen_left, hub_writeen_right;
reg [`HUB_MAX_COGS-1:0] hub_ack_cog;
reg [`HUB_MAX_COGS-1:0] active_cogs;
reg was_in_reset; // used to detect reset high->low transition
/* used by coginit */
reg [2:0] started_cog_0, started_cog_1, started_cog_2, started_cog_3;

wire hub_write_left, hub_write_right;
wire [2:0] first_free_cog;
wire no_free_cogs;

assign hub_write_left = ((hub_op_0_in[4:3] == 2'b10) & hub_data_rdy_0_in & (!hub_active_cog[0])) | 
                        ((hub_op_2_in[4:3] == 2'b10) & hub_data_rdy_2_in & (hub_active_cog[0]));
assign hub_write_right =((hub_op_1_in[4:3] == 2'b10) & hub_data_rdy_1_in & (!hub_active_cog[0])) | 
                        ((hub_op_3_in[4:3] == 2'b10) & hub_data_rdy_3_in & (hub_active_cog[0]));

assign hub_cog_reset_0_o = !active_cogs[0]; // resets are active high
assign hub_cog_reset_1_o = !active_cogs[1];
assign hub_cog_reset_2_o = !active_cogs[2];
assign hub_cog_reset_3_o = !active_cogs[3];

assign hub_mem_ack_0_o = hub_ack_cog[0];
assign hub_mem_ack_1_o = hub_ack_cog[1];
assign hub_mem_ack_2_o = hub_ack_cog[2];
assign hub_mem_ack_3_o = hub_ack_cog[3];


enc8to1 enc_free_cog(
	.in({4'b1111, active_cogs}), // for the time being only 4
	.enc(first_free_cog),
	.overflow(no_free_cogs)
	);

always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				hub_active_cog <= 3'h0;
				active_cogs 	<= 3'h0; // All cogs disabled */
				was_in_reset 	<= 1'b1; // set
			end
		else
			begin
				if (was_in_reset)
					active_cogs[0] <= 1'b1; // launches COG0, the other cogs remain dormant
			
				hub_active_cog <= hub_active_cog + 3'h1;
			end
		hub_active_cog_delayed <= hub_active_cog;
	end

/* Arbitration and HUB opcode execution
 *
 * Round robin for the time being
 */
always @(posedge clk_in)
	begin
		hub_ack_cog <= 0;
		// left side
		// COG 0
		if (hub_data_rdy_0_in)
			begin
				casex (hub_op_0_in)
					5'b01000: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready// CLKSET
					5'b01001: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready// COGID
					5'b01010: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready// COGINIT
					5'b01011: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready// COGSTOP
					5'b01100: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready
					5'b01101: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready
					5'b01110: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready
					5'b01111: if (hub_active_cog == 3'b000) hub_ack_cog[0] <= 1'b1; // ready
					5'b1xxxx: if (!hub_active_cog[0]) hub_ack_cog[0] <= 1'b1; // ready
					default: // ignore if invalid
						begin end
				endcase
			end
		// COG 2
		if ((hub_op_2_in[4:3] != 2'b00) & hub_data_rdy_2_in)
			begin
				if (hub_active_cog[0]) hub_ack_cog[2] <= 1'b1; // ready
			end
		// right side
		if ((hub_op_1_in[4:3] != 2'b00) & hub_data_rdy_1_in)
			begin
				if (!hub_active_cog[0]) hub_ack_cog[1] <= 1'b1; // ready
			end
		if ((hub_op_3_in[4:3] != 2'b00) & hub_data_rdy_3_in)
			begin
				if (hub_active_cog[0]) hub_ack_cog[3] <= 1'b1; // ready
			end
	end
	
// MUXES
// Left address
always @(*)
	begin
		hub_addr_left = 0;
		casex (hub_active_cog[1:0])
			2'bx0: hub_addr_left = hub_mem_addr_0_in[16:2];
			2'bx1: hub_addr_left = hub_mem_addr_2_in[16:2];
			//2'b10: hub_addr_left = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_left = hub_mem_addr_6_in[16:2];
		endcase
	end
// left data to memory byte selects
always @(*)
	begin
		hub_writeen_left = 0;
		casex (hub_active_cog)
			2'bx0: 	case (hub_mem_size_0_in)
						2'b00: 	case (hub_mem_addr_0_in[1:0]) // byte
									2'b00: hub_writeen_left = 4'h1;
									2'b01: hub_writeen_left = 4'h2;
									2'b10: hub_writeen_left = 4'h4;
									2'b11: hub_writeen_left = 4'h8;
								endcase
						2'b01: 	case (hub_mem_addr_0_in[1]) // word
									1'b0: hub_writeen_left = 4'h3;
									1'b1: hub_writeen_left = 4'hc;
								endcase
						2'b10, 2'b11: hub_writeen_left = 4'hf; // long
					endcase
			2'bx1: 	case (hub_mem_size_2_in)
						2'b00: 	case (hub_mem_addr_2_in[1:0]) // byte
									2'b00: hub_writeen_left = 4'h1;
									2'b01: hub_writeen_left = 4'h2;
									2'b10: hub_writeen_left = 4'h4;
									2'b11: hub_writeen_left = 4'h8;
								endcase
						2'b01: 	case (hub_mem_addr_2_in[1]) // word
									1'b0: hub_writeen_left = 4'h3;
									1'b1: hub_writeen_left = 4'hc;
								endcase
						2'b10, 2'b11: hub_writeen_left = 4'hf; // long
					endcase
			//2'b10: hub_addr_left = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_left = hub_mem_addr_6_in[16:2];
		endcase
	end
// left path, data to be written to HUB mem mux
always @(*)
	begin
		hub_data_left_in = 32'h0;
		casex (hub_active_cog)
			2'bx0: 	case (hub_mem_size_0_in)
						2'b00: 	case (hub_mem_addr_0_in[1:0]) // byte
									2'b00: hub_data_left_in[ 7: 0] = hub_mem_data_0_in[7:0];
									2'b01: hub_data_left_in[15: 8] = hub_mem_data_0_in[7:0];
									2'b10: hub_data_left_in[23:16] = hub_mem_data_0_in[7:0];
									2'b11: hub_data_left_in[31:24] = hub_mem_data_0_in[7:0];
								endcase
						2'b01: 	case (hub_mem_addr_0_in[1]) // word
									1'b0: hub_data_left_in[15: 0] = hub_mem_data_0_in[15:0];
									1'b1: hub_data_left_in[31:16] = hub_mem_data_0_in[15:0];
								endcase
						2'b10, 2'b11: hub_data_left_in[31:0] = hub_mem_data_0_in[31:0]; // long
					endcase
			2'bx1: 	case (hub_mem_size_2_in)
						2'b00: 	case (hub_mem_addr_2_in[1:0]) // byte
									2'b00: hub_data_left_in[ 7: 0] = hub_mem_data_2_in[7:0];
									2'b01: hub_data_left_in[15: 8] = hub_mem_data_2_in[7:0];
									2'b10: hub_data_left_in[23:16] = hub_mem_data_2_in[7:0];
									2'b11: hub_data_left_in[31:24] = hub_mem_data_2_in[7:0];
								endcase
						2'b01: 	case (hub_mem_addr_2_in[1]) // word
									1'b0: hub_data_left_in[15: 0] = hub_mem_data_2_in[15:0];
									1'b1: hub_data_left_in[31:16] = hub_mem_data_2_in[15:0];
								endcase
						2'b10, 2'b11: hub_data_left_in[31:0] = hub_mem_data_2_in[31:0]; // long
					endcase
			//2'b10: hub_addr_left = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_left = hub_mem_addr_6_in[16:2];
		endcase
	end
// mux from HUB left data path to cog 
// the c flag should also be written here
// and stored in wback
always @(posedge clk_in)
	begin
		case (hub_active_cog_delayed[0])
			1'b0: casex (hub_op_0_in)
						5'b01000: begin end // we do not read
						5'b01001: hub_mem_data_0_o <= 32'h0; // COGID
						5'b01010: hub_mem_data_0_o <= { 29'h0, started_cog_0 }; // COGINIT, returns cogid of recently started COG.
						5'b01011: hub_mem_data_0_o <= { 29'h0, hub_mem_data_0_in [2:0] }; // COGSTOP writes back # of cog stopped
						5'b01100: begin end // locknew
						5'b01101: begin end // lockret
						5'b01110: begin end // lockset
						5'b01111: begin end // lockclr
						5'b1xxxx: // RDxxx/WRxxx
									case (hub_mem_size_0_in)
										`SZ_BYTE: 	case (hub_mem_addr_0_in[1:0]) // byte
													2'b00: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[7:0] };
													2'b01: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[15:8] };
													2'b10: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[23:16] };
													2'b11: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[31:24] };
												endcase
										`SZ_WORD: 	case (hub_mem_addr_0_in[1]) // word
													1'b0: hub_mem_data_0_o <= { 16'h0, hub_data_left_o[15:0] };
													1'b1: hub_mem_data_0_o <= { 16'h0, hub_data_left_o[31:16] };
												endcase
										`SZ_LONG: hub_mem_data_0_o[31:0] <= hub_data_left_o[31:0]; // long
									endcase
					endcase
			1'b1: casex (hub_op_2_in)
						5'b01000: begin end // we do not read
						5'b01001: hub_mem_data_2_o <= 32'h0; // COGID
						5'b01010: hub_mem_data_2_o <= { 29'h0, started_cog_2 }; // COGINIT, returns cogid of recently started COG.
						5'b01011: hub_mem_data_2_o <= { 29'h0, hub_mem_data_2_in [2:0] }; // COGSTOP writes back # of cog stopped
						5'b01100: begin end // locknew
						5'b01101: begin end // lockret
						5'b01110: begin end // lockset
						5'b01111: begin end // lockclr
						5'b1xxxx: // RDxxx/WRxxx
									case (hub_mem_size_2_in)
										`SZ_BYTE:case (hub_mem_addr_2_in[1:0]) // byte
													2'b00: hub_mem_data_2_o <= { 24'h0, hub_data_left_o[7:0] };
													2'b01: hub_mem_data_2_o <= { 24'h0, hub_data_left_o[15:8] };
													2'b10: hub_mem_data_2_o <= { 24'h0, hub_data_left_o[23:16] };
													2'b11: hub_mem_data_2_o <= { 24'h0, hub_data_left_o[31:24] };
												endcase
										`SZ_WORD:case (hub_mem_addr_2_in[1]) // word
													1'b0: hub_mem_data_2_o <= { 16'h0, hub_mem_data_0_in[15:0] };
													1'b1: hub_mem_data_2_o <= { 16'h0, hub_mem_data_0_in[31:16] };
												endcase
										`SZ_LONG, 2'b11: hub_mem_data_0_o <= hub_data_left_o[31:0]; // long
									endcase
					endcase
		endcase
	end
// Right path
always @(*)
	begin
		casex (hub_active_cog)
			2'bx0: 	case (hub_mem_size_0_in)
						2'b00: 	case (hub_mem_addr_0_in[1:0]) // byte
									2'b00: hub_writeen_right = 4'h1;
									2'b01: hub_writeen_right = 4'h2;
									2'b10: hub_writeen_right = 4'h4;
									2'b11: hub_writeen_right = 4'h8;
								endcase
						2'b01: 	case (hub_mem_addr_0_in[1]) // word
									1'b0: hub_writeen_right = 4'h3;
									1'b1: hub_writeen_right = 4'hc;
								endcase
						2'b10, 2'b11: hub_writeen_right = 4'hf; // long
					endcase
			2'bx1: 	case (hub_mem_size_2_in)
						2'b00: 	case (hub_mem_addr_2_in[1:0]) // byte
									2'b00: hub_writeen_right = 4'h1;
									2'b01: hub_writeen_right = 4'h2;
									2'b10: hub_writeen_right = 4'h4;
									2'b11: hub_writeen_right = 4'h8;
								endcase
						2'b01: 	case (hub_mem_addr_2_in[1]) // word
									1'b0: hub_writeen_right = 4'h3;
									1'b1: hub_writeen_right = 4'hc;
								endcase
						2'b10, 2'b11: hub_writeen_right = 4'hf; // long
					endcase
			//2'b10: hub_addr_right = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_right = hub_mem_addr_6_in[16:2];
		endcase
	end
// right path, data to be written to HUB mem mux
always @(*)
	begin
		hub_data_right_in = 32'b0;
		casex (hub_active_cog)
			2'bx0: 	case (hub_mem_size_0_in)
						2'b00: 	case (hub_mem_addr_0_in[1:0]) // byte
									2'b00: hub_data_right_in[ 7: 0] = hub_mem_data_0_in[7:0];
									2'b01: hub_data_right_in[15: 8] = hub_mem_data_0_in[7:0];
									2'b10: hub_data_right_in[23:16] = hub_mem_data_0_in[7:0];
									2'b11: hub_data_right_in[31:24] = hub_mem_data_0_in[7:0];
								endcase
						2'b01: 	case (hub_mem_addr_0_in[1]) // word
									1'b0: hub_data_right_in[15: 0] = hub_mem_data_0_in[15:0];
									1'b1: hub_data_right_in[31:16] = hub_mem_data_0_in[15:0];
								endcase
						2'b10, 2'b11: hub_data_right_in[31:0] = hub_mem_data_0_in[31:0]; // long
					endcase
			2'bx1: 	case (hub_mem_size_2_in)
						2'b00: 	case (hub_mem_addr_2_in[1:0]) // byte
									2'b00: hub_data_right_in[ 7: 0] = hub_mem_data_2_in[7:0];
									2'b01: hub_data_right_in[15: 8] = hub_mem_data_2_in[7:0];
									2'b10: hub_data_right_in[23:16] = hub_mem_data_2_in[7:0];
									2'b11: hub_data_right_in[31:24] = hub_mem_data_2_in[7:0];
								endcase
						2'b01: 	case (hub_mem_addr_2_in[1]) // word
									1'b0: hub_data_right_in[15: 0] = hub_mem_data_2_in[15:0];
									1'b1: hub_data_right_in[31:16] = hub_mem_data_2_in[15:0];
								endcase
						2'b10, 2'b11: hub_data_right_in[31:0] = hub_mem_data_2_in[31:0]; // long
					endcase
			//2'b10: hub_addr_right = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_right = hub_mem_addr_6_in[16:2];
		endcase
	end
// right data to cog mux
always @(posedge clk_in)
	begin
		casex (hub_active_cog_delayed)
			2'bx0: 	case (hub_mem_size_1_in)
						2'b00: 	case (hub_mem_addr_1_in[1:0]) // byte
									2'b00: hub_mem_data_1_o <= { 24'h0, hub_data_right_o[7:0] };
									2'b01: hub_mem_data_1_o <= { 24'h0, hub_data_right_o[15:8] };
									2'b10: hub_mem_data_1_o <= { 24'h0, hub_data_right_o[23:16] };
									2'b11: hub_mem_data_1_o <= { 24'h0, hub_data_right_o[31:24] };
								endcase
						2'b01: 	case (hub_mem_addr_1_in[1]) // word
									1'b0: hub_mem_data_1_o <= { 16'h0, hub_data_right_o[15:0] };
									1'b1: hub_mem_data_1_o <= { 16'h0, hub_data_right_o[31:16] };
								endcase
						2'b10, 2'b11: hub_mem_data_1_o <= hub_data_right_o; // long
					endcase
			2'bx1: 	case (hub_mem_size_3_in)
						2'b00: 	case (hub_mem_addr_3_in[1:0]) // byte
									2'b00: hub_mem_data_3_o <= { 24'h0, hub_data_right_o[7:0] };
									2'b01: hub_mem_data_3_o <= { 24'h0, hub_data_right_o[15:8] };
									2'b10: hub_mem_data_3_o <= { 24'h0, hub_data_right_o[23:16] };
									2'b11: hub_mem_data_3_o <= { 24'h0, hub_data_right_o[31:24] };
								endcase
						2'b01: 	case (hub_mem_addr_3_in[1]) // word
									1'b0: hub_mem_data_3_o <= { 16'h0, hub_mem_data_3_in[15:0] };
									1'b1: hub_mem_data_3_o <= { 16'h0, hub_mem_data_3_in[31:16] };
								endcase
						2'b10, 2'b11: hub_mem_data_3_o <= hub_data_right_o; // long
					endcase
			//2'b10: hub_addr_right = hub_mem_addr_4_in[16:2];
			//2'b11: hub_addr_right = hub_mem_addr_6_in[16:2];
		endcase
	end
/* HUB Memory, platform dependent */

`ifdef SIMULATOR
hub_memblock_dp_x32 mem(
	.clk_i(clk_in),
	.port_a_addr_i(hub_addr_left),
	.port_b_addr_i(hub_addr_right), 
	.port_a_rden_i(1'b1),
	.port_b_rden_i(1'b1),
	.port_a_q_o(hub_data_left_o),
	.port_b_q_o(hub_data_right_o),
	.port_a_wen_i(hub_write_left),
	.port_b_wen_i(hub_write_right),
	.port_a_data_i(hub_data_left_in),
	.port_b_data_i(hub_data_right_in),
	.port_a_byteen_i(hub_writeen_left),
	.port_b_byteen_i(hub_writeen_right) );
`endif

`ifdef LATTICE_MACHXO2 

`endif // LATTICE_MACHXO2

`ifdef ALTERA_CV
 hub_mem_altera mem(
	.address_a(hub_addr_left),
	.address_b(hub_addr_right),
	.byteena_a(hub_writeen_left),
	.byteena_b(hub_writeen_right),
	.clock(clk_in),
	.data_a(hub_data_left_in),
	.data_b(hub_data_right_in),
	.wren_a(hub_write_left),
	.wren_b(hub_write_right),
	.q_a(hub_data_left_o),
	.q_b(hub_data_right_o));
`endif // ifdef ALTERA_CV

initial
	begin
		was_in_reset = 0;
		hub_active_cog = 0;
	end


endmodule

/* HUB Memory, platform independent, for simulation only */




`ifdef SIMULATOR
/* 128 kbytes HUB memory, 32k LONGS */
module hub_memblock_dp_x32(
	input wire clk_i,
	input wire [14:0] port_a_addr_i,
	input wire [14:0] port_b_addr_i,
	input wire port_a_rden_i,
	input wire port_b_rden_i,
	output reg [31:0] port_a_q_o,
	output reg [31:0] port_b_q_o,
	input wire port_a_wen_i,
	input wire port_b_wen_i,
	input wire [31:0] port_a_data_i,
	input wire [31:0] port_b_data_i,
	input wire [3:0] port_a_byteen_i,
	input wire [3:0] port_b_byteen_i
	);

reg [31:0] mem[32768:0];

always @(posedge clk_i)
	begin
		if (port_a_rden_i)
			port_a_q_o <= mem[port_a_addr_i];
		if (port_b_rden_i)
			port_b_q_o <= mem[port_b_addr_i];
		if (port_a_wen_i)
			begin
				if (port_a_byteen_i[0]) mem[port_a_addr_i][7:0] <= port_a_data_i[ 7: 0];
				if (port_a_byteen_i[1]) mem[port_a_addr_i][15:8] <= port_a_data_i[15: 8];
				if (port_a_byteen_i[2]) mem[port_a_addr_i][23:16] <= port_a_data_i[23:16];
				if (port_a_byteen_i[3]) mem[port_a_addr_i][31:24] <= port_a_data_i[31:24];
			end
		if (port_b_wen_i)
			begin
				if (port_b_byteen_i[0]) mem[port_b_addr_i][7:0] <= port_b_data_i[ 7: 0];
				if (port_b_byteen_i[1]) mem[port_b_addr_i][15:8] <= port_b_data_i[15: 8];
				if (port_b_byteen_i[2]) mem[port_b_addr_i][23:16] <= port_b_data_i[23:16];
				if (port_b_byteen_i[3]) mem[port_b_addr_i][31:24] <= port_b_data_i[31:24];
			end
	end

integer i;
initial
	begin
		for ( i = 32'd0; i < 32'd16384; i = i + 32'd1)
			mem[i] = { 32'hDEAD, i[15:0] };

		mem[16'h3E00] = 32'b10100000111111111110100000000011; //-- mov dira, #3
		mem[16'h3E01] = 32'b10100000101111111100000111110001; //-- mov temp, CNT ($1E0)
		mem[16'h3E02] = 32'b10000000111111111100000000100000; //-- add temp, #32
		mem[16'h3E03] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[16'h3E04] = 32'b10100000111111111110110000000010; //-- mov porta, #2
		mem[16'h3E05] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[16'h3E06] = 32'b10100000111111111110110000000001; //-- mov porta, #1
		mem[16'h3E07] = 32'b01011100011111000000000000000011; //-- jmp #3
			
			
	end
endmodule

`endif

module enc8to1(
	input wire [7:0] in,
	output reg [2:0] enc,
	output reg overflow);
	
always @(*)
	begin
		overflow = 1'b0;
		enc = 3'h7;
		casex (in)
			8'bxxxxxxx0: enc = 3'h0;
			8'bxxxxxx01: enc = 3'h1;
			8'bxxxxx011: enc = 3'h2;
			8'bxxxx0111: enc = 3'h3;
			8'bxxx01111: enc = 3'h4;
			8'bxx011111: enc = 3'h5;
			8'bx0111111: enc = 3'h6;
			8'b01111111: enc = 3'h7;
			8'b11111111: overflow = 1'b1;
		endcase
	end
			
endmodule
