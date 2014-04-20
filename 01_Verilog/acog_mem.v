/* 
 * ACog - Memory
 *
 * Triple ported 32 bit wide memory
 */
`include "acog_defs.v" 
module acog_mem(
	input wire clk_in,
	input wire reset_in,
	input wire [31:0] CNT_in,
	input wire [1:0] state_in,
	input wire [2:0] cod_id_in, /* ID of this cog, retrieved with COGID */
	// fetch channel
	input wire [`MEM_WIDTH-1:0] f_addr_in,
	output wire [31:0] f_data_o,
	// s channel
	input wire [`MEM_WIDTH-1:0] s_addr_in,
	//input wire s_write_in,
	output reg [31:0] s_data_o,
	output reg [31:0] s_data_neg_o,
	// d channel
	input wire [`MEM_WIDTH-1:0] d_addr_in,
	input wire d_write_in,
	input wire [31:0] d_data_in,
	output reg [31:0] d_data_o,
	output reg d_data_is_zero_o,
	output reg d_data_is_one_o,
	output reg [31:0] d_lshift_o,
	output reg [31:0] d_rshift_o,
	// ports
	input wire [31:0] port_a_in,
	output wire [31:0] port_a_o,
	output wire [31:0] port_a_dir_o,
	input wire [31:0] port_b_in,
	output wire [31:0] port_b_o,
	output wire [31:0] port_b_dir_o,
	//
	output wire port_pne_pina_o,
	output wire port_peq_pina_o,
	output wire port_pne_pinb_o,
	output wire port_peq_pinb_o,
	output wire port_cnt_eq_d_o
	
	);

reg [31:0] PAR, INA, INB, OUTA, OUTB, DIRA, DIRB;

