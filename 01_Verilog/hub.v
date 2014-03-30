/*
 * HUB Memory & resources
 *
 *
 */
`include "acog_defs.v"  
module HUB_Sim(
	input wire 			clk_in,
	input wire 			reset_in,
	
	/* Cog 0 */
	input wire [16:0] 	hub_mem_addr_0_in, /* Address */
	input wire [31:0] 	hub_mem_data_0_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_0_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_mem_read_0_in, /* Read request */
	input wire			hub_mem_write_0_in,	/* Write request */
	output reg			hub_mem_ack_0_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_0_o,
	/* Cog 1 */
	input wire [16:0] 	hub_mem_addr_1_in, /* Address */
	input wire [31:0] 	hub_mem_data_1_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_1_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_mem_read_1_in, /* Read request */
	input wire			hub_mem_write_1_in,	/* Write request */
	output reg			hub_mem_ack_1_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_1_o,
	/* Cog 2 */
	input wire [16:0] 	hub_mem_addr_2_in, /* Address */
	input wire [31:0] 	hub_mem_data_2_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_2_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_mem_read_2_in, /* Read request */
	input wire			hub_mem_write_2_in,	/* Write request */
	output reg			hub_mem_ack_2_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_2_o,
	/* Cog 3 */
	input wire [16:0] 	hub_mem_addr_3_in, /* Address */
	input wire [31:0] 	hub_mem_data_3_in,	/* Write data is left aligned */
	input wire [1:0] 	hub_mem_size_3_in, /* 00: byte, 01: word, 10: long */
	input wire			hub_mem_read_3_in, /* Read request */
	input wire			hub_mem_write_3_in,	/* Write request */
	output reg			hub_mem_ack_3_o,	/* asserted when data has been written or is ready to be latched */
	output reg [31:0]	hub_mem_data_3_o
	);
reg [1:0] hub_left_active_cog, hub_right_active_cog;
reg [1:0] hub_left_active_cog_delayed, hub_right_active_cog_delayed;
// memory
reg [14:0] hub_addr_left, hub_addr_right;
reg [31:0] hub_data_left_in, hub_data_right_in;
wire [31:0] hub_data_left_o, hub_data_right_o;
reg [3:0] hub_writeen_left, hub_writeen_right;
wire hub_write_left, hub_write_right;

assign hub_write_left = (hub_mem_write_0_in & (!hub_left_active_cog[0])) | 
                        (hub_mem_write_2_in & (hub_left_active_cog[0]));
assign hub_write_right =(hub_mem_write_1_in & (!hub_right_active_cog[0])) | 
                        (hub_mem_write_3_in & (hub_right_active_cog[0]));


always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				hub_left_active_cog <= 0;
				hub_right_active_cog <= 0;
			end
		else
			begin
				hub_left_active_cog <= hub_left_active_cog + 2'h1;
				hub_right_active_cog <= hub_right_active_cog + 2'h1;
			end
		hub_right_active_cog_delayed <= hub_right_active_cog;
		hub_left_active_cog_delayed <= hub_left_active_cog;
	end

/* Arbitration 
 *
 * Round robin for the time being
 */
always @(posedge clk_in)
	begin
		hub_mem_ack_0_o <= 1'b0;
		hub_mem_ack_1_o <= 1'b0;
		hub_mem_ack_2_o <= 1'b0;
		hub_mem_ack_3_o <= 1'b0;
		// left side
		if (hub_mem_read_0_in | hub_mem_write_0_in)
			begin
				if (!hub_left_active_cog[0]) hub_mem_ack_0_o <= 1'b1; // ready
			end
		if (hub_mem_read_2_in | hub_mem_write_2_in)
			begin
				if (hub_left_active_cog[0]) hub_mem_ack_2_o <= 1'b1; // ready
			end
		// right side
		if (hub_mem_read_1_in | hub_mem_write_1_in)
			begin
				if (!hub_right_active_cog[0]) hub_mem_ack_1_o <= 1'b1; // ready
			end
		if (hub_mem_read_3_in | hub_mem_write_3_in)
			begin
				if (hub_right_active_cog[0]) hub_mem_ack_3_o <= 1'b1; // ready
			end
	end
	
// MUXES
// Left address
always @(*)
	begin
		hub_addr_left = 0;
		casex (hub_left_active_cog)
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
		casex (hub_left_active_cog)
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
// left data to mem mux
always @(*)
	begin
		hub_data_left_in = 32'h0;
		casex (hub_left_active_cog)
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
// left data to cog mux
always @(posedge clk_in)
	begin
		casex (hub_left_active_cog_delayed)
			2'bx0: 	case (hub_mem_size_0_in)
						2'b00: 	case (hub_mem_addr_0_in[1:0]) // byte
									2'b00: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[7:0] };
									2'b01: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[15:8] };
									2'b10: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[23:16] };
									2'b11: hub_mem_data_0_o <= { 24'h0, hub_data_left_o[31:24] };
								endcase
						2'b01: 	case (hub_mem_addr_0_in[1]) // word
									1'b0: hub_mem_data_0_o <= { 16'h0, hub_data_left_o[15:0] };
									1'b1: hub_mem_data_0_o <= { 16'h0, hub_data_left_o[31:16] };
								endcase
						2'b10, 2'b11: hub_mem_data_0_o[31:0] <= hub_data_left_o[31:0]; // long
					endcase
			2'bx1: 	case (hub_mem_size_2_in)
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
	end
// Right path
always @(*)
	begin
		casex (hub_right_active_cog)
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
// right data to mem mux
always @(*)
	begin
		casex (hub_right_active_cog)
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
		casex (hub_right_active_cog_delayed)
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
`else
`ifdef LATTICE_MACHXO2 

cog0_mem mem(
	.DataInA(), 
	.DataInB(d_data_in), 
	.AddressA(left_addr_mux), 
	.AddressB(muxed_d_addr), 
	.ClockA(clk_in), 
	.ClockB(clk_in), 
    .ClockEnA(1'b1), 
	.ClockEnB(1'b1), 
	.WrA(1'b0), 
	.WrB(d_write_in & (state_in == `ST_WBACK)), 
	.ResetA(1'b0), 
	.ResetB(1'b0), 
	.QA(s_data_from_memory),
	.QB(d_data_from_memory));
`else //ALTERA_CV
`ifdef ALTERA_CV
cog_mem_altera (
	.address_a(left_addr_mux),
	.address_b(muxed_d_addr),
	.clock(clk_in),
	.data_a(32'b0),
	.data_b(d_data_in),
	.wren_a(1'b0),
	.wren_b(d_write_in & (state_in == `ST_WBACK)),
	.q_a(s_data_from_memory),
	.q_b(d_data_from_memory));
`endif
`endif // ifdef LATTICE...
`endif // ifdef SIMULATOR

initial
	begin
		hub_left_active_cog = 0;
		hub_right_active_cog = 0;
	end


endmodule

/* HUB Memory, platform independent */





/* 64 kbytes HUB memory */
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
	end
endmodule