wire [`MEM_WIDTH-1:0] left_addr_mux, muxed_d_addr;
wire [31:0] s_data_from_memory, d_data_from_memory;
reg [31:0] d_mux, s_mux;
reg latched_i; // latched i flag in opcode
reg load_from_mem; // asserted when memory needs to be read (during READ cycle)
reg run_mode; // asserted during load from HUB to COG
reg [`MEM_WIDTH-1:0] latched_source_addr, latched_dest_addr;
assign left_addr_mux = (state_in == `ST_FETCH) ? f_addr_in:s_data_from_memory[8:0]; //s_addr_in;

assign f_data_o = s_data_from_memory;

assign port_a_o = OUTA;
assign port_b_o = OUTB;
assign port_a_dir_o = DIRA;
assign port_b_dir_o = DIRB;

assign port_cnt_eq_d_o = CNT_in == d_data_o;
assign port_peq_pina_o = d_data_o == (INA & s_data_o);
assign port_pne_pina_o = d_data_o != (INA & s_data_o);
assign port_peq_pinb_o = d_data_o == (INB & s_data_o);
assign port_pne_pinb_o = d_data_o != (INB & s_data_o);

always @(posedge clk_in)
	begin
		if (reset_in)
			begin
				run_mode <= 1'b0;
				PAR <= 32'b00000000000000_11111000000000_0_000;
			end
		else
			begin
				case (state_in)
					`ST_FETCH:
						begin
							INA <= port_a_in;
							INB <= port_b_in;
						end
					`ST_DECODE:
						begin
							latched_i <= s_data_from_memory[`OP_I];
							latched_source_addr <= s_data_from_memory[`MEM_WIDTH-1:0];
							latched_dest_addr <= s_data_from_memory[17:9];
							load_from_mem <= 1'b1; // prevents S&D to be loaded multiple times when in wait instructions
						end
					`ST_READ: // latch values from memory or registers
						begin
							if (load_from_mem)
								begin
									s_data_neg_o <= 32'h0 - s_mux; // used in abs, xxxabs, sumxx
									s_data_o <= s_mux;
									case (s_mux[1:0]) // pre-shift for D
										2'b00: d_lshift_o <= d_mux;
										2'b01: d_lshift_o <= { d_mux[30:0], 1'b0 };
										2'b10: d_lshift_o <= { d_mux[29:0], 2'b0 };
										2'b11: d_lshift_o <= { d_mux[28:0], 3'b0 };
									endcase
									case (s_mux[1:0]) // pre-shift for D
										2'b00: d_rshift_o <= d_mux;
										2'b01: d_rshift_o <= { 1'b0, d_mux[31:1] };
										2'b10: d_rshift_o <= { 2'b0, d_mux[31:2] };
										2'b11: d_rshift_o <= { 3'b0, d_mux[31:3] };
									endcase
									d_data_o <= d_mux;
									d_data_is_zero_o <= d_mux == 32'h0;
									d_data_is_one_o <= d_mux == 32'h0000_0001;
									load_from_mem <= 1'b0; // loaded in this cycle
								end
						end
					`ST_WBACK:
						if (d_write_in)
							begin
								case (d_addr_in)
									`R_OUTA: OUTA <= d_data_in;
									`R_OUTB: OUTB <= d_data_in;
									`R_DIRA:  DIRA <= d_data_in;
									`R_DIRB:  DIRB <= d_data_in;
								endcase
								if (d_addr_in == 9'h1ef) // run mode ends with the write to address 0
									run_mode <= 1'b1;
							end
				endcase
			end
	end

always @(*)
	begin
		if (latched_i)
			s_mux = { 23'h0, latched_source_addr };
		else
			begin
				s_mux = s_data_from_memory;
				case (s_addr_in)
					`R_PAR: if (run_mode) s_mux = { 18'h0, PAR[31:18] }; else s_mux = { 16'h0, PAR[17:4], 2'h0 };
					`R_CNT: if (run_mode) s_mux = CNT_in;
					`R_INA: if (run_mode) s_mux = INA;
					`R_INB: if (run_mode) s_mux = INB;
					`R_OUTA: if (run_mode) s_mux = OUTA;
					`R_OUTB: if (run_mode) s_mux = OUTB;
					`R_DIRA: if (run_mode) s_mux = DIRA;
					`R_DIRB: if (run_mode) s_mux = DIRB;
					default: s_mux = s_data_from_memory;
				endcase
			end
	end


always @(*)
	begin
		if (run_mode) 
			case (d_addr_in)
				`R_OUTA: d_mux = OUTA;
				`R_OUTB: d_mux = OUTB;
				`R_DIRA: d_mux = DIRA;
				`R_DIRB: d_mux = DIRB;
				default: d_mux = d_data_from_memory;
			endcase
		else
			d_mux = d_data_from_memory;
	end
	
assign muxed_d_addr = (state_in == `ST_WBACK) ? latched_dest_addr:s_data_from_memory[17:9];
wire cog_mem_write;
// Write to memory is only possible
assign cog_mem_write = ((state_in == `ST_WBACK) & d_write_in) &
                       ((run_mode & (latched_dest_addr[8:4] == 5'h1f)) ? 1'b0:1'b1);

`ifdef SIMULATOR
memblock_dp_x32 cog_mem(
	.clk_i(clk_in),
	.port_a_addr_i(left_addr_mux),
	.port_b_addr_i(muxed_d_addr), 
	.port_a_rden_i(1'b1),
	.port_b_rden_i(1'b1),
	.port_a_q_o(s_data_from_memory),
	.port_b_q_o(d_data_from_memory),
	.port_b_wen_i(cog_mem_write),
	.port_b_data_i(d_data_in) );
`else
`ifdef LATTICE_MACHXO2 

cog0_mem cog_mem(
	.DataInA(), 
	.DataInB(d_data_in), 
	.AddressA(left_addr_mux), 
	.AddressB(muxed_d_addr), 
	.ClockA(clk_in), 
	.ClockB(clk_in), 
    .ClockEnA(1'b1), 
	.ClockEnB(1'b1), 
	.WrA(1'b0), 
	.WrB(cog_mem_write), 
	.ResetA(1'b0), 
	.ResetB(1'b0), 
	.QA(s_data_from_memory),
	.QB(d_data_from_memory));
`else //ALTERA_CV
`ifdef ALTERA_CV
cog_mem_altera cog_mem(
	.address_a(left_addr_mux),
	.address_b(muxed_d_addr),
	.clock(clk_in),
	.data_a(32'b0),
	.data_b(d_data_in),
	.wren_a(1'b0),
	.wren_b(cog_mem_write),
	.q_a(s_data_from_memory),
	.q_b(d_data_from_memory));
`endif
`endif // ifdef LATTICE...
`endif // ifdef SIMULATOR

initial
	begin
		PAR  = 0;
		OUTA = 0;
		OUTB = 0;
		DIRA = 0;
		DIRB = 0;
		latched_i = 0;
		latched_source_addr = 0;
		latched_dest_addr = 0;
		run_mode = 0;
	end

endmodule


`ifdef SIMULATOR
module memblock_dp_x32(
	input wire clk_i,
	input wire [8:0] port_a_addr_i,
	input wire [8:0] port_b_addr_i,
	input wire port_a_rden_i,
	input wire port_b_rden_i,
	output reg [31:0] port_a_q_o,
	output reg [31:0] port_b_q_o,
	input wire port_b_wen_i,
	input wire [31:0] port_b_data_i
	);

reg [31:0] mem[511:0];

always @(posedge clk_i)
	begin
		if (port_a_rden_i)
			port_a_q_o <= mem[port_a_addr_i];
		if (port_b_rden_i)
			port_b_q_o <= mem[port_b_addr_i];
		if (port_b_wen_i)
			mem[port_b_addr_i] <= port_b_data_i;
	end

integer i;
initial
	begin
		for ( i = 32'd0; i < 32'd511; i = i + 32'd1)
			mem[i] = { i[15:0], i[15:0] };//32'hDEADBEEF;
		#0
		// HUB loader
		mem[9'h1f4] = { `I_MOV,    4'b0010, 4'hf, 9'h1f1, `R_PAR}; //  mov    $1f1, PAR     ' load src ptr
		mem[9'h1f5] = { `I_MOV,    4'b0011, 4'hf, 9'h1f2, 9'h000}; //  mov    $1f2, #0      ' load src ptr
		mem[9'h1f6] = { `I_MOV,    4'b0011, 4'hf, 9'h1f3, 9'h1f0}; //  mov    $1f3, #1f0    ' load counter
		mem[9'h1f7] = { `I_MOVD,   4'b0010, 4'hf, 9'h1f8, 9'h1f2}; //  loop movd   $1fa, $1f2    ' dest ptr
		mem[9'h1f8] = { `I_RDLONG, 4'b0010, 4'hf, 9'h000, 9'h1f1}; //  rdlong $0-0, $1f1    ' load long
		mem[9'h1f9] = { `I_ADD,    4'b0011, 4'hf, 9'h1f1, 9'h004}; //  add    $1f1, #$4     ' icr dest addr
		mem[9'h1fa] = { `I_ADD,    4'b0011, 4'hf, 9'h1f2, 9'h001}; //  add    $1f2, #$1     ' icr dest addr
		mem[9'h1fb] = { `I_DJNZ,   4'b0011, 4'hf, 9'h1f3, 9'h1f7}; //  djnz   $1f3, loop
		mem[9'h1fc] = { `I_JMP,    4'b0001, 4'hf,  9'h00, 9'h000}; //  jmp    #$0           ' jump to start
                    //OOOOOOZCRiCCCCDDDDDDDDDSSSSSSSSS
/*
		mem[   0] = 32'b10100000111111111110100000000011; //-- mov dira, #3
		mem[   1] = 32'b10100000101111111100000111110001; //-- mov temp, CNT ($1E0)
		mem[   2] = 32'b10000000111111111100000000100000; //-- add temp, #32
		mem[   3] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[   4] = 32'b10100000111111111110110000000010; //-- mov porta, #2
		mem[   5] = 32'b11111000111111111100000000010100; //-- waitcnt temp, #20
		mem[   6] = 32'b10100000111111111110110000000001; //-- mov porta, #1
		mem[   7] = 32'b01011100011111000000000000000011; //-- jmp #3
		mem[   8] = 32'b001110_1111_0010_001000100_001000001; // mov rt, rA20
		mem[   9] = 32'b001110_1111_0010_001000100_001000001; // mov rt, rA20
		mem[ 128] = 32'b111100_0011_1100_001111000_011110000; // mov rt, rA20
*/
	end
endmodule
`endif
